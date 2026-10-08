import SwiftUI
import PhotosUI

/// "Wall Test" — photograph the wall you're actually considering, drop the
/// piece onto it at a size you control, and see it before you buy. The
/// direct answer to the single biggest objection in buying art online:
/// will this actually look right in my space.
struct WallTestView: View {
    let artwork: Artwork
    @Environment(\.dismiss) private var dismiss

    @State private var wallPhotoItem: PhotosPickerItem?
    @State private var wallImage: UIImage?
    @State private var isLoadingPhoto = false

    // Placement, expressed relative to the photo's own displayed size so
    // it maps cleanly onto the full-resolution export later.
    @State private var scale: CGFloat = 0.34
    @State private var lastScale: CGFloat = 0.34
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if let wallImage {
                    placementView(wallImage: wallImage)
                } else {
                    pickerView
                }
            }
            .background(Color.picardoBackground.ignoresSafeArea())
            .navigationTitle("Wall Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(wallImage == nil ? "Cancel" : "Retake") {
                        if wallImage == nil {
                            dismiss()
                        } else {
                            wallImage = nil
                            wallPhotoItem = nil
                            resetPlacement()
                        }
                    }
                    .foregroundStyle(Color.picardoTextSecondary)
                }
                if wallImage != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Share") { prepareShare() }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.picardoAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ActivityShareSheet(items: [shareImage])
            }
        }
        .onChange(of: wallPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                isLoadingPhoto = true
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    wallImage = image
                }
                isLoadingPhoto = false
            }
        }
    }

    // MARK: - Step 1: pick a wall

    private var pickerView: some View {
        VStack(spacing: 22) {
            Spacer()

            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(Color.picardoTextSecondary)

            VStack(spacing: 10) {
                Text("See it on your wall")
                    .font(PicardoType.display(26))
                    .foregroundStyle(Color.picardoText)

                Text("Photograph the wall you're thinking about. We'll drop \u{201c}\(artwork.title)\u{201d} onto it so you can judge it before you buy, not after.")
                    .font(PicardoType.body(15))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 36)
            }

            if isLoadingPhoto {
                ProgressView().padding(.top, 4)
            } else {
                PhotosPicker(selection: $wallPhotoItem, matching: .images) {
                    Text("Choose a Photo")
                        .font(PicardoType.cta())
                        .kerning(1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.picardoText)
                }
                .padding(.horizontal, 32)
                .padding(.top, 4)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 2: place it

    private func placementView(wallImage: UIImage) -> some View {
        GeometryReader { geo in
            let displaySize = fitSize(of: wallImage.size, in: geo.size)

            ZStack {
                Image(uiImage: wallImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)

                ArtworkImage(artwork: artwork, contentMode: .fit)
                    .frame(width: displaySize.width * scale)
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 8)
                    .offset(offset)
                    .gesture(placementGesture)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .overlay(alignment: .bottom) {
                VStack(spacing: 6) {
                    if !artwork.dimensions.isEmpty {
                        Text("\(artwork.dimensions) · pinch to resize, drag to place")
                            .font(PicardoType.meta(10))
                    } else {
                        Text("Pinch to resize, drag to place")
                            .font(PicardoType.meta(10))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(.bottom, 22)
            }
        }
    }

    private var placementGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(width: lastOffset.width + value.translation.width,
                                     height: lastOffset.height + value.translation.height)
                }
                .onEnded { _ in lastOffset = offset },
            MagnificationGesture()
                .onChanged { value in
                    scale = min(max(lastScale * value, 0.12), 0.92)
                }
                .onEnded { _ in lastScale = scale }
        )
    }

    private func resetPlacement() {
        scale = 0.34; lastScale = 0.34
        offset = .zero; lastOffset = .zero
    }

    /// The actual on-screen size of an aspect-fit image inside a container —
    /// needed because a letterboxed photo's own size isn't the container's.
    private func fitSize(of imageSize: CGSize, in container: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return container }
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = container.width / container.height
        if imageAspect > containerAspect {
            return CGSize(width: container.width, height: container.width / imageAspect)
        } else {
            return CGSize(width: container.height * imageAspect, height: container.height)
        }
    }

    // MARK: - Export

    @MainActor
    private func prepareShare() {
        guard let wallImage else { return }
        guard let overlay = UIImage(named: artwork.imageName) else {
            // Backend-hosted artwork without a bundled asset: fall back to
            // sharing the placement as SwiftUI renders it right now.
            let renderer = ImageRenderer(content: placementView(wallImage: wallImage).frame(width: 1080, height: 1080))
            renderer.scale = 3
            if let uiImage = renderer.uiImage {
                shareImage = uiImage
                showShareSheet = true
            }
            return
        }

        // Roughly matches the on-screen frame used while placing, so what
        // you saw is what you get.
        let approxContainer = CGSize(width: 400, height: 620)
        let displaySize = fitSize(of: wallImage.size, in: approxContainer)
        let ratio = wallImage.size.width / max(displaySize.width, 1)

        let artWidth = displaySize.width * scale * ratio
        let artHeight = artWidth * (overlay.size.height / max(overlay.size.width, 1))
        let centerX = wallImage.size.width / 2 + offset.width * ratio
        let centerY = wallImage.size.height / 2 + offset.height * ratio
        let rect = CGRect(x: centerX - artWidth / 2, y: centerY - artHeight / 2, width: artWidth, height: artHeight)

        let renderer = UIGraphicsImageRenderer(size: wallImage.size)
        let composite = renderer.image { ctx in
            wallImage.draw(in: CGRect(origin: .zero, size: wallImage.size))
            ctx.cgContext.saveGState()
            ctx.cgContext.setShadow(offset: CGSize(width: 0, height: 10), blur: 22, color: UIColor.black.withAlphaComponent(0.4).cgColor)
            overlay.draw(in: rect)
            ctx.cgContext.restoreGState()
        }
        shareImage = composite
        showShareSheet = true
    }
}

/// Thin wrapper around UIActivityViewController so Wall Test can hand its
/// composite straight to Messages, Photos, or anywhere else.
private struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    WallTestView(artwork: Artwork.samples[0])
}
