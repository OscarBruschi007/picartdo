import SwiftUI
import CoreMotion

struct ShelfBlock: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var zoom: Namespace.ID
    var onOpen: (String) -> Void

    @State private var picked: String?
    @State private var tilt = StudioMotionTilt()

    private var names: [String] {
        if case .shelf(let n) = block.payload { return n }
        return []
    }

    var body: some View {
        StudioBlockChrome(style: block.style, accent: accent) {
            VStack(alignment: .leading, spacing: 10) {
                StudioQuoted(text: "SHELF", color: accent)
                if names.isEmpty {
                    StudioEmptyBlock(line: "SHELF IS EMPTY")
                } else {
                    ZStack(alignment: .bottom) {
                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(names, id: \.self) { name in
                                ArtworkImage(imageName: name, contentMode: .fill, maxDimension: 500)
                                    .frame(width: picked == name ? 92 : 64, height: picked == name ? 118 : 86)
                                    .clipped()
                                    .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
                                    .offset(x: tilt.roll * (picked == name ? 8 : 3))
                                    .modifier(StudioZoomSource(imageName: name, zoom: zoom))
                                    .onTapGesture {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(PicardoMotion.transition) {
                                            picked = picked == name ? nil : name
                                        }
                                    }
                                    .onLongPressGesture { onOpen(name) }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .fill(Color(red: 0.62, green: 0.48, blue: 0.32))
                            .frame(height: 10)
                    }
                }
            }
        }
        .onAppear { tilt.start() }
        .onDisappear { tilt.stop() }
        .accessibilityLabel("Shelf of works")
    }
}

@MainActor
@Observable
final class StudioMotionTilt {
    var roll: CGFloat = 0
    private let motion = CMMotionManager()

    func start() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1 / 30
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let roll = data?.attitude.roll else { return }
            Task { @MainActor in
                self?.roll = CGFloat(max(-1, min(1, roll)))
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
    }
}
