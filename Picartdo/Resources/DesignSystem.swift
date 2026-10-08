import SwiftUI

// MARK: - Motion
//
// Natural springs, 350–500ms transitions. Nothing snaps. No bounce.

enum PicardoMotion {
    static let transition = Animation.spring(response: 0.42, dampingFraction: 0.86)
    static let quick = Animation.spring(response: 0.32, dampingFraction: 0.88)
    static let reveal = Animation.easeOut(duration: 0.45)
    static let dissolve = Animation.easeInOut(duration: 0.85)
    static let press = Animation.spring(response: 0.28, dampingFraction: 0.7)
}

// MARK: - Card chrome
//
// Soft elevation, subtle border, 20pt radius. No heavy shadows.

struct PicardoCardModifier: ViewModifier {
    var radius: CGFloat = 20
    var elevated: Bool = true

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.picardoBorder, lineWidth: 0.5)
            )
            .shadow(
                color: elevated ? Color.black.opacity(0.04) : .clear,
                radius: elevated ? 12 : 0,
                x: 0,
                y: elevated ? 4 : 0
            )
    }
}

extension View {
    func picardoCard(radius: CGFloat = 20, elevated: Bool = true) -> some View {
        modifier(PicardoCardModifier(radius: radius, elevated: elevated))
    }

    /// Apple liquid glass — refraction and depth, no white card.
    func picardoGlass<S: Shape>(in shape: S, interactive: Bool = false) -> some View {
        let glass: Glass = interactive ? .regular.interactive() : .regular
        return self.glassEffect(glass, in: shape)
    }

    /// Photo or video as one glass piece — continuous curve, no Instagram card corners.
    func picardoGlassMedia<S: InsettableShape>(in shape: S) -> some View {
        self
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.55),
                            .white.opacity(0.08),
                            .white.opacity(0.22),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(0.28), radius: 22, y: 14)
            .shadow(color: .black.opacity(0.08), radius: 4, y: 1)
    }

    /// Solid nav chrome on pushed screens so swipe-back doesn't blur moving layers.
    func picardoPushedScreen() -> some View {
        self
            .toolbarBackground(Color.picardoBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Pressable microinteraction

struct PicardoPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(PicardoMotion.press, value: configuration.isPressed)
    }
}

// MARK: - Editorial eyebrow + title

struct PicardoEyebrow: View {
    let text: String
    var accent: Bool = true

    var body: some View {
        Text(text)
            .picardoMetaStyle()
            .foregroundStyle(accent ? Color.picardoAccent : Color.picardoTextSecondary)
    }
}

struct PicardoSectionHeader: View {
    let title: String
    let eyebrow: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PicardoEyebrow(text: eyebrow)
            Text(title)
                .font(PicardoType.section())
                .foregroundStyle(Color.picardoText)
            Rectangle()
                .fill(Color.picardoAccent)
                .frame(width: 28, height: 1.5)
                .padding(.top, 2)
        }
    }
}

// MARK: - Understated primary / secondary CTAs

struct PicardoPrimaryButton: View {
    let title: String
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PicardoType.cta())
                .kerning(1)
                // Inverse of the era text color, so it reads in light and dark mode.
                .foregroundStyle(Color.picardoBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(enabled ? Color.picardoText : Color.picardoTextSecondary)
        }
        .buttonStyle(PicardoPressStyle())
        .disabled(!enabled)
    }
}

struct PicardoSecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(PicardoType.cta())
                .kerning(1)
                .foregroundStyle(Color.picardoText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .overlay(Rectangle().strokeBorder(Color.picardoBorder, lineWidth: 1))
        }
        .buttonStyle(PicardoPressStyle())
    }
}

// MARK: - Soft fade-in on appear

struct PicardoReveal: ViewModifier {
    @State private var visible = false
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 12)
            .onAppear {
                withAnimation(PicardoMotion.reveal.delay(delay)) {
                    visible = true
                }
            }
    }
}

extension View {
    func picardoReveal(delay: Double = 0) -> some View {
        modifier(PicardoReveal(delay: delay))
    }
}
