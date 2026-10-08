import Combine
import SwiftUI

struct ProfileStoriesRow: View {
    let stories: [ArtistStory]
    var onOpen: (ArtistStory) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stories")
                .font(.system(.title3, design: .serif).weight(.semibold))
                .foregroundStyle(Color.picardoText)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(stories) { story in
                        Button {
                            Haptics.tap()
                            onOpen(story)
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .strokeBorder(
                                        AngularGradient(
                                            colors: [Color.brand, Color.picardoAccent, Color.brand.opacity(0.35), Color.brand],
                                            center: .center
                                        ),
                                        lineWidth: 2.4
                                    )
                                    .frame(width: 78, height: 78)
                                    .overlay {
                                        ArtworkImage(imageName: story.coverImage, contentMode: .fill, maxDimension: 240)
                                            .frame(width: 68, height: 68)
                                            .clipShape(Circle())
                                    }
                                Text(story.title)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color.picardoText)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(story.title) story")
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct StoryViewer: View {
    let story: ArtistStory
    var onClose: () -> Void

    @State private var index = 0
    @State private var progress: CGFloat = 0
    @State private var paused = false

    private let duration: TimeInterval = 3.2

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()

                ArtworkImage(imageName: story.frames[safe: index] ?? story.coverImage, contentMode: .fill, maxDimension: 1600)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                LinearGradient(colors: [.black.opacity(0.45), .clear, .black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        ForEach(story.frames.indices, id: \.self) { i in
                            GeometryReader { bar in
                                Capsule().fill(.white.opacity(0.28))
                                Capsule()
                                    .fill(.white)
                                    .frame(width: bar.size.width * width(for: i))
                            }
                            .frame(height: 3)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    HStack {
                        Text(story.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            Haptics.tap()
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(.white.opacity(0.18), in: Circle())
                        }
                        .accessibilityLabel("Close story")
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12).onEnded { value in
                    if value.translation.height > 80 { onClose() }
                }
            )
            .onTapGesture { location in
                Haptics.select()
                if location.x < geo.size.width * 0.3 {
                    goBack()
                } else {
                    advance()
                }
            }
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            guard !paused else { return }
            progress += 0.05 / duration
            if progress >= 1 { advance() }
        }
        .statusBarHidden(true)
    }

    private func width(for i: Int) -> CGFloat {
        if i < index { return 1 }
        if i == index { return min(1, progress) }
        return 0
    }

    private func advance() {
        if index + 1 < story.frames.count {
            index += 1
            progress = 0
        } else {
            onClose()
        }
    }

    private func goBack() {
        if index > 0 {
            index -= 1
            progress = 0
        } else {
            progress = 0
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
