import SwiftUI
import PhotosUI
import UIKit

struct ProfileIdentity: Codable, Equatable {
    var name: String
    var tagline: String
    var bio: String
    var location: String
    var specialties: [String]
    var startingPrice: String
    var commissionsOpen: Bool
    var replyTime: String
    var shipsWorldwide: Bool
    var website: String
    var inspiredBy: String
    var studioCity: String
    var sinceYear: Int
    var avatarFileName: String?
    var avatarAsset: String

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var handle: String {
        name.lowercased().replacingOccurrences(of: " ", with: "")
    }

    var avatarImage: UIImage? {
        guard let avatarFileName else { return nil }
        let url = Self.directory.appendingPathComponent(avatarFileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    mutating func setAvatar(_ image: UIImage) {
        try? FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        let name = "avatar.jpg"
        let url = Self.directory.appendingPathComponent(name)
        if let data = image.jpegData(compressionQuality: 0.88) {
            try? data.write(to: url, options: .atomic)
            avatarFileName = name
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static var hasSaved: Bool {
        UserDefaults.standard.data(forKey: storageKey) != nil
    }

    static func load() -> ProfileIdentity {
        var identity: ProfileIdentity
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(ProfileIdentity.self, from: data) {
            identity = decoded
        } else {
            identity = .defaults
        }
        let before = identity
        identity.migratingStaleCopy()
        if identity != before { identity.save() }
        return identity
    }

    mutating func migratingStaleCopy() {
        if location.localizedCaseInsensitiveContains("miami") {
            location = "Toronto, ON"
        }
        if studioCity.localizedCaseInsensitiveContains("miami") {
            studioCity = "Toronto"
        }
        if bio.localizedCaseInsensitiveContains("miami")
            || bio.contains("visual language")
            || bio.localizedCaseInsensitiveContains("mandala") {
            bio = Self.shortBio
        }
        if avatarFileName == nil {
            avatarAsset = Artist.oscar.avatarImage
        }
        if !UserDefaults.standard.bool(forKey: Self.oscarPhotoStamp) {
            avatarAsset = Artist.oscar.avatarImage
            avatarFileName = nil
            UserDefaults.standard.set(true, forKey: Self.oscarPhotoStamp)
        }
    }

    static let shortBio = "Abstract art."

    private static let storageKey = "profile.identity.v2"
    private static let oscarPhotoStamp = "profile.photo.oscar.v1"

    private static var directory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Picartdo", isDirectory: true)
    }

    static let defaults = ProfileIdentity(
        name: Artist.oscar.name,
        tagline: Artist.oscar.tagline,
        bio: Artist.oscar.bio,
        location: Artist.oscar.location,
        specialties: Artist.oscar.specialties,
        startingPrice: Artist.oscar.startingPrice,
        commissionsOpen: Artist.oscar.availableForCommissions,
        replyTime: "Replies in under an hour",
        shipsWorldwide: true,
        website: "",
        inspiredBy: "Mandalas, Jung, and winter light",
        studioCity: "Toronto",
        sinceYear: 2018,
        avatarFileName: nil,
        avatarAsset: Artist.oscar.avatarImage
    )
}

struct EditProfileSheet: View {
    @Binding var identity: ProfileIdentity
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ProfileIdentity = .defaults
    @State private var photoItem: PhotosPickerItem?
    @State private var saving = false
    @State private var specialtiesText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    HStack(spacing: 16) {
                        portrait
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Text("Change photo")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("About you") {
                    TextField("Name", text: $draft.name)
                    TextField("What you make", text: $draft.tagline)
                    TextField("City", text: $draft.location)
                    TextField("Studio in", text: $draft.studioCity)
                    TextField("Inspired by", text: $draft.inspiredBy)
                    TextField("Bio", text: $draft.bio, axis: .vertical)
                        .lineLimit(4...10)
                    TextField("Mediums, separated by commas", text: $specialtiesText)
                }

                Section("Studio") {
                    Toggle("Open for commissions", isOn: $draft.commissionsOpen)
                    TextField("Commissions from", text: $draft.startingPrice)
                    TextField("Reply time", text: $draft.replyTime)
                    Toggle("Ships worldwide", isOn: $draft.shipsWorldwide)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(draft.name.trimmingCharacters(in: .whitespaces).isEmpty || saving)
                }
            }
            .onAppear {
                draft = identity
                specialtiesText = identity.specialties.joined(separator: ", ")
            }
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
            }
        }
    }

    private var portrait: some View {
        Group {
            if let custom = draft.avatarImage {
                Image(uiImage: custom).resizable().scaledToFill()
            } else {
                ArtworkImage(imageName: draft.avatarAsset, contentMode: .fill, maxDimension: 400)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(Circle())
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            draft.setAvatar(image)
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.tagline = draft.tagline.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.bio = draft.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.location = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.studioCity = draft.studioCity.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.inspiredBy = draft.inspiredBy.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.specialties = specialtiesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        draft.save()
        identity = draft
        Haptics.success()
        try? await ProfileService.updateProfile(fullName: draft.name, tagline: draft.tagline, bio: draft.bio)
        dismiss()
    }
}
