import Foundation
import UIKit

/// The signed-in artist's studio, kept on the phone. No account or backend.
@Observable
@MainActor
final class StudioStore {
    static let shared = StudioStore()

    private let key = "picartdo.studio.owned"
    private(set) var studio: OwnedStudio?

    var hasStudio: Bool { studio != nil }

    private init() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode(OwnedStudio.self, from: data) else { return }
        studio = saved
    }

    func publish(_ studio: OwnedStudio) {
        self.studio = studio
        save()
    }

    func addService(_ service: OwnedService) {
        guard var studio else { return }
        studio.services.append(service)
        self.studio = studio
        save()
    }

    func update(_ service: OwnedService) {
        guard var studio, let index = studio.services.firstIndex(where: { $0.id == service.id }) else { return }
        studio.services[index] = service
        self.studio = studio
        save()
    }

    func setActive(id: UUID, isActive: Bool) {
        guard var studio, let index = studio.services.firstIndex(where: { $0.id == id }) else { return }
        studio.services[index].isActive = isActive
        self.studio = studio
        save()
    }

    static func jpeg(_ image: UIImage) -> Data? {
        let maxEdge: CGFloat = 900
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxEdge ? maxEdge / longest : 1
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let scaled = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return scaled.jpegData(compressionQuality: 0.72)
    }

    private func save() {
        guard let studio, let data = try? JSONEncoder().encode(studio) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

struct OwnedStudio: Codable, Equatable {
    var name: String
    var city: String
    var bio: String
    var coverJPEG: Data?
    var avatarJPEG: Data?
    var coverAsset: String
    var avatarAsset: String
    var services: [OwnedService]
}

struct OwnedService: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var summary: String
    var type: String
    var priceAmount: Int
    var delivery: String
    var coverJPEG: Data?
    var coverAsset: String
    var isActive: Bool

    var priceLabel: String { "From $\(priceAmount)" }
}
