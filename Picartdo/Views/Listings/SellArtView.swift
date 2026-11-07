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
    /// Opens the artist's own studio after publishing (switches to the Profile tab).
    var onViewStudio: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session

    @State private var mode: SellComposeMode = .listing
    @State private var title             = ""
    @State private var caption           = ""
    @State private var selectedCategory: ArtCategory = .painting
    @State private var medium            = ""
    @State private var dimensions        = ""
    @State private var year              = "2026"
    @State private var condition         = "Excellent"
    @State private var edition           = "Original 1/1"
    @State private var currency          = "CAD"
    @State private var isSigned          = false
    @State private var hasCertificate    = false
    @State private var isFramed          = false
    @State private var shipsWorldwide    = true
    @State private var shipsFrom         = ""
    @State private var location          = ""
    @State private var tags              = ""
    @State private var allowComments     = true
    @State private var askPrice          = ""
    @State private var showSuccess       = false
    @State private var isSubmitting      = false
    @State private var showAuth          = false
    @State private var submitError       = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isAutofilling = false
    @State private var autofillGeneration = 0
    @State private var confirmDiscard = false
    @State private var formHeight: CGFloat = 0
    @State private var showDetails = false
    @State private var autofillStep = ""
    @State private var aiFilled = false

    /// Anything the artist would be sad to lose.
    private var hasDraft: Bool {
        selectedImage != nil
            || ![title, caption, medium, dimensions, tags, askPrice]
                .allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func cancelTapped() {
        if hasDraft {
            Haptics.warning()
            confirmDiscard = true
        } else {
            dismiss()
        }
    }

    private let conditions = ["Mint", "Excellent", "Good", "Fair"]
    private let editions = ["Original 1/1", "Limited edition", "Open edition", "Print"]
    private let currencies = ["CAD", "USD", "EUR", "GBP"]

    private var identity: ProfileIdentity { .load() }

    var isFormValid: Bool {
        switch mode {
        case .post:
            !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil
        case .listing:
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && Double(askPrice) != nil
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            // Header stays put; only the form scrolls, so Cancel and List are
            // always reachable, even with the keyboard up.
            composeHeader
                .padding(.horizontal, 16)
            modePicker
                .padding(.horizontal, 16)
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        photoCard
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(minHeight: 168)
                        Group {
                            if mode == .post {
                                postFields
                            } else {
                                listingFields
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    // Always laid out at the full, keyboard-free height, so it looks exactly
                    // as before; when the keyboard takes space, the form simply scrolls.
                    .frame(height: max(formHeight, geo.size.height))
                }
                .onAppear { formHeight = max(formHeight, geo.size.height) }
                .onChange(of: geo.size.height) { _, h in formHeight = max(formHeight, h) }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular, in: Rectangle())
                .overlay(Color.picardoBackground.opacity(0.22))
                .ignoresSafeArea()
        }
        .onAppear {
            if shipsFrom.isEmpty { shipsFrom = identity.studioCity }
            if location.isEmpty { location = identity.location }
            currency = SettingsStore.shared.flags.currency
            shipsWorldwide = identity.shipsWorldwide
        }
        .overlay {
            if showSuccess {
                ListingLiveView(
                    kind: mode == .post ? .post : .listing,
                    image: selectedImage,
                    title: mode == .post ? "" : title,
                    priceLabel: mode == .post ? nil : publishedPriceLabel,
                    caption: caption,
                    onViewStudio: onViewStudio,
                    onDone: { dismiss() }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSuccess)
        .sheet(isPresented: $showAuth) { AuthRequiredSheet() }
        .alert("Could not list artwork", isPresented: .init(
            get: { !submitError.isEmpty },
            set: { if !$0 { submitError = "" } }
        )) {
            Button("Try Again") { submitError = ""; submit() }
            Button("Not Now", role: .cancel) { submitError = "" }
        } message: {
            Text("\(submitError)\n\nYour photo and details are still here.")
        }
    }

    private var composeHeader: some View {
        HStack {
            Button("Cancel") { cancelTapped() }
                .font(.system(size: 16))
                .foregroundStyle(.primary)
                .confirmationDialog(
                    mode == .post ? "Discard this post?" : "Discard this listing?",
                    isPresented: $confirmDiscard,
                    titleVisibility: .visible
                ) {
                    Button("Discard", role: .destructive) { dismiss() }
                    Button("Keep Editing", role: .cancel) {}
                } message: {
                    Text(selectedImage != nil
                         ? "Your photo and details will be lost."
                         : "What you\u{2019}ve written will be lost.")
                }
            Spacer()
            Text(mode == .post ? "New Post" : "New Listing")
                .font(PicardoType.wordmark(18))
                .foregroundStyle(.primary)
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

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(SellComposeMode.allCases) { item in
                Button {
                    withAnimation(PicardoMotion.quick) { mode = item }
                } label: {
                    VStack(spacing: 5) {
                        Text(item.rawValue)
                            .font(.system(size: 14, weight: mode == item ? .semibold : .medium))
                            .foregroundStyle(mode == item ? Color.primary : Color.secondary)
                        Rectangle()
                            .fill(mode == item ? Color.picardoAccent : Color.clear)
                            .frame(width: 22, height: 1.5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .background(Color.picardoBackground.opacity(0.28), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        )
    }

    private var photoCard: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: mode == .post ? "camera.fill" : "photo")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(Color.picardoBackground.opacity(0.32), in: Circle())
                        Text(mode == .post ? "Add a photo" : "Photograph the work")
                            .font(PicardoType.title(16))
                            .foregroundStyle(.primary)
                        Text(mode == .post ? "From the studio" : "JPG · PNG · the piece as it hangs")
                            .font(PicardoType.meta(8))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if isAutofilling {
                    ZStack(alignment: .bottom) {
                        Color.black.opacity(0.22)
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .symbolEffect(.pulse)
                            Text(autofillStep)
                                .contentTransition(.opacity)
                                .id(autofillStep)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(.black.opacity(0.45), in: Capsule())
                        .padding(.bottom, 16)
                        .accessibilityElement(children: .combine)
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isAutofilling)
            .animation(.easeInOut(duration: 0.25), value: autofillStep)
            .overlay { goldCorners() }
            .background(Color.picardoBackground.opacity(0.28), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(.white.opacity(0.34), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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

    private var postFields: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                sellerPortrait
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                TextField("What’s happening in the studio?", text: $caption, axis: .vertical)
                    .font(PicardoType.body(16))
                    .foregroundStyle(.primary)
                    .tint(Color.picardoNeonRed)
                    .lineLimit(2...4)
            }

            compactField("Location", text: $location, hint: "Toronto, ON")
            compactField("Tags", text: $tags, hint: "studio, process, night")

            HStack {
                Text("Allow comments")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("", isOn: $allowComments)
                    .labelsHidden()
                    .tint(Color.picardoNeonRed)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.picardoBackground.opacity(0.30), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.34), lineWidth: 1)
        )
    }

    private var listingFields: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                sellerPortrait
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Title of the piece", text: $title)
                        .font(PicardoType.title(16))
                        .foregroundStyle(.primary)
                        .tint(Color.picardoNeonRed)
                    TextField("Description", text: $caption, axis: .vertical)
                        .font(PicardoType.body(13))
                        .foregroundStyle(.primary)
                        .tint(Color.picardoNeonRed)
                        .lineLimit(2...5)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.picardoNeonRed)
                TextField("0", text: $askPrice)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.primary)
                    .keyboardType(.decimalPad)
                    .tint(Color.picardoNeonRed)
                Spacer(minLength: 8)
                menuChip(currency, options: currencies) { currency = $0 }
            }

            if aiFilled {
                Label("Filled in by Picartdo AI. Tap anything to change it.", systemImage: "sparkles")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }

            moreDetailsToggle

            if showDetails {
                detailFields
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.picardoBackground.opacity(0.30), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.34), lineWidth: 1)
        )
    }

    /// Everything beyond photo, title and price waits behind one row, already
    /// filled in where we can, so listing takes three taps instead of fourteen.
    private var detailsSummary: String {
        var parts = [selectedCategory.rawValue]
        let m = medium.trimmingCharacters(in: .whitespaces)
        if !m.isEmpty { parts.append(m) }
        parts.append(condition)
        let from = shipsFrom.trimmingCharacters(in: .whitespaces)
        if !from.isEmpty { parts.append("Ships from \(from)") }
        return parts.joined(separator: " \u{00B7} ")
    }

    private var moreDetailsToggle: some View {
        Button {
            Haptics.select()
            withAnimation(PicardoMotion.quick) { showDetails.toggle() }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("More details")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(detailsSummary)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(showDetails ? 180 : 0))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.picardoBackground.opacity(0.24), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("More details")
        .accessibilityValue(detailsSummary)
        .accessibilityHint(showDetails ? "Hides category, size, edition and shipping" : "Shows category, size, edition and shipping")
    }

    private var detailFields: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                labeledMenu("Category", value: selectedCategory.rawValue) {
                    ForEach(ArtCategory.allCases) { item in
                        Button(item.rawValue) { selectedCategory = item }
                    }
                }
                compactField("Medium", text: $medium, hint: "Oil on canvas")
            }
            HStack(spacing: 8) {
                compactField("Size", text: $dimensions, hint: "24 × 36 in")
                compactField("Year", text: $year, hint: "2026")
            }
            HStack(spacing: 8) {
                labeledMenu("Condition", value: condition) {
                    ForEach(conditions, id: \.self) { item in
                        Button(item) { condition = item }
                    }
                }
                labeledMenu("Edition", value: edition) {
                    ForEach(editions, id: \.self) { item in
                        Button(item) { edition = item }
                    }
                }
            }

            HStack(spacing: 8) {
                stackedToggle("Signed", isOn: $isSigned)
                stackedToggle("Certificate", isOn: $hasCertificate)
                stackedToggle("Framed", isOn: $isFramed)
            }

            HStack(spacing: 8) {
                compactField("Ships from", text: $shipsFrom, hint: "Toronto")
                stackedToggle("Worldwide", isOn: $shipsWorldwide)
            }
        }
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
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(PicardoType.meta(8))
                .foregroundStyle(.secondary)
            TextField(hint, text: text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
                .tint(Color.picardoNeonRed)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.picardoBackground.opacity(0.24), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        )
    }

    private func labeledMenu<Content: View>(
        _ label: String,
        value: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(PicardoType.meta(8))
                .foregroundStyle(.secondary)
            Menu {
                content()
            } label: {
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.picardoBackground.opacity(0.24), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        )
    }

    private func menuChip(_ value: String, options: [String], onPick: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(options, id: \.self) { item in
                Button(item) { onPick(item) }
            }
        } label: {
            Text(value)
                .font(PicardoType.meta(9))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.picardoNeonRed, in: Capsule())
        }
    }

    private func stackedToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(PicardoType.meta(8))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.picardoNeonRed)
                .scaleEffect(0.84)
                .frame(height: 22)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.picardoBackground.opacity(0.24), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.28), lineWidth: 1)
        )
    }

    private var publishedPriceLabel: String? {
        guard let price = Double(askPrice) else { return nil }
        return price.formatted(.currency(code: currency).precision(.fractionLength(0)))
    }

    private var listingDescription: String {
        var lines: [String] = []
        let story = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        if !story.isEmpty { lines.append(story) }
        var specs: [String] = []
        if !year.isEmpty { specs.append("Year \(year)") }
        if !edition.isEmpty { specs.append(edition) }
        if !condition.isEmpty { specs.append(condition) }
        if isSigned { specs.append("Signed") }
        if hasCertificate { specs.append("Certificate") }
        if isFramed { specs.append("Framed") }
        if shipsWorldwide { specs.append("Ships worldwide") }
        if !shipsFrom.isEmpty { specs.append("From \(shipsFrom)") }
        if !specs.isEmpty { lines.append(specs.joined(separator: " · ")) }
        return lines.joined(separator: "\n\n")
    }

    private func submit() {
        guard isFormValid else { return }
        if mode == .post {
            showSuccess = true
            return
        }
        submitListing()
    }

    /// What the vision pass actually looks at, shown as it works. A result that
    /// visibly took a moment of thought reads as considered, not as a glitch.
    private static let autofillSteps = [
        "Looking at your piece\u{2026}",
        "Reading colour and subject\u{2026}",
        "Naming the medium\u{2026}",
        "Suggesting a price\u{2026}",
    ]

    private func runAutofill(from image: UIImage) {
        autofillGeneration += 1
        let generation = autofillGeneration
        aiFilled = false
        autofillStep = Self.autofillSteps[0]
        isAutofilling = true
        UIAccessibility.post(notification: .announcement, argument: "Picartdo AI is reading your piece")

        // Walk through the steps while the real request runs.
        Task {
            for step in Self.autofillSteps.dropFirst() {
                try? await Task.sleep(for: .milliseconds(650))
                guard generation == autofillGeneration, isAutofilling else { return }
                autofillStep = step
            }
        }

        Task {
            let started = ContinuousClock.now
            let draft = await Self.autofillDraft(for: image)
            // Let the steps finish so the result never pops in mid-sentence.
            let minimum = Duration.milliseconds(2400)
            let elapsed = ContinuousClock.now - started
            if elapsed < minimum { try? await Task.sleep(for: minimum - elapsed) }
            guard generation == autofillGeneration else { return }
            isAutofilling = false

            guard let draft else {
                PicartdoToast.show(
                    "Couldn\u{2019}t read this photo. Add the details yourself.",
                    icon: "text.cursor"
                )
                return
            }

            // Fill one field at a time, so the artist sees exactly what was suggested.
            let fills: [() -> Void] = [
                { title = draft.title },
                { caption = draft.caption },
                { selectedCategory = draft.category; medium = draft.medium; condition = draft.condition },
                { askPrice = "\(draft.askPrice)" },
            ]
            for fill in fills {
                guard generation == autofillGeneration else { return }
                withAnimation(.easeOut(duration: 0.25)) { fill() }
                try? await Task.sleep(for: .milliseconds(140))
            }
            withAnimation(.easeOut(duration: 0.25)) { aiFilled = true }
            Haptics.success()
        }
    }

    private static func autofillDraft(for image: UIImage) async -> ListingAutofillDraft? {
        #if DEBUG
        // `--demo-autofill`: a fixed suggestion, for testing the flow without an API key.
        if ProcessInfo.processInfo.arguments.contains("--demo-autofill") {
            try? await Task.sleep(for: .milliseconds(500))
            return ListingAutofillDraft(
                title: "Night Garden",
                caption: "Deep blue blooms over a dotted black ground, painted in layered acrylic.",
                category: .painting,
                medium: "Acrylic on canvas",
                condition: "Excellent",
                askPrice: 850
            )
        }
        #endif
        return await ListingAutofillService.suggest(from: image)
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
                    description: listingDescription,
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
            let len: CGFloat = 16
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
        .environment(SettingsStore.shared)
}
