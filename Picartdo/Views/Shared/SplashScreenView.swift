import SwiftUI

/// Opening — a quiet pigment wash on textured paper, "PICARTDO" written in at the centre,
/// then the wordmark glides up into the Home header as the app fades in around it.
struct SplashScreenView: View {
    @Environment(SessionStore.self) private var session
    @Environment(WishlistStore.self) private var wishlist
    @Environment(TastePreferenceStore.self) private var taste
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    // Canvas and paint
    @State private var canvasSettled: Double = 0
    @State private var washOpacity: Double = 0
    @State private var washDrift: CGFloat = -1
    @State private var backdropOpacity: Double = 1
    // Wordmark
    @State private var writeProgress: CGFloat = 1
    @State private var tracking: CGFloat = 2.5
    @State private var rise: CGFloat = 0
    @State private var landed = false
    @State private var wordmarkOpacity: Double = 1
    @State private var homeWordmarkFrame: CGRect = .zero
    // Details
    @State private var ruleWidth: CGFloat = 0
    @State private var taglineOpacity: Double = 0
    @State private var taglineRise: CGFloat = 6
    // App
    @State private var appOpacity: Double = 0
    @State private var mainAppReady = false
    @State private var overlayRemoved = false
    @State private var didStart = false
    @State private var didHandoff = false
    @State private var sequenceTask: Task<Void, Never>?

    private let skipChrome = ProcessInfo.processInfo.arguments.contains("--studio-tab")
        || ProcessInfo.processInfo.arguments.contains("--explore-tab")
        || ProcessInfo.processInfo.arguments.contains("--artist-profile")

    private static let lastOpenKey = "picardo.splash.lastOpenAt"
    /// Home header size; the splash sets the same wordmark larger and lands it at this size.
    private static let homeWordmarkSize: CGFloat = 24
    private static let homeTracking: CGFloat = 2.5

    // Motion language: one family of curves, used everywhere.
    private static let settle = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 1.1)
    private static let write = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.95)
    private static let glide = Animation.spring(duration: 0.8, bounce: 0)

    private var isDark: Bool { colorScheme == .dark }
    private var eraCanvas: Color { isDark ? .black : Color.picardoBackground }
    private var launchCanvas: Color { Color("LaunchBackground") }
    private var landsOnHome: Bool { skipChrome || taste.hasCompletedTastePass }

    private var isReturningVisit: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--splash-full") { return false }
        #endif
        let last = UserDefaults.standard.double(forKey: Self.lastOpenKey)
        guard last > 0 else { return false }
        return Date().timeIntervalSince1970 - last < 6 * 60 * 60
    }

    var body: some View {
        ZStack {
            eraCanvas.ignoresSafeArea()

            if mainAppReady {
                destination
                    .opacity(appOpacity)
                    .environment(\.picardoSplashBridge, overlayRemoved ? nil : bridge)
            }

            if !overlayRemoved {
                splashLayer
                    .allowsHitTesting(!didHandoff)
                    .onTapGesture { skipToHandoff() }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Picartdo")
            }
        }
        .onAppear(perform: startSequence)
    }

    private var bridge: PicardoSplashBridge {
        PicardoSplashBridge(hidesHomeWordmark: true) { frame in
            if frame.width > 0 { homeWordmarkFrame = frame }
        }
    }

    @ViewBuilder
    private var destination: some View {
        if landsOnHome {
            ContentView()
        } else {
            TasteOnboardingView()
        }
    }

    // MARK: - Layers

    private var splashLayer: some View {
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            // Matches the LaunchWordmark image exactly, so launch screen → splash has no jump.
            let heroSize: CGFloat = 48
            let heroScale = heroSize / Self.homeWordmarkSize
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let canLand = landed && homeWordmarkFrame != .zero
            let target = CGPoint(
                x: homeWordmarkFrame.midX - origin.x,
                y: homeWordmarkFrame.midY - origin.y
            )

            ZStack {
                // Backdrop: paper, pigment and grain. Fades away during the handoff.
                ZStack {
                    launchCanvas
                    eraCanvas.opacity(canvasSettled)
                    PigmentWash(canvas: eraCanvas, drift: washDrift, strength: isDark ? 0.8 : 1)
                        .opacity(washOpacity)
                    PaperGrain()
                        .opacity(isDark ? 0.05 : 0.045)
                }
                .opacity(backdropOpacity)

                // Hairline and tagline sit under the wordmark.
                VStack(spacing: 16) {
                    Capsule()
                        .fill(Color.picardoNeonRed)
                        .frame(width: ruleWidth, height: 1.5)
                    Text("EVERY PIECE OF ART TELLS A STORY")
                        .font(.system(size: 10.5, weight: .semibold))
                        .kerning(2.6)
                        .foregroundStyle(Color.primary.opacity(0.55))
                        .opacity(taglineOpacity)
                        .offset(y: taglineRise)
                }
                .position(x: center.x, y: center.y + heroSize * 0.95)

                // The wordmark is the same view as the Home header, set larger, so it can land on it.
                PicardoBrandWordmark(size: Self.homeWordmarkSize, tracking: tracking)
                    .mask { WriteOnMask(progress: writeProgress) }
                    .scaleEffect(canLand ? 1 : heroScale)
                    .offset(y: canLand ? 0 : rise)
                    .opacity(wordmarkOpacity)
                    .position(canLand ? target : center)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    // MARK: - Sequence

    private func startSequence() {
        guard !didStart else { return }
        didStart = true

        Task { @MainActor in
            await session.bootstrap()
            await wishlist.hydrateFromServer()
        }

        if skipChrome {
            mainAppReady = true
            appOpacity = 1
            overlayRemoved = true
            recordOpen()
            return
        }

        sequenceTask = Task { @MainActor in
            do {
                if reduceMotion {
                    try await playReduceMotion()
                } else if isReturningVisit {
                    try await playShort()
                } else {
                    try await playFull()
                }
            } catch {
                // Cancelled by tap-to-skip, which runs the handoff itself.
            }
        }
    }

    private func playFull() async throws {
        // The launch screen already showed the wordmark; carry on from it without redrawing.
        try await Task.sleep(for: .milliseconds(40))
        withAnimation(.easeInOut(duration: 0.7)) { canvasSettled = 1 }
        withAnimation(.easeOut(duration: 0.9)) { washOpacity = 1 }
        withAnimation(.easeInOut(duration: 1.8)) { washDrift = 1 }

        try await Task.sleep(for: .milliseconds(120))
        withAnimation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.5)) { ruleWidth = 36 }

        try await Task.sleep(for: .milliseconds(150))
        withAnimation(.easeOut(duration: 0.4)) {
            taglineOpacity = 1
            taglineRise = 0
        }

        // Mount the app underneath during the still moment so first layout can't stutter the motion.
        try await Task.sleep(for: .milliseconds(150))
        mainAppReady = true
        try await Task.sleep(for: .milliseconds(450))
        try Task.checkCancellation()
        await performHandoff()
    }

    private func playShort() async throws {
        withAnimation(.easeInOut(duration: 0.4)) { canvasSettled = 1 }
        withAnimation(.easeOut(duration: 0.4)) { washOpacity = 1 }
        try await Task.sleep(for: .milliseconds(120))
        mainAppReady = true
        try await Task.sleep(for: .milliseconds(280))
        try Task.checkCancellation()
        await performHandoff()
    }

    private func playReduceMotion() async throws {
        canvasSettled = 1
        washOpacity = 1
        washDrift = 0
        writeProgress = 1
        tracking = Self.homeTracking
        rise = 0
        ruleWidth = 36
        taglineOpacity = 1
        taglineRise = 0
        mainAppReady = true
        try await Task.sleep(for: .milliseconds(800))
        try Task.checkCancellation()
        await performHandoff()
    }

    private func skipToHandoff() {
        guard !didHandoff else { return }
        sequenceTask?.cancel()
        mainAppReady = true
        withAnimation(.easeOut(duration: 0.2)) {
            writeProgress = 1
            tracking = Self.homeTracking
            rise = 0
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            await performHandoff()
        }
    }

    @MainActor
    private func performHandoff() async {
        guard !didHandoff else { return }
        didHandoff = true
        mainAppReady = true
        recordOpen()

        // Give a freshly mounted Home a moment to report where its header sits.
        for _ in 0..<5 where homeWordmarkFrame == .zero {
            try? await Task.sleep(for: .milliseconds(50))
        }

        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.4)) {
                appOpacity = 1
                backdropOpacity = 0
                wordmarkOpacity = 0
                ruleWidth = 0
                taglineOpacity = 0
            }
            try? await Task.sleep(for: .milliseconds(420))
            overlayRemoved = true
            return
        }

        // Details step back first.
        withAnimation(.easeIn(duration: 0.18)) {
            taglineOpacity = 0
            taglineRise = -4
            ruleWidth = 0
        }
        try? await Task.sleep(for: .milliseconds(120))

        let canLand = landsOnHome && homeWordmarkFrame != .zero
        withAnimation(Self.glide) {
            if canLand {
                landed = true
            } else {
                wordmarkOpacity = 0
            }
            backdropOpacity = 0
            appOpacity = 1
        }

        try? await Task.sleep(for: .milliseconds(560))
        Haptics.soft()
        try? await Task.sleep(for: .milliseconds(320))
        // The splash wordmark now sits exactly on the Home header; swap them in the same frame.
        overlayRemoved = true
    }

    private func recordOpen() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastOpenKey)
    }
}

#Preview {
    SplashScreenView()
        .environment(SessionStore())
        .environment(WishlistStore())
        .environment(MarketplaceStore())
        .environment(ThreadPostStore())
        .environment(TastePreferenceStore())
}
