import AVFoundation
import SwiftUI
import UIKit

private struct HeroVideoEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var heroVideoEnabled: Bool {
        get { self[HeroVideoEnabledKey.self] }
        set { self[HeroVideoEnabledKey.self] = newValue }
    }
}

/// Pauses the hero video even when the SwiftUI view under a push is frozen
/// and would not receive environment updates until the pop finishes.
@MainActor
enum HeroVideoControl {
    static func setEnabled(_ enabled: Bool) {
        LoopingHeroVideoUIView.setPlaybackEnabled(enabled)
    }
}

/// Muted, looping, aspect-fill video for service heroes. No controls.
struct LoopingHeroVideo: View {
    let resourceName: String
    var fallbackImageName: String? = nil

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.heroVideoEnabled) private var heroVideoEnabled
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if let fallbackImageName {
                ArtworkImage(imageName: fallbackImageName, contentMode: .fill, maxDimension: 1400)
            } else {
                Color.black
            }

            if isPlaying {
                LoopingHeroVideoPlayer(resourceName: resourceName, isPlaying: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear { syncPlayback() }
        .onDisappear { isPlaying = false }
        .onChange(of: scenePhase) { _, _ in syncPlayback() }
        .onChange(of: heroVideoEnabled) { _, _ in syncPlayback() }
    }

    private func syncPlayback() {
        isPlaying = heroVideoEnabled && scenePhase == .active
    }
}

private struct LoopingHeroVideoPlayer: UIViewRepresentable {
    let resourceName: String
    var isPlaying: Bool

    func makeUIView(context: Context) -> LoopingHeroVideoUIView {
        let view = LoopingHeroVideoUIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.load(resourceName: resourceName)
        return view
    }

    func updateUIView(_ uiView: LoopingHeroVideoUIView, context: Context) {
        isPlaying ? uiView.play() : uiView.pause()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: LoopingHeroVideoUIView, context: Context) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    static func dismantleUIView(_ uiView: LoopingHeroVideoUIView, coordinator: ()) {
        uiView.pause()
        uiView.unregister()
    }
}

final class LoopingHeroVideoUIView: UIView {
    private static weak var active: LoopingHeroVideoUIView?
    private static var playbackEnabled = true

    private let playerLayer = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        clipsToBounds = true
        layer.masksToBounds = true
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.masksToBounds = true
        playerLayer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(playerLayer)
        Self.active = self
        applyPlaybackEnabled()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    static func setPlaybackEnabled(_ enabled: Bool) {
        playbackEnabled = enabled
        active?.applyPlaybackEnabled()
    }

    func load(resourceName: String) {
        let name = (resourceName as NSString).deletingPathExtension
        let ext = (resourceName as NSString).pathExtension.isEmpty ? "mp4" : (resourceName as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else { return }

        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 1

        let player = AVQueuePlayer()
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = true
        player.allowsExternalPlayback = false
        looper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player
        playerLayer.player = player
        Self.active = self
        applyPlaybackEnabled()
    }

    func pause() {
        queuePlayer?.pause()
        playerLayer.isHidden = true
        playerLayer.opacity = 0
    }

    func play() {
        guard Self.playbackEnabled else {
            pause()
            return
        }
        playerLayer.isHidden = false
        playerLayer.opacity = 1
        queuePlayer?.play()
    }

    func unregister() {
        if Self.active === self { Self.active = nil }
        pause()
    }

    private func applyPlaybackEnabled() {
        Self.playbackEnabled ? play() : pause()
    }
}
