import AVFoundation
import SwiftUI
import UIKit

private struct FeedVideoEnabledKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var feedVideoEnabled: Bool {
        get { self[FeedVideoEnabledKey.self] }
        set { self[FeedVideoEnabledKey.self] = newValue }
    }
}

/// Muted looping post video. Each card has its own player so the Home feed
/// can autoplay more than one clip. Falls back to the still if the file is missing.
struct LoopingPostVideo: View {
    let resourceName: String
    var fallbackImageName: String? = nil

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.feedVideoEnabled) private var feedVideoEnabled
    @State private var isPlaying = false

    var body: some View {
        ZStack {
            if let fallbackImageName {
                ArtworkImage(imageName: fallbackImageName, contentMode: .fit, maxDimension: 1400)
            } else {
                Color.black
            }

            if isPlaying {
                LoopingPostVideoPlayer(resourceName: resourceName)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear { syncPlayback() }
        .onDisappear { isPlaying = false }
        .onChange(of: scenePhase) { _, _ in syncPlayback() }
        .onChange(of: feedVideoEnabled) { _, _ in syncPlayback() }
    }

    private func syncPlayback() {
        isPlaying = feedVideoEnabled && scenePhase == .active
    }
}

private struct LoopingPostVideoPlayer: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> LoopingPostVideoUIView {
        let view = LoopingPostVideoUIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.load(resourceName: resourceName)
        return view
    }

    func updateUIView(_ uiView: LoopingPostVideoUIView, context: Context) {
        uiView.play()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: LoopingPostVideoUIView, context: Context) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    static func dismantleUIView(_ uiView: LoopingPostVideoUIView, coordinator: ()) {
        uiView.shutdown()
    }
}

final class LoopingPostVideoUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .black
        clipsToBounds = true
        layer.masksToBounds = true
        playerLayer.videoGravity = .resizeAspect
        playerLayer.masksToBounds = true
        playerLayer.backgroundColor = UIColor.black.cgColor
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
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
        play()
    }

    func play() {
        playerLayer.isHidden = false
        playerLayer.opacity = 1
        queuePlayer?.play()
    }

    func shutdown() {
        queuePlayer?.pause()
        queuePlayer?.removeAllItems()
        playerLayer.player = nil
        looper = nil
        queuePlayer = nil
    }
}
