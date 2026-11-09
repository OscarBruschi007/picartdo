import SwiftUI

/// A quiet figure at an easel, painting behind the content.
///
/// The brush really draws: each stroke on the canvas is traced by the tip of the brush,
/// and the arm reaches for it. Two modes:
/// - `progress` set (0...1): the painting grows with the onboarding. Each step adds strokes,
///   and at 1 the canvas is finished and the painter just dabs at it.
/// - `progress` nil: an ambient loop that paints, rests, fades and starts again.
///
/// Drawn entirely with `Canvas`. No images, no video. Reduce Motion shows a still,
/// finished painting. Decorative only, so hidden from VoiceOver.
struct PainterBackgroundView: View {
    var progress: Double? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    // Catch-up state: where the painting was when the target last changed.
    @State private var fromStrokes: Double = 0
    @State private var changedAt: Date = .distantPast

    /// Seconds per stroke while catching up to a new step, and in the ambient loop.
    private static let catchUpBeat: Double = 0.95
    private static let ambientBeat: Double = 2.2

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || scenePhase != .active)) { timeline in
            let now = timeline.date
            Canvas { context, size in
                draw(in: &context, size: size, now: now)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            fromStrokes = targetStrokes
            previousTarget = targetStrokes
            changedAt = .now
        }
        .onChange(of: progress) { _, _ in
            fromStrokes = catchUpStrokes(at: .now, target: previousTarget)
            previousTarget = targetStrokes
            changedAt = .now
        }
    }

    @State private var previousTarget: Double = 0

    // MARK: - Timing

    private var targetStrokes: Double {
        guard let progress else { return Double(PainterArt.strokes.count) }
        return (min(max(progress, 0), 1) * Double(PainterArt.strokes.count)).rounded(.down)
    }

    private func catchUpStrokes(at date: Date, target: Double) -> Double {
        let elapsed = max(0, date.timeIntervalSince(changedAt))
        let moved = elapsed / Self.catchUpBeat
        if target >= fromStrokes { return min(target, fromStrokes + moved) }
        return max(target, fromStrokes - moved * 3) // going back unpaints quickly
    }

    /// How many strokes are painted right now (fractional: the live stroke), plus a fade.
    private func paintState(at date: Date) -> (strokes: Double, fade: Double) {
        let count = Double(PainterArt.strokes.count)
        if reduceMotion { return (progress == nil ? count : targetStrokes, 1) }
        if progress != nil {
            return (catchUpStrokes(at: date, target: targetStrokes), 1)
        }
        // Ambient loop: paint every stroke, admire it, fade, start over.
        let loop = count + 3
        let phase = (date.timeIntervalSinceReferenceDate / Self.ambientBeat).truncatingRemainder(dividingBy: loop)
        let fade = phase > count + 2 ? 1 - (phase - count - 2) : 1
        return (min(count, phase), max(0, fade))
    }

    // MARK: - Drawing

    private func draw(in context: inout GraphicsContext, size: CGSize, now: Date) {
        let design = PainterArt.designSize
        let scale = min(size.width / design.width, size.height / design.height)
        let dx = (size.width - design.width * scale) / 2
        let dy = size.height - design.height * scale
        context.translateBy(x: dx, y: dy)
        context.scaleBy(x: scale, y: scale)

        let t = reduceMotion ? 0 : now.timeIntervalSinceReferenceDate
        let ink = Color.picardoText
        let (painted, fade) = paintState(at: now)

        // Floor shadow
        context.fill(
            Path(ellipseIn: CGRect(x: 30, y: 344, width: 290, height: 12)),
            with: .color(ink.opacity(0.08))
        )

        drawEasel(in: &context, ink: ink)

        // The painting
        var tip = PainterArt.restPoint
        var previousEnd = PainterArt.restPoint
        for (index, stroke) in PainterArt.strokes.enumerated() {
            let local = painted - Double(index)
            guard local > 0 else { break }
            let travel = 0.25
            let drawn = min(1, max(0, (local - travel) / (1 - travel)))
            if drawn > 0 {
                let path = stroke.path.trimmedPath(from: 0, to: drawn)
                context.stroke(
                    path,
                    with: .color(stroke.color.opacity(0.9 * fade)),
                    style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round)
                )
                tip = path.currentPoint ?? stroke.start
            } else {
                // Brush travelling to the start of the next stroke.
                let u = ease(min(1, local / travel))
                tip = lerp(previousEnd, stroke.start, u)
            }
            previousEnd = stroke.end
        }

        let isPainting = painted.truncatingRemainder(dividingBy: 1) > 0.001 && painted < Double(PainterArt.strokes.count)
        if !isPainting {
            // Resting on the work: small, unhurried dabs near the last mark.
            let anchor = painted >= 1 ? previousEnd : PainterArt.restPoint
            tip = CGPoint(
                x: anchor.x + 5 * sin(t * 1.9),
                y: anchor.y + 4 * cos(t * 1.4)
            )
        } else {
            tip.x += 0.8 * sin(t * 9)
        }

        drawFigure(in: &context, ink: ink, tip: tip, t: t)
    }

    private func drawEasel(in context: inout GraphicsContext, ink: Color) {
        var legs = Path()
        legs.move(to: CGPoint(x: 130, y: 44)); legs.addLine(to: CGPoint(x: 66, y: 350))
        legs.move(to: CGPoint(x: 130, y: 44)); legs.addLine(to: CGPoint(x: 194, y: 350))
        legs.move(to: CGPoint(x: 130, y: 44)); legs.addLine(to: CGPoint(x: 130, y: 340))
        context.stroke(legs, with: .color(ink.opacity(0.55)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

        // Ledge
        context.fill(
            Path(roundedRect: CGRect(x: 62, y: 226, width: 136, height: 7), cornerRadius: 2),
            with: .color(ink.opacity(0.6))
        )

        // Canvas board
        let board = PainterArt.board
        context.fill(Path(board.insetBy(dx: -4, dy: -4)), with: .color(ink.opacity(0.75)))
        context.fill(Path(board), with: .color(Color.picardoPolaroidMat))
    }

    private func drawFigure(in context: inout GraphicsContext, ink: Color, tip: CGPoint, t: Double) {
        let breathe = 1.4 * sin(t * 1.15)
        let fill = GraphicsContext.Shading.color(ink)
        let limb = StrokeStyle(lineWidth: 13, lineCap: .round, lineJoin: .round)
        let thin = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)

        // Legs
        var legs = Path()
        legs.move(to: CGPoint(x: 262, y: 222)); legs.addLine(to: CGPoint(x: 252, y: 344))
        legs.move(to: CGPoint(x: 280, y: 222)); legs.addLine(to: CGPoint(x: 290, y: 344))
        context.stroke(legs, with: fill, style: limb)

        // Torso, leaning a little toward the easel
        var torso = Path()
        torso.move(to: CGPoint(x: 250, y: 128 + breathe))
        torso.addQuadCurve(to: CGPoint(x: 290, y: 130 + breathe), control: CGPoint(x: 272, y: 118 + breathe))
        torso.addQuadCurve(to: CGPoint(x: 288, y: 228), control: CGPoint(x: 298, y: 180))
        torso.addLine(to: CGPoint(x: 256, y: 228))
        torso.addQuadCurve(to: CGPoint(x: 250, y: 128 + breathe), control: CGPoint(x: 244, y: 176))
        torso.closeSubpath()
        context.fill(torso, with: fill)

        // Neck and head, tilting as they look at the work
        let tilt = 2.0 * sin(t * 0.6)
        var neck = Path()
        neck.move(to: CGPoint(x: 268, y: 126 + breathe)); neck.addLine(to: CGPoint(x: 265, y: 110 + breathe))
        context.stroke(neck, with: fill, style: StrokeStyle(lineWidth: 9, lineCap: .round))
        let head = CGPoint(x: 262 + tilt * 0.5, y: 94 + breathe)
        context.fill(Path(ellipseIn: CGRect(x: head.x - 17, y: head.y - 18, width: 34, height: 36)), with: fill)
        // Hair knot
        context.fill(Path(ellipseIn: CGRect(x: head.x + 8, y: head.y - 22, width: 14, height: 14)), with: fill)

        // Back arm holding the palette
        let backShoulder = CGPoint(x: 284, y: 136 + breathe)
        var backArm = Path()
        backArm.move(to: backShoulder)
        backArm.addLine(to: CGPoint(x: 296, y: 182))
        backArm.addLine(to: CGPoint(x: 276, y: 196))
        context.stroke(backArm, with: fill, style: thin)
        let palette = CGRect(x: 246, y: 186, width: 44, height: 24)
        context.fill(Path(ellipseIn: palette), with: .color(Color.picardoPolaroidMat))
        context.stroke(Path(ellipseIn: palette), with: .color(ink.opacity(0.7)), lineWidth: 1.5)
        for (i, pigment) in PainterArt.pigments.prefix(4).enumerated() {
            let x = palette.minX + 8 + CGFloat(i) * 8.5
            let y = palette.midY - 3 + (i.isMultiple(of: 2) ? 0 : 5)
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 6, height: 6)), with: .color(pigment))
        }

        // Painting arm: two-bone reach toward the brush.
        let shoulder = CGPoint(x: 254, y: 136 + breathe)
        let brushLength: CGFloat = 30
        let toShoulder = normalized(CGPoint(x: shoulder.x - tip.x, y: shoulder.y - tip.y + 18))
        let hand = CGPoint(x: tip.x + toShoulder.x * brushLength, y: tip.y + toShoulder.y * brushLength)
        let reachedHand = clampReach(shoulder: shoulder, hand: hand, length: 119.5)
        let elbow = solveElbow(shoulder: shoulder, hand: reachedHand, upper: 62, lower: 58)

        var arm = Path()
        arm.move(to: shoulder)
        arm.addLine(to: elbow)
        arm.addLine(to: reachedHand)
        context.stroke(arm, with: fill, style: thin)

        // Brush: handle in ink, tip loaded with paint
        let brushEnd = CGPoint(x: reachedHand.x - toShoulder.x * brushLength, y: reachedHand.y - toShoulder.y * brushLength)
        var brush = Path()
        brush.move(to: CGPoint(x: reachedHand.x + toShoulder.x * 6, y: reachedHand.y + toShoulder.y * 6))
        brush.addLine(to: brushEnd)
        context.stroke(brush, with: fill, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        context.fill(
            Path(ellipseIn: CGRect(x: brushEnd.x - 3, y: brushEnd.y - 3, width: 6, height: 6)),
            with: .color(Color.picardoNeonRed)
        )
    }

    // MARK: - Geometry helpers

    private func solveElbow(shoulder: CGPoint, hand: CGPoint, upper: CGFloat, lower: CGFloat) -> CGPoint {
        let target = hand
        let dx = target.x - shoulder.x, dy = target.y - shoulder.y
        let d = max(0.001, hypot(dx, dy))
        // Law of cosines for the angle at the shoulder.
        let cosA = (upper * upper + d * d - lower * lower) / (2 * upper * d)
        let a = acos(min(1, max(-1, cosA)))
        let base = atan2(dy, dx)
        // Bend the elbow downward, the way a painter's arm hangs.
        let angle = base - a
        let candidate = CGPoint(x: shoulder.x + upper * cos(angle), y: shoulder.y + upper * sin(angle))
        let other = CGPoint(x: shoulder.x + upper * cos(base + a), y: shoulder.y + upper * sin(base + a))
        return candidate.y >= other.y ? candidate : other
    }

    private func clampReach(shoulder: CGPoint, hand: CGPoint, length: CGFloat) -> CGPoint {
        let dx = hand.x - shoulder.x, dy = hand.y - shoulder.y
        let d = hypot(dx, dy)
        guard d > length else { return hand }
        return CGPoint(x: shoulder.x + dx / d * length, y: shoulder.y + dy / d * length)
    }

    private func normalized(_ p: CGPoint) -> CGPoint {
        let d = max(0.001, hypot(p.x, p.y))
        return CGPoint(x: p.x / d, y: p.y / d)
    }

    private func lerp(_ a: CGPoint, _ b: CGPoint, _ u: Double) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u)
    }

    private func ease(_ u: Double) -> Double { u * u * (3 - 2 * u) }
}

// MARK: - The artwork

/// The painting the figure makes: a small landscape, stroke by stroke.
private enum PainterArt {
    static let designSize = CGSize(width: 330, height: 356)
    static let board = CGRect(x: 72, y: 78, width: 118, height: 144)
    static let restPoint = CGPoint(x: 176, y: 200)

    static let pigments: [Color] = [
        .picardoNeonRed,
        Color(red: 0.949, green: 0.702, blue: 0.239),
        Color(red: 0.231, green: 0.447, blue: 0.718),
        .picardoSupport,
        Color(red: 0.55, green: 0.33, blue: 0.62),
    ]

    struct Stroke {
        let path: Path
        let color: Color
        let width: CGFloat
        var start: CGPoint { path.trimmedPath(from: 0, to: 0.001).currentPoint ?? .zero }
        var end: CGPoint { path.currentPoint ?? .zero }
    }

    private static let blue = Color(red: 0.231, green: 0.447, blue: 0.718)
    private static let sky = Color(red: 0.48, green: 0.66, blue: 0.86)
    private static let gold = Color(red: 0.949, green: 0.702, blue: 0.239)
    private static let purple = Color(red: 0.55, green: 0.33, blue: 0.62)
    private static let deepGreen = Color(red: 0.16, green: 0.29, blue: 0.23)

    static let strokes: [Stroke] = [
        wave(from: CGPoint(x: 84, y: 96), to: CGPoint(x: 178, y: 96), lift: 5, color: blue, width: 11),
        wave(from: CGPoint(x: 178, y: 112), to: CGPoint(x: 84, y: 112), lift: -4, color: sky, width: 10),
        circle(center: CGPoint(x: 156, y: 128), radius: 9, color: gold, width: 6),
        wave(from: CGPoint(x: 82, y: 168), to: CGPoint(x: 180, y: 162), lift: 26, color: .picardoSupport, width: 10),
        wave(from: CGPoint(x: 180, y: 190), to: CGPoint(x: 82, y: 186), lift: 22, color: deepGreen, width: 11),
        wave(from: CGPoint(x: 112, y: 206), to: CGPoint(x: 114, y: 170), lift: 3, color: .picardoNeonRed, width: 5),
        circle(center: CGPoint(x: 114, y: 165), radius: 6, color: .picardoNeonRed, width: 5),
        wave(from: CGPoint(x: 92, y: 140), to: CGPoint(x: 128, y: 136), lift: 6, color: gold, width: 4),
        wave(from: CGPoint(x: 132, y: 208), to: CGPoint(x: 178, y: 206), lift: 8, color: purple, width: 7),
        wave(from: CGPoint(x: 160, y: 214), to: CGPoint(x: 180, y: 213), lift: 4, color: Color(white: 0.1), width: 2.2),
    ]

    private static func wave(from a: CGPoint, to b: CGPoint, lift: CGFloat, color: Color, width: CGFloat) -> Stroke {
        var path = Path()
        path.move(to: a)
        let c1 = CGPoint(x: a.x + (b.x - a.x) / 3, y: a.y + (b.y - a.y) / 3 - lift)
        let c2 = CGPoint(x: a.x + 2 * (b.x - a.x) / 3, y: a.y + 2 * (b.y - a.y) / 3 + lift * 0.6)
        path.addCurve(to: b, control1: c1, control2: c2)
        return Stroke(path: path, color: color, width: width)
    }

    private static func circle(center: CGPoint, radius: CGFloat, color: Color, width: CGFloat) -> Stroke {
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .degrees(-100), endAngle: .degrees(250), clockwise: false)
        return Stroke(path: path, color: color, width: width)
    }
}

#Preview("Onboarding, half done") {
    PainterBackgroundView(progress: 0.5)
        .frame(height: 420)
        .background(Color.picardoBackground)
}

#Preview("Ambient loop") {
    PainterBackgroundView()
        .frame(height: 420)
        .background(Color.picardoBackground)
}
