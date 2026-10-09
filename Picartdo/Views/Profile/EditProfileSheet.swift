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
    var coverFileName: String?

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

    var coverImage: UIImage? {
        guard let coverFileName else { return nil }
        let url = Self.directory.appendingPathComponent(coverFileName)
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

    mutating func setCover(_ image: UIImage) {
        try? FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        let name = "cover.jpg"
        let url = Self.directory.appendingPathComponent(name)
        if let data = image.jpegData(compressionQuality: 0.88) {
            try? data.write(to: url, options: .atomic)
            coverFileName = name
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
        avatarAsset: Artist.oscar.avatarImage,
        coverFileName: nil
    )
}

struct EditProfileSheet: View {
    @Binding var identity: ProfileIdentity
    @Binding var isPresented: Bool
    @State private var draft: ProfileIdentity = .defaults
    @State private var photoItem: PhotosPickerItem?
    @State private var coverItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCoverPicker = false
    @State private var saving = false
    @State private var specialtiesText = ""

    private var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
    }

    private var coverShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())

            VStack(spacing: 0) {
                header
                    .zIndex(2)

                VStack(spacing: 16) {
                    identityHero

                    group("Profile") {
                        fieldRow("Name", text: $draft.name)
                        divider
                        lockedRow("Username", value: "@\(draft.handle)")
                        divider
                        fieldRow("Bio", text: $draft.bio, axis: .vertical)
                        divider
                        fieldRow("Location", text: $draft.location)
                        divider
                        fieldRow("Website", text: $draft.website, url: true)
                    }

                    group("Shop") {
                        toggleRow("Commissions", isOn: $draft.commissionsOpen)
                        divider
                        toggleRow("Ships worldwide", isOn: $draft.shipsWorldwide)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                panelShape
                    .fill(.clear)
                    .glassEffect(.regular, in: panelShape)
            }
            .clipShape(panelShape)
            .overlay {
                panelShape.strokeBorder(.white.opacity(0.28), lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .padding(10)
            .contentShape(panelShape)
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .photosPicker(isPresented: $showCoverPicker, selection: $coverItem, matching: .images)
        .onAppear {
            draft = identity
            specialtiesText = identity.specialties.joined(separator: ", ")
        }
        .onChange(of: photoItem) { _, item in
            Task { await loadPhoto(item) }
        }
        .onChange(of: coverItem) { _, item in
            Task { await loadCover(item) }
        }
    }

    private var header: some View {
        HStack {
            Button {
                Haptics.tap()
                close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.18), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel")

            Spacer()

            Text("Edit profile")
                .font(PicardoType.wordmark(20))
                .foregroundStyle(.primary)

            Spacer()

            Button {
                save()
            } label: {
                Text("Save")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.picardoNeonRed, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || saving)
            .accessibilityLabel("Save")
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var identityHero: some View {
        ZStack {
            Button {
                Haptics.tap()
                showCoverPicker = true
            } label: {
                coverImage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change cover")

            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)

            Button {
                Haptics.tap()
                showPhotoPicker = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    portrait
                    Image(systemName: "camera.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.picardoNeonRed, in: Circle())
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change photo")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 168)
        .clipped()
        .clipShape(coverShape)
        .contentShape(coverShape)
        .overlay(coverShape.strokeBorder(.white.opacity(0.28), lineWidth: 1).allowsHitTesting(false))
    }

    private var portrait: some View {
        Group {
            if let custom = draft.avatarImage {
                Image(uiImage: custom).resizable().scaledToFill()
            } else {
                ArtworkImage(imageName: draft.avatarAsset, contentMode: .fill, maxDimension: 400)
            }
        }
        .frame(width: 92, height: 92)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.picardoNeonRed.opacity(0.9), lineWidth: 2))
    }

    private var coverImage: some View {
        Group {
            if let custom = draft.coverImage {
                Image(uiImage: custom).resizable().scaledToFill()
            } else {
                ArtworkImage(imageName: Artist.oscar.bannerImage, contentMode: .fill, maxDimension: 800)
            }
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
                .padding(.leading, 6)

            VStack(spacing: 0) { content() }
                .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )
        }
    }

    private func fieldRow(_ label: String, text: Binding<String>, axis: Axis = .horizontal, url: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(PicardoType.meta(8))
                .foregroundStyle(.secondary)
            if axis == .vertical {
                TextField(label, text: text, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(3...4)
            } else {
                TextField(label, text: text)
                    .font(.system(size: 15))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .textInputAutocapitalization(url ? .never : .words)
                    .keyboardType(url ? .URL : .default)
                    .textContentType(url ? .URL : nil)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func lockedRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(PicardoType.meta(8))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(label, isOn: isOn)
            .font(.system(size: 15, weight: .medium))
            .tint(Color.picardoNeonRed)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
    }

    private var divider: some View {
        Divider()
            .overlay(.white.opacity(0.18))
            .padding(.leading, 14)
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            var next = draft
            next.setAvatar(image)
            draft = next
        }
    }

    private func loadCover(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            var next = draft
            next.setCover(image)
            draft = next
        }
    }

    private func close() {
        isPresented = false
    }

    private func save() {
        guard !saving else { return }
        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !draft.name.isEmpty else { return }
        saving = true
        draft.bio = draft.bio.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.location = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.website = draft.website.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.studioCity = draft.location.split(separator: ",").first.map(String.init) ?? draft.studioCity
        draft.save()
        identity = draft
        Haptics.success()
        close()
        let snapshot = draft
        Task {
            try? await ProfileService.updateProfile(
                fullName: snapshot.name,
                tagline: snapshot.tagline,
                bio: snapshot.bio
            )
        }
    }
}
