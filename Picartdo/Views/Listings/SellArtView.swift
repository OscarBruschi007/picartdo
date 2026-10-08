import SwiftUI
import PhotosUI
import UIKit

enum SellComposeMode: String, CaseIterable, Identifiable {
    case post = "Post"
    case listing = "Listing"
    var id: String { rawValue }
}

enum PricingMode: String, CaseIterable {
    case fixed   = "Fixed Price"
    case auction = "Open to Bids"
}

struct SellArtView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    @State private var mode: SellComposeMode = .listing
    @State private var title             = ""
    @State private var caption           = ""
    @State private var selectedCategory: ArtCategory = .painting
    @State private var medium            = ""
    @State private var dimensions        = ""
    @State private var condition         = "Excellent"
    @State private var isSigned          = false
    @State private var hasCertificate    = false
    @State private var askPrice          = ""
    @State private var showSuccess       = false
    @State private var isSubmitting      = false
    @State private var showAuth          = false
    @State private var submitError       = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isAutofilling = false
    @State private var autofillGeneration = 0

    private let conditions = ["Mint", "Excellent", "Good", "Fair"]

    private var identity: ProfileIdentity { .load() }

    var isFormValid: Bool {
        switch mode {
        case .post:
            !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
        case .listing:
            !title.isEmpty && Double(askPrice) != nil
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            composeHeader
            PicardoEyebrow(text: "Create")
                .frame(maxWidth: .infinity, alignment: .leading)
            modePicker
            photoCard
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if mode == .post {
                postCard
            } else {
                listingFields
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular)
                .ignoresSafeArea()
        }
        .background(.clear)
        .alert(mode == .post ? "Posted!" : "Listed!", isPresented: $showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text(mode == .post
                 ? "Your post is live on Picartdo."
                 : "\"\(title)\" is now live on Picartdo.")
        }
        .sheet(isPresented: $showAuth) { AuthRequiredSheet() }
        .alert("Could not list artwork", isPresented: .init(
            get: { !submitError.isEmpty },
            set: { if !$0 { submitError = "" } }
        )) {
            Button("OK") { submitError = "" }
        } message: {
            Text(submitError)
        }
    }

    private var composeHeader: some View {
        HStack {
            Button("Cancel") { dismiss() }
                .font(.system(size: 16))
                .foregroundStyle(Color.picardoText)
            Spacer()
            Text(mode == .post ? "New Post" : "New Listing")
                .font(PicardoType.wordmark(18))
                .foregroundStyle(Color.picardoText)
            Spacer()
            Button { submit() } label: {
                Text(mode == .post ? "Post" : "List")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        isFormValid ? Color.picardoNeonRed : Color.picardoTextSecondary.opacity(0.35),
                        in: Capsule()
                    )
            }
            .disabled(!isFormValid)
        }
    }

    // MARK: Mode

    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(SellComposeMode.allCases) { item in
                Button {
                    withAnimation(PicardoMotion.quick) { mode = item }
                } label: {
                    VStack(spacing: 5) {
                        Text(item.rawValue)
                            .font(.system(size: 14, weight: mode == item ? .semibold : .medium))
                            .foregroundStyle(mode == item ? Color.picardoText : Color.picardoTextSecondary)
                        Rectangle()
                            .fill(mode == item ? Color.picardoAccent : Color.clear)
                            .frame(width: 22, height: 1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .picardoGlass(in: Capsule(), interactive: true)
    }

    // MARK: Photo

    private var photoCard: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.picardoAccent)
                                .frame(width: 52, height: 52)
                                .picardoGlass(in: Circle(), interactive: true)
                            VStack(spacing: 4) {
                                Text(mode == .post ? "From the studio" : "Photograph the work")
                                    .font(PicardoType.title(18))
                                    .foregroundStyle(Color.picardoText)
                                Text(mode == .post ? "A process shot, a night in the room" : "JPG · PNG · the piece as it hangs")
                                    .font(PicardoType.meta(8))
                                    .foregroundStyle(Color.picardoTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .overlay {
                    if isAutofilling {
                        Color.black.opacity(0.18)
                        ProgressView().tint(.white)
                    }
                }
                .overlay { goldCorners() }
                .picardoGlass(in: RoundedRectangle(cornerRadius: 28, style: .continuous), interactive: true)
        }
        .buttonStyle(.plain)
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
        .onChange(of: selectedImage) { _, image in
            guard mode == .listing, let image else { return }
            runAutofill(from: image)
        }
    }

    // MARK: Post

    private var postCard: some View {
        HStack(alignment: .top, spacing: 12) {
            sellerPortrait
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            TextField("A caption for the studio", text: $caption, axis: .vertical)
                .font(PicardoType.body(16))
                .foregroundStyle(Color.picardoText)
                .tint(Color.picardoNeonRed)
                .lineLimit(3...6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .picardoGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous), interactive: true)
    }

    // MARK: Listing

    private var listingFields: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                sellerPortrait
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Title of the piece", text: $title)
                        .font(PicardoType.title(18))
                        .foregroundStyle(Color.picardoText)
                        .tint(Color.picardoNeonRed)
                    TextField("The story behind it", text: $caption, axis: .vertical)
                        .font(PicardoType.body(14))
                        .foregroundStyle(Color.picardoText)
                        .tint(Color.picardoNeonRed)
                        .lineLimit(2...3)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.picardoNeonRed)
                TextField("0", text: $askPrice)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color.picardoText)
                    .keyboardType(.decimalPad)
                    .tint(Color.picardoNeonRed)
                Spacer(minLength: 8)
                Text("USD")
                    .font(PicardoType.meta(9))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.picardoNeonRed, in: Capsule())
            }

            HStack(spacing: 8) {
                compactPicker("Category", selection: $selectedCategory) {
                    ForEach(ArtCategory.allCases) { c in Text(c.rawValue).tag(c) }
                }
                compactField("Medium", text: $medium, hint: "Oil on canvas")
            }
            HStack(spacing: 8) {
                compactField("Size", text: $dimensions, hint: "24 × 36 in")
                compactPicker("Condition", selection: $condition) {
                    ForEach(conditions, id: \.self) { c in Text(c).tag(c) }
                }
            }
            HStack(spacing: 16) {
                compactToggle("Signed", isOn: $isSigned)
                compactToggle("Certificate", isOn: $hasCertificate)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .picardoGlass(in: RoundedRectangle(cornerRadius: 22, style: .continuous), interactive: true)
    }

    @ViewBuilder
    private var sellerPortrait: some View {
        if let custom = identity.avatarImage {
            Image(uiImage: custom).resizable().scaledToFill()
        } else {
            ArtworkImage(imageName: identity.avatarAsset, contentMode: .fill, maxDimension: 200)
        }
    }

    private func compactField(_ label: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(PicardoType.meta(8))
                .foregroundStyle(Color.picardoTextSecondary)
            TextField(hint, text: text)
                .font(.system(size: 13))
                .foregroundStyle(Color.picardoText)
                .tint(Color.picardoNeonRed)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .picardoGlass(in: RoundedRectangle(cornerRadius: 12, style: .continuous), interactive: true)
    }

    private func compactPicker<T: Hashable, Content: View>(
        _ label: String,
        selection: Binding<T>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(PicardoType.meta(8))
                .foregroundStyle(Color.picardoTextSecondary)
            Picker("", selection: selection, content: content)
                .labelsHidden()
                .tint(Color.picardoText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .picardoGlass(in: RoundedRectangle(cornerRadius: 12, style: .continuous), interactive: true)
    }

    private func compactToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        Toggle(label, isOn: isOn)
            .font(.system(size: 13, weight: .medium))
            .tint(Color.picardoNeonRed)
    }

    private func submit() {
        guard isFormValid else { return }
        if mode == .post {
            showSuccess = true
            return
        }
        submitListing()
    }

    private func runAutofill(from image: UIImage) {
        autofillGeneration += 1
        let generation = autofillGeneration
        isAutofilling = true
        Task {
            let draft = await ListingAutofillService.suggest(from: image)
            guard generation == autofillGeneration else { return }
            isAutofilling = false
            guard let draft else { return }
            title = draft.title
            caption = draft.caption
            selectedCategory = draft.category
            medium = draft.medium
            condition = draft.condition
            askPrice = "\(draft.askPrice)"
        }
    }

    private func submitListing() {
        guard !isSubmitting else { return }
        guard AppConfig.isBackendConfigured else {
            showSuccess = true
            return
        }
        guard session.isAuthenticated, let artistID = session.profile?.id else {
            showAuth = true
            return
        }
        guard let price = Double(askPrice) else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let images = selectedImage.map { [$0] } ?? []
                _ = try await ListingService.createListing(
                    title: title,
                    description: caption,
                    price: price,
                    category: selectedCategory,
                    medium: medium,
                    dimensions: dimensions,
                    images: images,
                    artistID: artistID
                )
                showSuccess = true
            } catch {
                submitError = error.localizedDescription
            }
        }
    }

    private func goldCorners() -> some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let len: CGFloat = 18
            let t: CGFloat = 1.25
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 12, y: 12 + len))
                    p.addLine(to: CGPoint(x: 12, y: 12))
                    p.addLine(to: CGPoint(x: 12 + len, y: 12))
                }
                .stroke(Color.picardoAccent, lineWidth: t)
                Path { p in
                    p.move(to: CGPoint(x: w - 12 - len, y: 12))
                    p.addLine(to: CGPoint(x: w - 12, y: 12))
                    p.addLine(to: CGPoint(x: w - 12, y: 12 + len))
                }
                .stroke(Color.picardoAccent, lineWidth: t)
                Path { p in
                    p.move(to: CGPoint(x: 12, y: h - 12 - len))
                    p.addLine(to: CGPoint(x: 12, y: h - 12))
                    p.addLine(to: CGPoint(x: 12 + len, y: h - 12))
                }
                .stroke(Color.picardoAccent, lineWidth: t)
                Path { p in
                    p.move(to: CGPoint(x: w - 12 - len, y: h - 12))
                    p.addLine(to: CGPoint(x: w - 12, y: h - 12))
                    p.addLine(to: CGPoint(x: w - 12, y: h - 12 - len))
                }
                .stroke(Color.picardoAccent, lineWidth: t)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Placeholder helper

extension View {
    func placeholder<C: View>(when show: Bool, @ViewBuilder placeholder: () -> C) -> some View {
        ZStack(alignment: .leading) {
            if show { placeholder() }
            self
        }
    }
}

struct PriceInputRow: View {
    let label: String
    @Binding var value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundStyle(.primary)
            Spacer()
            HStack(spacing: 3) {
                Text("$").font(.system(size: 13)).foregroundStyle(Color(.tertiaryLabel))
                TextField("0", text: $value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.picardoNeonRed)
                    .keyboardType(.decimalPad)
                    .tint(Color.picardoNeonRed)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
    }
}

#Preview {
    SellArtView()
        .environment(SessionStore())
}
