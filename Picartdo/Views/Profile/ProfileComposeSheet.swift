import SwiftUI
import PhotosUI
import AVKit
import UniformTypeIdentifiers

struct QualityStarRow: View {
    let stars: Int
    var size: CGFloat = 13
    var value: Double? = nil

    private var filled: Int { min(5, max(0, stars)) }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: index <= filled ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(Color(red: 0.13, green: 0.13, blue: 0.13))
            }
            if let value {
                Text(String(format: "%.1f", value))
                    .font(.system(size: size + 1, weight: .semibold))
                    .foregroundStyle(Color(red: 0.13, green: 0.13, blue: 0.13))
            }
        }
        .accessibilityLabel("\(filled) out of 5 stars")
        .accessibilityAddTraits(.isImage)
    }
}

struct ProfileComposeSheet: View {
    var store: ProfilePostStore
    var onSell: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var videoItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var videoURL: URL?
    @State private var isVideo = false

    private var canPost: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || image != nil || videoURL != nil
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    ArtworkImage(imageName: Artist.oscar.avatarImage, contentMode: .fill, maxDimension: 200)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    TextField("What's happening?", text: $text, axis: .vertical)
                        .font(.system(size: 18))
                        .lineLimit(4...10)
                }
                .padding(16)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                self.image = nil
                                photoItem = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(.black.opacity(0.55), in: Circle())
                            }
                            .padding(26)
                            .accessibilityLabel("Remove photo")
                        }
                } else if let videoURL {
                    ProfileVideoThumb(url: videoURL)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                }

                Spacer()

                HStack(spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        composeTool("photo", "Photo")
                    }
                    PhotosPicker(selection: $videoItem, matching: .videos) {
                        composeTool("video", "Video")
                    }
                    Button {
                        dismiss()
                        onSell()
                    } label: {
                        composeTool("tag", "Sell")
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .overlay(alignment: .top) { Rectangle().fill(Color(white: 0.9)).frame(height: 1) }
            }
            .background(Color.white)
            .navigationTitle("New post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { publish() }
                        .fontWeight(.semibold)
                        .disabled(!canPost)
                }
            }
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
            }
            .onChange(of: videoItem) { _, item in
                Task { await loadVideo(item) }
            }
        }
    }

    private func composeTool(_ icon: String, _ label: String) -> some View {
        Label(label, systemImage: icon)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(red: 0.13, green: 0.13, blue: 0.13))
            .padding(.horizontal, 10)
            .frame(height: 36)
            .contentShape(Rectangle())
    }

    private func publish() {
        var post = ProfilePost(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
        if let image, let name = store.saveImage(image) {
            post.storedImageName = name
            post.qualityStars = 3
        }
        if let videoURL, let name = store.saveVideo(from: videoURL) {
            post.storedVideoName = name
            post.isVideo = true
        }
        store.add(post)
        dismiss()
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        videoURL = nil
        videoItem = nil
        isVideo = false
        if let data = try? await item.loadTransferable(type: Data.self),
           let loaded = UIImage(data: data) {
            image = loaded
        }
    }

    private func loadVideo(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        image = nil
        photoItem = nil
        isVideo = true
        if let movie = try? await item.loadTransferable(type: ProfileMovieFile.self) {
            videoURL = movie.url
        }
    }
}

struct ProfileMovieFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".mov")
            try FileManager.default.copyItem(at: received.file, to: dest)
            return ProfileMovieFile(url: dest)
        }
    }
}

struct ProfileVideoThumb: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(white: 0.12)
            }
            Image(systemName: "play.fill")
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(.black.opacity(0.45), in: Circle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .task { image = await thumbnail() }
        .accessibilityLabel("Video")
    }

    private func thumbnail() async -> UIImage? {
        await Task.detached {
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.4, preferredTimescale: 600)
            guard let cg = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
            return UIImage(cgImage: cg)
        }.value
    }
}

struct ProfilePostRow: View {
    let post: ProfilePost
    var store: ProfilePostStore
    var avatarName: String
    var displayName: String
    var handle: String
    var ink: Color
    var mute: Color
    var onOpenListing: ((Artwork) -> Void)? = nil

    @State private var playURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ArtworkImage(imageName: avatarName, contentMode: .fill, maxDimension: 200)
                .frame(width: 40, height: 40)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ink)
                    Text(handle)
                        .foregroundStyle(mute)
                    Text("·")
                        .foregroundStyle(mute)
                    Text(post.timeAgo)
                        .foregroundStyle(mute)
                }
                .font(.system(size: 15))
                .lineLimit(1)

                if !post.text.isEmpty {
                    Text(post.text)
                        .font(.system(size: 16))
                        .foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if post.hasMedia {
                    media
                }

                if post.isListing, let price = post.listingPrice {
                    HStack(spacing: 8) {
                        QualityStarRow(stars: post.qualityStars, size: 11)
                        Text("For sale")
                            .font(.system(size: 13, weight: .medium))
                        Text(price, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(ink)
                    .padding(.top, 2)
                } else if post.qualityStars > 0, post.hasMedia {
                    QualityStarRow(stars: post.qualityStars, size: 11)
                        .padding(.top, 2)
                }

                HStack(spacing: 0) {
                    threadAction("bubble.right", "\(max(1, post.likeCount / 9))")
                    threadAction("arrow.2.squarepath", "\(max(0, post.likeCount / 14))")
                    threadAction("heart", "\(post.likeCount)")
                    Spacer(minLength: 0)
                }
                .font(.system(size: 13))
                .foregroundStyle(mute)
                .padding(.top, 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .fullScreenCover(isPresented: Binding(
            get: { playURL != nil },
            set: { if !$0 { playURL = nil } }
        )) {
            if let playURL {
                ProfileVideoPlayer(url: playURL)
            }
        }
    }

    private func threadAction(_ icon: String, _ count: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
            Text(count)
                .font(.system(size: 12))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var media: some View {
        Color.clear
            .frame(height: 200)
            .overlay {
                if let name = post.storedVideoName {
                    let url = store.videoURL(name)
                    Button { playURL = url } label: {
                        ProfileVideoThumb(url: url)
                    }
                    .buttonStyle(.plain)
                } else if post.isVideo, let asset = post.assetImageName {
                    ZStack {
                        ArtworkImage(imageName: asset, contentMode: .fill, maxDimension: 900)
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                } else if let name = post.storedImageName, let ui = UIImage(contentsOfFile: store.imageURL(name).path) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else if let asset = post.assetImageName {
                    ArtworkImage(imageName: asset, contentMode: .fill, maxDimension: 900)
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color(white: 0.9), lineWidth: 1)
            )
    }
}

private struct ProfileVideoPlayer: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: AVPlayer(url: url))
                .ignoresSafeArea()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.2), in: Circle())
            }
            .padding(20)
            .accessibilityLabel("Close video")
        }
    }
}
