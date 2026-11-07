import SwiftUI

/// The opening, "The Blank Canvas".
/// Every artist starts with a blank canvas; every collector with a blank wall.
/// First we ask which side of the canvas you stand on, then the walk-through
/// bends around the answer: collectors hang their wall, artists open their studio
/// and sign their name. The answers personalize Picartdo from the first scroll.
struct TasteOnboardingView: View {
    @Environment(TastePreferenceStore.self) private var tasteStore

    enum Step: Hashable { case canvas, mediums, goals, signature, budget, reveal }

    @State private var step: Step = .canvas
    @State private var forward = true
    @State private var role: PicartdoRole?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mediums: Set<ArtCategory> = []
    @State private var goals: Set<ArtistGoal> = []
    @State private var budget: CollectorBudget?
    @State private var artistName = ""
    @FocusState private var nameFocused: Bool

    private var path: [Step] {
        switch role {
        case .collector: [.canvas, .mediums, .budget, .reveal]
        case .artist:    [.canvas, .mediums, .goals, .signature, .reveal]
        case .both:      [.canvas, .mediums, .goals, .signature, .budget, .reveal]
        case nil:        [.canvas]
        }
    }

    private var stepIndex: Int { path.firstIndex(of: step) ?? 0 }

    var body: some View {
        ZStack {
            Color.picardoBackground.ignoresSafeArea()
            PaperGrain().opacity(0.045).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ZStack {
                    content
                        .id(step)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
                        ))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

                if step != .canvas {
                    primaryButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                }
            }
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .accessibilityLabel("Back")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.picardoText)
                    .frame(width: 40, height: 40)
            }
            .opacity(step == .canvas || step == .reveal ? 0 : 1)
            .disabled(step == .canvas || step == .reveal)

            Spacer()
            if role != nil {
                PaletteProgress(count: path.count, filled: stepIndex + 1)
                    .transition(.opacity)
            }
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .canvas:    canvasStep
        case .mediums:   mediumsStep
        case .goals:     goalsStep
        case .signature: signatureStep
        case .budget:    budgetStep
        case .reveal:    revealStep
        }
    }

    private var primaryButton: some View {
        Button(action: advance) {
            Text(step == .reveal ? "Enter Picartdo" : "Continue")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.picardoBackground)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.picardoText, in: Capsule())
        }
        .opacity(canContinue ? 1 : 0.3)
        .disabled(!canContinue)
        .animation(.easeOut(duration: 0.2), value: canContinue)
    }

    private var canContinue: Bool {
        switch step {
        case .canvas:    role != nil
        case .mediums:   !mediums.isEmpty
        case .goals:     !goals.isEmpty
        case .signature: !artistName.trimmingCharacters(in: .whitespaces).isEmpty
        case .budget:    budget != nil
        case .reveal:    true
        }
    }

    // MARK: - Steps

    /// Step 1 — three framed pieces on a wall. You pick yourself like you'd pick a painting.
    private var canvasStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                PicardoBrandWordmark(size: 18, tracking: 2)
                    .padding(.top, 4)

                Text("Every story starts\non a blank canvas.")
                    .font(PicardoType.display(30))
                    .foregroundStyle(Color.picardoText)
                    .multilineTextAlignment(.center)
                    .padding(.top, 22)

                Text("Which side of it do you stand on?")
                    .font(PicardoType.body(15))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .padding(.top, 10)

                VStack(spacing: 14) {
                    RoleFrame(
                        imageName: "night_cafe",
                        title: "The Collector",
                        plaque: "Curiosity on a blank wall · 2026",
                        line: "I'm here to discover art and live with it.",
                        tilt: -1.6,
                        isSelected: role == .collector
                    ) { choose(.collector) }

                    RoleFrame(
                        imageName: "studio_stretch",
                        title: "The Artist",
                        plaque: "Pigment, hands, late nights · 2026",
                        line: "I'm here to create, show and sell my work.",
                        tilt: 1.2,
                        isSelected: role == .artist
                    ) { choose(.artist) }

                    RoleFrame(
                        imageName: "circle_worlds",
                        title: "Both Sides",
                        plaque: "Studio by day, gallery by night · 2026",
                        line: "I make art, and I collect it too.",
                        tilt: -0.8,
                        isSelected: role == .both
                    ) { choose(.both) }
                }
                .padding(.top, 28)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }

    private var mediumsStep: some View {
        let isMaker = role?.makesArt == true
        return StepScaffold(
            title: isMaker ? "What's on your easel?" : "Which rooms do you\nwander into first?",
            subtitle: isMaker
                ? "Pick everything you work in. It shapes your studio."
                : "Pick the mediums you could stand in front of for hours."
        ) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(ArtCategory.allCases) { category in
                    MediumTile(category: category, isSelected: mediums.contains(category)) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if mediums.contains(category) { mediums.remove(category) } else { mediums.insert(category) }
                        }
                    }
                }
            }
        }
    }

    private var goalsStep: some View {
        StepScaffold(
            title: "What should Picartdo\ndo for your art?",
            subtitle: "Pick as many as you like. We'll open the right doors."
        ) {
            VStack(spacing: 10) {
                ForEach(ArtistGoal.allCases) { goal in
                    ChoiceRow(
                        icon: goal.icon,
                        title: goal.title,
                        detail: goal.detail,
                        isSelected: goals.contains(goal)
                    ) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            if goals.contains(goal) { goals.remove(goal) } else { goals.insert(goal) }
                        }
                    }
                }
            }
        }
    }

    /// The artist signs their canvas. Their name is written on in script as they type.
    private var signatureStep: some View {
        StepScaffold(
            title: "Sign your work.",
            subtitle: "This is the name collectors will know you by."
        ) {
            VStack(spacing: 22) {
                SignedCanvas(name: artistName, imageName: heroImage(for: orderedMediums.first) ?? "studio_frame")
                    .onTapGesture { nameFocused = true }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ARTIST NAME")
                        .font(.system(size: 10.5, weight: .semibold))
                        .kerning(1.6)
                        .foregroundStyle(Color.picardoTextSecondary)
                    TextField("How you sign your pieces", text: $artistName)
                        .font(PicardoType.title(20))
                        .foregroundStyle(Color.picardoText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($nameFocused)
                        .onSubmit { if canContinue { advance() } }
                    Rectangle()
                        .fill(Color.picardoText.opacity(nameFocused ? 0.9 : 0.25))
                        .frame(height: 1)
                }
            }
        }
    }

    private var budgetStep: some View {
        StepScaffold(
            title: role == .both ? "And when you collect,\nyour first piece is…" : "Your first piece.",
            subtitle: "No pressure. It just helps us show you the right walls."
        ) {
            VStack(spacing: 10) {
                ForEach(CollectorBudget.allCases) { option in
                    ChoiceRow(
                        icon: option == .browsing ? "figure.walk" : "tag",
                        title: option.price,
                        detail: option.detail,
                        isSelected: budget == option
                    ) {
                        Haptics.select()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { budget = option }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var revealStep: some View {
        if role?.makesArt == true {
            StudioReveal(
                name: artistName,
                imageName: heroImage(for: orderedMediums.first) ?? "studio_frame",
                mediums: orderedMediums,
                goals: ArtistGoal.allCases.filter(goals.contains),
                alsoCollects: role == .both
            )
        } else {
            WallReveal(imageNames: wallImages, mediums: orderedMediums)
        }
    }

    // MARK: - Flow

    private var orderedMediums: [ArtCategory] { ArtCategory.allCases.filter(mediums.contains) }

    private var wallImages: [String] {
        // Hang real pieces from the rooms they chose, most-loved first; only pad with other work if a room is thin.
        let loved = Artwork.samples.sorted { $0.likeCount > $1.likeCount }
        var names = loved.filter { mediums.contains($0.category) }.map(\.imageName)
        for name in loved.map(\.imageName) where names.count < 3 && !names.contains(name) {
            names.append(name)
        }
        return Array(names.prefix(3))
    }

    private func heroImage(for category: ArtCategory?) -> String? {
        guard let category else { return nil }
        return MediumTile.imageName(for: category)
    }

    private func choose(_ chosen: PicartdoRole) {
        Haptics.select()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) { role = chosen }
        Task {
            try? await Task.sleep(for: .milliseconds(420))
            guard role == chosen, step == .canvas else { return }
            advance()
        }
    }

    private func advance() {
        guard canContinue else { return }
        if step == .reveal {
            finish()
            return
        }
        guard stepIndex + 1 < path.count else { return }
        let next = path[stepIndex + 1]
        nameFocused = false
        forward = true
        if next == .reveal { Haptics.success() }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
            step = next
        }
        if next == .signature && artistName.isEmpty {
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                nameFocused = true
            }
        }
    }

    private func goBack() {
        guard stepIndex > 0 else { return }
        nameFocused = false
        forward = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
            step = path[stepIndex - 1]
        }
    }

    private func finish() {
        guard let role else { return }
        Haptics.soft()
        withAnimation(.easeInOut(duration: 0.45)) {
            tasteStore.completeOnboarding(
                role: role,
                mediums: mediums,
                goals: goals,
                budget: budget,
                artistName: artistName
            )
        }
    }
}

// MARK: - Scaffold

private struct StepScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(PicardoType.display(28))
                    .foregroundStyle(Color.picardoText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(PicardoType.body(15))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                content
                    .padding(.top, 24)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Palette progress

/// Progress as paint on a palette: each step you finish adds a dab of pigment.
private struct PaletteProgress: View {
    let count: Int
    let filled: Int

    private static let pigments: [Color] = [
        .picardoNeonRed,
        Color(red: 0.949, green: 0.702, blue: 0.239),
        Color(red: 0.231, green: 0.447, blue: 0.718),
        .picardoSupport,
        Color(red: 0.55, green: 0.33, blue: 0.62),
        Color(red: 0.11, green: 0.11, blue: 0.11),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                let color = Self.pigments[index % Self.pigments.count]
                let current = index == filled - 1
                Circle()
                    .fill(index < filled ? color : Color.clear)
                    .overlay(Circle().stroke(index < filled ? color : Color.picardoText.opacity(0.2), lineWidth: 1.2))
                    .frame(width: current ? 12 : 8, height: current ? 12 : 8)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: filled)
        .accessibilityElement()
        .accessibilityLabel("Step \(filled) of \(count)")
    }
}

// MARK: - Role frame

/// A framed piece with a museum plaque beside it. Straightens when chosen.
private struct RoleFrame: View {
    let imageName: String
    let title: String
    let plaque: String
    let line: String
    let tilt: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                ArtworkImage(imageName: imageName, contentMode: .fill, maxDimension: 400)
                    .scaleEffect(1.32) // crop the wall the piece was photographed on
                    .allowsHitTesting(false)
                    .frame(width: 84, height: 104)
                    .clipped()
                    .padding(6)
                    .background(Color.picardoPolaroidMat)
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 4))
                    .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 6)
                    .rotationEffect(.degrees(isSelected ? 0 : tilt))

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(PicardoType.title(21))
                        .foregroundStyle(Color.picardoText)
                    Text(plaque)
                        .font(.system(size: 11, design: .serif).italic())
                        .foregroundStyle(Color.picardoTextSecondary)
                    Text(line)
                        .font(PicardoType.body(13.5))
                        .foregroundStyle(Color.picardoText.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.picardoText : Color.picardoBorder, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Medium tile

private struct MediumTile: View {
    let category: ArtCategory
    let isSelected: Bool
    let action: () -> Void

    static func imageName(for category: ArtCategory) -> String {
        switch category {
        case .painting:    "red_dress_portrait"
        case .photography: "carnival_circle"
        case .sculpture:   "tagged_david"
        case .digital:     "zebra_crossing"
        case .drawing:     "night_watch"
        case .printmaking: "queen_of_clubs"
        case .mixedMedia:  "people_collage"
        }
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                Color.clear
                    .overlay {
                        ArtworkImage(imageName: Self.imageName(for: category), contentMode: .fill, maxDimension: 500)
                            .scaleEffect(1.5) // crop the wall the piece was photographed on
                            .allowsHitTesting(false)
                    }
                    .clipped()

                LinearGradient(colors: [.clear, .black.opacity(0.65)], startPoint: .center, endPoint: .bottom)

                HStack(spacing: 6) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 12, weight: .semibold))
                    Text(category.rawValue)
                        .font(PicardoType.title(16))
                }
                .foregroundStyle(.white)
                .padding(12)
            }
            .frame(height: 132)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.9))
                    .background(Circle().fill(isSelected ? Color.white : Color.black.opacity(0.15)).padding(2))
                    .padding(10)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.picardoText, lineWidth: isSelected ? 3 : 0)
            )
            .scaleEffect(isSelected ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Choice row

private struct ChoiceRow: View {
    let icon: String
    let title: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isSelected ? Color.picardoBackground : Color.picardoText)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(isSelected ? Color.picardoText : Color.picardoText.opacity(0.06)))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(PicardoType.title(17))
                        .foregroundStyle(Color.picardoText)
                    Text(detail)
                        .font(PicardoType.body(13))
                        .foregroundStyle(Color.picardoTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Color.picardoText : Color.picardoText.opacity(0.2))
            }
            .padding(14)
            .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.picardoText : Color.picardoBorder, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Signed canvas

/// A framed canvas with the artist's signature written into the corner as they type.
private struct SignedCanvas: View {
    let name: String
    let imageName: String

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .overlay {
                    ArtworkImage(imageName: imageName, contentMode: .fill, maxDimension: 700)
                        .scaleEffect(1.45) // crop the wall the piece was photographed on
                        .allowsHitTesting(false)
                }
                .clipped()

            Text(trimmed.isEmpty ? "your name" : trimmed)
                .font(.custom("SnellRoundhand-Bold", size: 34))
                .foregroundStyle(trimmed.isEmpty ? Color.black.opacity(0.3) : Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 14)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.85), in: Capsule())
                .padding(14)
                .animation(.easeOut(duration: 0.2), value: trimmed)
        }
        .frame(height: 230)
        .padding(8)
        .background(Color.picardoPolaroidMat)
        .overlay(Rectangle().stroke(Color.black, lineWidth: 5))
        .shadow(color: .black.opacity(0.2), radius: 14, y: 10)
        .rotationEffect(.degrees(-0.8))
        .accessibilityElement()
        .accessibilityLabel(trimmed.isEmpty ? "Unsigned canvas" : "Canvas signed \(trimmed)")
    }
}

// MARK: - Reveals

/// Collector payoff: their wall, hung with the mediums they chose.
private struct WallReveal: View {
    let imageNames: [String]
    let mediums: [ArtCategory]
    @State private var hung = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            Text("Your wall is ready.")
                .font(PicardoType.display(30))
                .foregroundStyle(Color.picardoText)
            Text("Picartdo now opens on the work you're drawn to.")
                .font(PicardoType.body(15))
                .foregroundStyle(Color.picardoTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            HStack(alignment: .center, spacing: 14) {
                ForEach(Array(imageNames.enumerated()), id: \.offset) { index, name in
                    let big = index == 1
                    ArtworkImage(imageName: name, contentMode: .fill, maxDimension: 500)
                        .scaleEffect(1.32) // crop the wall the piece was photographed on
                        .allowsHitTesting(false)
                        .frame(width: big ? 120 : 86, height: big ? 156 : 112)
                        .clipped()
                        .padding(big ? 8 : 6)
                        .background(Color.picardoPolaroidMat)
                        .overlay(Rectangle().stroke(Color.black, lineWidth: big ? 5 : 4))
                        .shadow(color: .black.opacity(0.22), radius: 10, y: 8)
                        .offset(y: hung ? 0 : -40)
                        .opacity(hung ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.12 * Double(index)), value: hung)
                }
            }
            .padding(.top, 44)

            MuseumPlaque(
                title: "The Collection of You",
                line: "est. 2026",
                detail: mediums.map(\.rawValue).joined(separator: " · ")
            )
            .padding(.top, 36)
            .opacity(hung ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: hung)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
        .onAppear { hung = true }
    }
}

/// Artist payoff: their signed canvas and a plaque for the studio.
private struct StudioReveal: View {
    let name: String
    let imageName: String
    let mediums: [ArtCategory]
    let goals: [ArtistGoal]
    let alsoCollects: Bool
    @State private var opened = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Text("Your studio is open.")
                    .font(PicardoType.display(30))
                    .foregroundStyle(Color.picardoText)
                    .padding(.top, 8)
                Text(alsoCollects
                     ? "Make it, show it, sell it, and collect from the artists you love."
                     : "Make it, show it, sell it. Collectors are already looking.")
                    .font(PicardoType.body(15))
                    .foregroundStyle(Color.picardoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 16)

                SignedCanvas(name: name, imageName: imageName)
                    .padding(.top, 28)
                    .scaleEffect(opened ? 1 : 0.92)
                    .opacity(opened ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: opened)

                MuseumPlaque(
                    title: "Studio of \(name.trimmingCharacters(in: .whitespaces))",
                    line: "est. 2026",
                    detail: mediums.map(\.rawValue).joined(separator: " · ")
                )
                .padding(.top, 28)

                FlowTags(tags: goals.map(\.title))
                    .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear { opened = true }
    }
}

private struct MuseumPlaque: View {
    let title: String
    let line: String
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(PicardoType.title(17))
                .foregroundStyle(Color.picardoText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(line)
                .font(.system(size: 11, design: .serif).italic())
                .foregroundStyle(Color.picardoTextSecondary)
            if !detail.isEmpty {
                Text(detail.uppercased())
                    .font(.system(size: 9.5, weight: .semibold))
                    .kerning(1.4)
                    .foregroundStyle(Color.picardoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(Color.picardoCard, in: RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.picardoBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

private struct FlowTags: View {
    let tags: [String]

    var body: some View {
        // Five tags at most, so rows of two wrap well enough.
        VStack(spacing: 8) {
            ForEach(Array(stride(from: 0, to: tags.count, by: 2)), id: \.self) { start in
                HStack(spacing: 8) {
                    ForEach(tags[start..<min(start + 2, tags.count)], id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color.picardoText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.picardoText.opacity(0.06)))
                            .overlay(Capsule().stroke(Color.picardoBorder, lineWidth: 1))
                    }
                }
            }
        }
    }
}

#Preview {
    TasteOnboardingView()
        .environment(TastePreferenceStore())
}
