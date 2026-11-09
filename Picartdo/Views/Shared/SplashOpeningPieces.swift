import SwiftUI

// MARK: - Opening bridge (shared with Home wordmark)

/// Lets the launch animation land its wordmark exactly on the Home header.
/// Home reports where its wordmark sits and keeps it hidden until the splash hands over.
struct PicardoSplashBridge {
    var hidesHomeWordmark: Bool
    var reportWordmarkFrame: (CGRect) -> Void
}

private struct PicardoSplashBridgeKey: EnvironmentKey {
    static let defaultValue: PicardoSplashBridge? = nil
}

extension EnvironmentValues {
    var picardoSplashBridge: PicardoSplashBridge? {
        get { self[PicardoSplashBridgeKey.self] }
        set { self[PicardoSplashBridgeKey.self] = newValue }
    }
}

/// The Picartdo wordmark, as set in the Home header and the opening transition.
struct PicardoBrandWordmark: View {
    var size: CGFloat = 24
    var tracking: CGFloat = 2.5

    @Environment(\.colorScheme) private var colorScheme

    /// Solid black ink; flips to white in dark mode so it never disappears on a black canvas.
    private var ink: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        Text("Picartdo")
            .foregroundStyle(ink)
            .font(.system(size: size, weight: .black, design: .serif))
            .kerning(tracking)
            .lineLimit(1)
            .fixedSize()
            .accessibilityLabel("Picartdo")
    }
}

// MARK: - Pigment wash

/// A slow mesh of muted Picartdo pigments: red, ochre and cobalt pooled toward the edges,
/// with a clean centre so the wordmark always reads.
struct PigmentWash: View {
    let canvas: Color
    var drift: CGFloat
    var strength: CGFloat

    private static let red = Color.picardoNeonRed
    private static let ochre = Color(red: 0.949, green: 0.702, blue: 0.239)
    private static let cobalt = Color(red: 0.231, green: 0.447, blue: 0.718)

    var body: some View {
        let d = Float(drift)
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5 - 0.06 * d], [0.5 + 0.04 * d, 0.48 + 0.03 * d], [1, 0.5 + 0.06 * d],
                [0, 1], [0.5 - 0.05 * d, 1], [1, 1],
            ],
            colors: [
                tint(Self.ochre, 0.10), tint(Self.red, 0.06), canvas,
                tint(Self.red, 0.22), canvas, tint(Self.ochre, 0.26),
                canvas, tint(Self.cobalt, 0.20), tint(Self.cobalt, 0.10),
            ],
            smoothsColors: true
        )
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func tint(_ pigment: Color, _ amount: Double) -> Color {
        canvas.mix(with: pigment, by: amount * Double(strength))
    }
}

// MARK: - Paper grain

/// Fine, static paper texture: one small noise tile rendered once, then repeated.
struct PaperGrain: View {
    private static let tile: UIImage = {
        // Rendered at 3x with one-pixel specks, so the grain is finer than a point
        // and reads as paper rather than visible noise.
        // Written straight into a pixel buffer: the same specks as drawing ~32,000 tiny
        // rects, but in a few milliseconds instead of ~0.4 s on the first frame.
        let side = 120
        let scale = 3
        let pixels = side * scale
        var buffer = [UInt8](repeating: 0, count: pixels * pixels * 4) // premultiplied RGBA
        var rng = SeededGenerator(seed: 0x51C0FFEE)
        for _ in 0..<(pixels * pixels / 4) {
            let x = Int.random(in: 0..<pixels, using: &rng)
            let y = Int.random(in: 0..<pixels, using: &rng)
            let dark = Bool.random(using: &rng)
            let alpha = Double.random(in: 0.2...1, using: &rng)
            // Source-over, as the fill did: out = src + dst * (1 - srcAlpha).
            let i = (y * pixels + x) * 4
            let keep = 1 - alpha
            let channel = dark ? 0 : 255 * alpha
            for c in 0..<3 {
                buffer[i + c] = UInt8((channel + Double(buffer[i + c]) * keep).rounded())
            }
            buffer[i + 3] = UInt8((255 * alpha + Double(buffer[i + 3]) * keep).rounded())
        }
        let data = Data(buffer) as CFData
        guard let provider = CGDataProvider(data: data),
              let image = CGImage(
                width: pixels,
                height: pixels,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: pixels * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else { return UIImage() }
        return UIImage(cgImage: image, scale: CGFloat(scale), orientation: .up)
    }()

    var body: some View {
        Image(uiImage: Self.tile)
            .resizable(resizingMode: .tile)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

// MARK: - Write-on mask

/// A soft-edged wipe that reveals content left to right, like ink being laid down.
struct WriteOnMask: View {
    var progress: CGFloat
    var feather: CGFloat = 0.22

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width * (1 + feather)
            LinearGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: 1 - feather / (1 + feather)),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width, height: geo.size.height)
            .offset(x: -width * (1 - progress))
        }
    }
}
