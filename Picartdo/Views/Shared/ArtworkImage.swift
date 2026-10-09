import SwiftUI
import UIKit

/// Single image renderer for every artwork/post thumbnail.
/// Decodes off the main thread and caches a screen-sized bitmap so lists
/// don't upload 4K photos every frame.
struct ArtworkImage: View {
    enum Source: Equatable {
        case artwork(Artwork)
        case named(String)
        case url(URL)
    }

    let source: Source
    var contentMode: ContentMode = .fill
    /// Longest edge in pixels. List cards stay around 900; heroes can go higher.
    var maxDimension: CGFloat = 1080

    @State private var loaded: UIImage?

    init(artwork: Artwork, contentMode: ContentMode = .fill, maxDimension: CGFloat = 1080) {
        self.source = .artwork(artwork)
        self.contentMode = contentMode
        self.maxDimension = maxDimension
    }

    init(imageName: String, contentMode: ContentMode = .fill, maxDimension: CGFloat = 1080) {
        self.source = .named(imageName)
        self.contentMode = contentMode
        self.maxDimension = maxDimension
    }

    init(url: URL, contentMode: ContentMode = .fill, maxDimension: CGFloat = 1080) {
        self.source = .url(url)
        self.contentMode = contentMode
        self.maxDimension = maxDimension
    }

    var body: some View {
        let shown = loaded ?? ArtworkImageCache.shared.peek(source, maxDimension: maxDimension)
        Group {
            if let shown {
                Image(uiImage: shown)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                Color.picardoCardMid
            }
        }
        .task(id: ArtworkImageCache.key(for: source, maxDimension: maxDimension)) {
            if loaded == nil, let peek = ArtworkImageCache.shared.peek(source, maxDimension: maxDimension) {
                loaded = peek
            }
            if let image = await ArtworkImageCache.shared.image(for: source, maxDimension: maxDimension) {
                if loaded !== image {
                    loaded = image
                }
            }
        }
    }
}

extension Artwork {
    var primaryImageURL: URL? {
        guard let first = imageURLs.first, !first.isEmpty else { return nil }
        return URL(string: first)
    }
}

// MARK: - Memory + disk cache

final class ArtworkImageCache: @unchecked Sendable {
    static let shared = ArtworkImageCache()

    private let memory = NSCache<NSString, UIImage>()
    private let ioQueue = DispatchQueue(label: "com.picartdo.artwork-image-cache", qos: .utility)
    private let session: URLSession
    private let diskDirectory: URL
    private let lock = NSLock()
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    private init() {
        memory.countLimit = 180
        memory.totalCostLimit = 64 * 1024 * 1024

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskDirectory = caches.appendingPathComponent("ArtworkImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)

        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 24 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024,
            diskPath: "ArtworkImageURLCache"
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
    }

    func clear() {
        memory.removeAllObjects()
        lock.withLock { inFlight.removeAll() }
        try? FileManager.default.removeItem(at: diskDirectory)
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
        session.configuration.urlCache?.removeAllCachedResponses()
    }

    static func key(for source: ArtworkImage.Source, maxDimension: CGFloat = 1080) -> String {
        let base: String
        switch source {
        case .artwork(let art):
            if let url = art.primaryImageURL { base = "url:\(url.absoluteString)" }
            else { base = "asset:\(art.imageName)" }
        case .named(let name):
            base = "asset:\(name)"
        case .url(let url):
            base = "url:\(url.absoluteString)"
        }
        return "\(base)|d\(Int(maxDimension))"
    }

    /// Memory only — never decode on the main thread.
    func peek(_ source: ArtworkImage.Source, maxDimension: CGFloat = 1080) -> UIImage? {
        memory.object(forKey: Self.key(for: source, maxDimension: maxDimension) as NSString)
    }

    func pixelSize(for artwork: Artwork) -> CGSize {
        if let image = peek(.artwork(artwork), maxDimension: 1080) {
            return image.size
        }
        return CGSize(width: 3, height: 4)
    }

    func image(for source: ArtworkImage.Source, maxDimension: CGFloat = 1080) async -> UIImage? {
        let key = Self.key(for: source, maxDimension: maxDimension)
        if let cached = memory.object(forKey: key as NSString) { return cached }

        let existing: Task<UIImage?, Never>? = lock.withLock { inFlight[key] }
        if let existing { return await existing.value }

        let task = Task<UIImage?, Never> { [weak self] in
            await self?.loadUncached(source, key: key, maxDimension: maxDimension)
        }
        lock.withLock { inFlight[key] = task }
        let result = await task.value
        lock.withLock { inFlight[key] = nil }
        return result
    }

    /// Decode common assets ahead of first scroll.
    func warmListedAssets() {
        ioQueue.async { [weak self] in
            guard let self else { return }
            var names: [String] = Artwork.samples.map(\.imageName)
            names += (1...9).map { String(format: "tattoo_studio_%02d", $0) }
            names += ["tattoo_hero"]
            for name in names {
                let source = ArtworkImage.Source.named(name)
                let key = Self.key(for: source, maxDimension: 900)
                if self.memory.object(forKey: key as NSString) != nil { continue }
                guard let raw = UIImage(named: name) else { continue }
                let sized = Self.downsample(raw, maxDimension: 900)
                self.store(sized, key: key)
            }
        }
    }

    private func loadUncached(_ source: ArtworkImage.Source, key: String, maxDimension: CGFloat) async -> UIImage? {
        if let cached = memory.object(forKey: key as NSString) { return cached }

        let remote: URL?
        let assetName: String?
        switch source {
        case .artwork(let art):
            remote = art.primaryImageURL
            assetName = art.imageName
        case .named(let name):
            remote = nil
            assetName = name
        case .url(let url):
            remote = url
            assetName = nil
        }

        if let remote {
            if let disk = loadFromDisk(url: remote) {
                let sized = Self.downsample(disk, maxDimension: maxDimension)
                store(sized, key: key)
                return sized
            }
            if let downloaded = await download(remote) {
                let sized = Self.downsample(downloaded, maxDimension: maxDimension)
                store(sized, key: key)
                saveToDisk(downloaded, url: remote)
                return sized
            }
        }

        if let assetName {
            let sized: UIImage? = await withCheckedContinuation { continuation in
                ioQueue.async {
                    guard let raw = UIImage(named: assetName) else {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: Self.downsample(raw, maxDimension: maxDimension))
                }
            }
            if let sized {
                store(sized, key: key)
                return sized
            }
        }
        return nil
    }

    private static func downsample(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        let longest = max(pixelWidth, pixelHeight)
        guard longest > maxDimension, longest > 0 else { return image }

        let scale = maxDimension / longest
        let newSize = CGSize(width: max(1, pixelWidth * scale), height: max(1, pixelHeight * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func download(_ url: URL) async -> UIImage? {
        do {
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return nil
            }
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func store(_ image: UIImage, key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        memory.setObject(image, forKey: key as NSString, cost: max(cost, 1))
    }

    private func diskFile(for url: URL) -> URL {
        let name = url.absoluteString.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            ?? url.lastPathComponent
        return diskDirectory.appendingPathComponent(name)
    }

    private func loadFromDisk(url: URL) -> UIImage? {
        let file = diskFile(for: url)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return UIImage(contentsOfFile: file.path)
    }

    private func saveToDisk(_ image: UIImage, url: URL) {
        let file = diskFile(for: url)
        ioQueue.async {
            guard let data = image.jpegData(compressionQuality: 0.9) else { return }
            try? data.write(to: file, options: .atomic)
        }
    }
}
