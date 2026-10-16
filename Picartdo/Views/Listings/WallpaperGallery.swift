import Photos
import SwiftUI

// MARK: - Wallpaper packs (Services → Wallpapers)

struct WallpaperPack: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let images: [String]

    /// Names of the bundled phone wallpapers (Assets.xcassets/wave_*).
    static let waves = WallpaperPack(
        id: "3d-waves",
        title: "3D Waves",
        subtitle: "26 phone wallpapers · tap one to preview and save",
        images: [
            "wave_black", "wave_onyx", "wave_graphite", "wave_silver", "wave_moonstone", "wave_crystal",
            "wave_midnight_purple", "wave_pearlescent_purple", "wave_magic", "wave_cyan", "wave_mint",
            "wave_grass", "wave_volt", "wave_sunrise", "wave_bronze", "wave_rose_gold", "wave_lava",
            "wave_passion", "wave_cherry", "wave_garnet", "wave_lust", "wave_watermelon", "wave_candy",
            "wave_pearlescent_candy", "wave_rainbow", "wave_retro",
        ]
    )

    static func displayName(_ image: String) -> String {
        image.replacingOccurrences(of: "wave_", with: "")
            .split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

/// Horizontal strip of phone-shaped wallpaper previews.
struct WallpaperPackSection: View {
    let pack: WallpaperPack
    @State private var preview: WallpaperPreviewItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pack.title)
                    .font(.system(size: 19, weight: .bold))
                Text(pack.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(pack.images, id: \.self) { name in
                        Button {
                            Haptics.tap()
                            preview = WallpaperPreviewItem(name: name)
                        } label: {
                            VStack(spacing: 6) {
                                ArtworkImage(imageName: name, contentMode: .fill, maxDimension: 500)
                                    .frame(width: 110, height: 238)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                                    )
                                Text(WallpaperPack.displayName(name))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(WallpaperPack.displayName(name)) wallpaper")
                    }
                }
                .padding(.horizontal, 18)
            }
        }
        .fullScreenCover(item: $preview) { item in
            WallpaperPreview(name: item.name)
        }
    }
}

struct WallpaperPreviewItem: Identifiable {
    let name: String
    var id: String { name }
}

/// Full-screen preview with a Save to Photos button.
struct WallpaperPreview: View {
    let name: String
    @Environment(\.dismiss) private var dismiss
    @State private var status: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ArtworkImage(imageName: name, contentMode: .fill, maxDimension: 2600)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .glassEffect(.regular, in: Circle())
                    }
                    .accessibilityLabel("Close")
                    Spacer()
                }
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 10) {
                    if let status {
                        Text(status)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .transition(.opacity)
                    }
                    Button(action: save) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 14)
                            .glassEffect(.regular, in: Capsule())
                    }
                    Text(WallpaperPack.displayName(name))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.bottom, 30)
            }
        }
    }

    private func save() {
        guard let image = UIImage(named: name) else { return }
        Haptics.tap()
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { auth in
            guard auth == .authorized || auth == .limited else {
                Task { @MainActor in
                    withAnimation { status = "Allow Photos access in Settings to save." }
                }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { ok, _ in
                Task { @MainActor in
                    if ok { Haptics.success() }
                    withAnimation { status = ok ? "Saved to Photos" : "Couldn't save. Try again." }
                }
            }
        }
    }
}

/// The Wallpapers service page: a full grid of phone wallpapers, nothing else.
struct WallpaperGalleryPage: View {
    let pack: WallpaperPack
    @State private var preview: WallpaperPreviewItem?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Wallpapers")
                        .font(.system(size: 30, weight: .black, design: .serif))
                    Text("\(pack.title) · \(pack.images.count) phone wallpapers · tap one to preview and save")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(pack.images, id: \.self) { name in
                        Button {
                            Haptics.tap()
                            preview = WallpaperPreviewItem(name: name)
                        } label: {
                            VStack(spacing: 6) {
                                Color.black
                                    .aspectRatio(9.0 / 19.5, contentMode: .fit)
                                    .overlay {
                                        ArtworkImage(imageName: name, contentMode: .fill, maxDimension: 500)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                                    )
                                Text(WallpaperPack.displayName(name))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(WallpaperPack.displayName(name)) wallpaper")
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 110)
            }
        }
        .background(Color.picardoBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .fullScreenCover(item: $preview) { item in
            WallpaperPreview(name: item.name)
        }
    }
}
