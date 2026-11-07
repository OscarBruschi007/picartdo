import SwiftUI
import UIKit

/// One quiet message that confirms what just happened, with an optional action
/// (usually Undo). Lives in its own small window above everything, so it shows
/// over sheets and full-screen covers too, and never blocks touches elsewhere.
///
///     PicartdoToast.show("Removed from your wall", icon: "heart.slash", action: .undo { … })
@MainActor
enum PicartdoToast {

    struct Action {
        let title: String
        let perform: () -> Void

        static func undo(_ perform: @escaping () -> Void) -> Action {
            Action(title: "Undo", perform: perform)
        }
    }

    enum Tone { case neutral, success, error }

    struct Message: Identifiable, Equatable {
        let id = UUID()
        let text: String
        let icon: String?
        let tone: Tone
        let action: Action?

        static func == (a: Message, b: Message) -> Bool { a.id == b.id }
    }

    static func show(
        _ text: String,
        icon: String? = nil,
        tone: Tone = .neutral,
        action: Action? = nil,
        duration: Duration? = nil
    ) {
        let message = Message(text: text, icon: icon, tone: tone, action: action)
        switch tone {
        case .success: Haptics.success()
        case .error: Haptics.error()
        case .neutral: break
        }
        ToastPresenter.shared.present(message, for: duration ?? (action == nil ? .seconds(2.4) : .seconds(4.5)))
        UIAccessibility.post(
            notification: .announcement,
            argument: action == nil ? text : "\(text). \(action!.title) available."
        )
    }

    static func dismiss() { ToastPresenter.shared.dismiss() }
}

// MARK: - Presenter

@Observable
@MainActor
final class ToastPresenter {
    static let shared = ToastPresenter()

    private(set) var current: PicartdoToast.Message?
    /// Where the capsule is on screen, so only it catches touches.
    @ObservationIgnored var toastFrame: CGRect = .zero
    private var window: ToastWindow?
    private var hideTask: Task<Void, Never>?

    func present(_ message: PicartdoToast.Message, for duration: Duration) {
        installWindowIfNeeded()
        window?.isHidden = false
        current = message
        hideTask?.cancel()
        hideTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.dismiss()
        }
    }

    func dismiss() {
        hideTask?.cancel()
        current = nil
        toastFrame = .zero
        // Let the exit animation finish before the window stops drawing.
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self, self.current == nil else { return }
            self.window?.isHidden = true
        }
    }

    func runAction(of message: PicartdoToast.Message) {
        guard current == message else { return }
        Haptics.tap()
        message.action?.perform()
        dismiss()
    }

    private func installWindowIfNeeded() {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }

        let window = ToastWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        let host = UIHostingController(rootView: ToastHost())
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }
}

/// Touches pass through everywhere except the toast itself. SwiftUI buttons
/// aren't UIViews, so the check is against the capsule's reported frame.
private final class ToastWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let presenter = ToastPresenter.shared
        guard presenter.current != nil,
              presenter.toastFrame.insetBy(dx: -4, dy: -4).contains(point)
        else { return nil }
        return super.hitTest(point, with: event)
    }
}

// MARK: - View

private struct ToastHost: View {
    @State private var presenter = ToastPresenter.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack {
            if let message = presenter.current {
                ToastCapsule(message: message) { presenter.runAction(of: message) }
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: {
                        presenter.toastFrame = $0
                    }
                    .id(message.id)
                    .transition(
                        reduceMotion
                            ? .opacity
                            : .move(edge: .top).combined(with: .opacity)
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 12).onEnded { value in
                            if value.translation.height < -12 { presenter.dismiss() }
                        }
                    )
            }
            Spacer()
        }
        // Like the system's own banners: just under the Dynamic Island, clear of
        // every bottom button and the tab bar.
        .padding(.top, 6)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(PicardoMotion.quick, value: presenter.current)
        .ignoresSafeArea(.keyboard)
    }
}

private struct ToastCapsule: View {
    let message: PicartdoToast.Message
    let onAction: () -> Void

    @ScaledMetric(relativeTo: .subheadline) private var textSize: CGFloat = 14

    private var iconColor: Color {
        switch message.tone {
        case .neutral: return Color.picardoText
        case .success: return Color.picardoSupport
        case .error: return Color.picardoNeonRed
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon = message.icon {
                Image(systemName: icon)
                    .font(.system(size: textSize, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)
            }
            Text(message.text)
                .font(.system(size: textSize, weight: .medium))
                .foregroundStyle(Color.picardoText)
                .lineLimit(6)
                .fixedSize(horizontal: false, vertical: true)
            if let action = message.action {
                Spacer(minLength: 8)
                Button(action.title, action: onAction)
                    .font(.system(size: textSize, weight: .semibold))
                    .foregroundStyle(Color.picardoAccent)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, message.action == nil ? 13 : 4)
        .frame(minHeight: 48)
        // Radius 24 on a 48pt bar reads as a capsule; taller (large text) it stays graceful.
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Color.picardoBorder, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        .accessibilityElement(children: .contain)
    }
}
