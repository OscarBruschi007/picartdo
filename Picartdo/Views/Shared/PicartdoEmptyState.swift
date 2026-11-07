import SwiftUI

/// The one empty state for every list: a symbol, a warm line, a hint, and,
/// when there's somewhere to go, one action. Never a blank screen.
struct PicartdoEmptyState: View {
    let icon: String
    let title: String
    var message: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    /// Overrides the text colors on themed screens (e.g. Messages).
    var primary: Color = .picardoText
    var secondary: Color = .picardoTextSecondary

    @ScaledMetric(relativeTo: .title) private var iconSize: CGFloat = 30

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .light))
                .foregroundStyle(secondary)
                .padding(.bottom, 4)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(primary)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let actionTitle, let action {
                Button {
                    Haptics.tap()
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.picardoBackground)
                        .padding(.horizontal, 20)
                        .frame(minHeight: 44)
                        .background(primary, in: Capsule())
                }
                .buttonStyle(PicardoPressStyle())
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
