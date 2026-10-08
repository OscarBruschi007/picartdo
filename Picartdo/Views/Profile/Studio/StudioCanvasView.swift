import SwiftUI

struct StudioCanvasView: View {
    @Bindable var store: StudioCanvasStore
    var zoom: Namespace.ID
    var onBack: (() -> Void)?
    var onKnock: () -> Void
    var onOpenArtwork: (Artwork) -> Void
    var reduceMotion: Bool

    @State private var canvasWidth: CGFloat = 390
    @State private var showEntrance = true
    @State private var shareImage: UIImage?
    @State private var showShare = false

    private var accent: Color { store.layout.accent.color }

    var body: some View {
        ZStack(alignment: .bottom) {
            store.layout.material.fill.ignoresSafeArea()
            if store.layout.material == .grid {
                StudioGridPaper().ignoresSafeArea().opacity(0.35)
            }

            VStack(spacing: 0) {
                chrome
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        title
                        canvas
                        footnotes
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, store.isEditing && store.isOwner ? 88 : 28)
                }
            }

            if store.isEditing && store.isOwner {
                editBar
            }

            if showEntrance && !reduceMotion && !store.entrancePlayed {
                StudioEntranceOverlay(kind: store.layout.entrance) {
                    store.entrancePlayed = true
                    showEntrance = false
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $store.showLibrary) { library }
        .sheet(isPresented: $store.showTheme) { themeSheet }
        .sheet(isPresented: $store.showStyle) { styleSheet }
        .sheet(isPresented: $showShare) {
            if let shareImage {
                StudioActivitySheet(items: [shareImage])
            }
        }
        .onAppear {
            if reduceMotion || store.entrancePlayed {
                showEntrance = false
                store.entrancePlayed = true
            }
        }
        .onChange(of: store.layout) { _, _ in
            store.schedulePersist()
        }
    }

    private var chrome: some View {
        HStack(spacing: 10) {
            Button { onBack?() } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.picardoStudioInk)
                    .overlay(Rectangle().strokeBorder(Color.picardoStudioHairline, lineWidth: 1))
            }
            .accessibilityLabel("Back")

            Spacer()

            Button("SHARE") {
                shareImage = StudioShareCard.render(store.layout)
                showShare = shareImage != nil
            }
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(Color.picardoStudioInk)
            .frame(minHeight: 44)

            if store.isOwner {
                Button(store.isEditing ? "DONE" : "EDIT") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(PicardoMotion.transition) {
                        store.isEditing.toggle()
                        if !store.isEditing { store.selectedBlockID = nil }
                    }
                }
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.picardoStudioInk)
                .frame(minHeight: 44)
            }

            if !store.isEditing {
                Button {
                    store.previewAsVisitor.toggle()
                } label: {
                    Text("PREVIEW")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.picardoStudioInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .overlay(
                            Rectangle().strokeBorder(
                                Color.picardoStudioInk,
                                lineWidth: store.previewAsVisitor ? 1 : 0
                            )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Preview as visitor")
                .accessibilityAddTraits(store.previewAsVisitor ? .isSelected : [])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.white)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.picardoStudioHairline).frame(height: 1) }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(store.layout.artistName)
                .font(.system(.largeTitle, design: .serif).weight(.black))
                .foregroundStyle(Color.picardoStudioInk)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            Text(store.layout.tagline.uppercased())
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .kerning(1.4)
                .foregroundStyle(Color.picardoStudioMute)
        }
        .padding(.top, 12)
        .accessibilityAddTraits(.isHeader)
    }

    private var canvas: some View {
        StudioGridLayout {
            ForEach($store.layout.blocks) { $block in
                StudioEditableFrame(
                    block: $block,
                    isEditing: store.isEditing && store.isOwner,
                    selected: store.selectedBlockID == block.id,
                    accent: accent,
                    canvasWidth: canvasWidth,
                    reduceMotion: reduceMotion,
                    onMoveStart: { store.pushUndo() },
                    onRemove: { store.remove(block.id) }
                ) {
                    StudioBlockView(
                        block: $block,
                        accent: accent,
                        isOwner: store.isOwner && !store.isEditing,
                        reduceMotion: reduceMotion,
                        zoom: zoom,
                        onOpenImage: { name in
                            if let art = Artwork.samples.first(where: { $0.imageName == name }) {
                                onOpenArtwork(art)
                            }
                        },
                        onKnock: onKnock
                    )
                }
                .layoutValue(key: StudioFrameKey.self, value: block.frame)
                .onTapGesture {
                    guard store.isEditing && store.isOwner else { return }
                    if store.selectedBlockID == block.id {
                        store.showStyle = true
                    } else {
                        store.selectedBlockID = block.id
                    }
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: StudioCanvasWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(StudioCanvasWidthKey.self) { canvasWidth = $0 }
        .onLongPressGesture {
            guard store.isOwner else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(PicardoMotion.transition) { store.isEditing = true }
        }
    }

    private var footnotes: some View {
        Text("WORKS \(Artwork.samples.count)  ·  EST. 2024  ·  \(store.layout.template.label)")
            .font(.system(.caption2, design: .monospaced).weight(.semibold))
            .foregroundStyle(Color.picardoStudioMute)
            .padding(.top, 8)
            .accessibilityLabel("Spec sheet. \(Artwork.samples.count) works. Established 2024. Template \(store.layout.template.label).")
    }

    private var editBar: some View {
        HStack(spacing: 14) {
            Button("UNDO", action: store.undo).disabled(!store.canUndo)
            Button("REDO", action: store.redo).disabled(!store.canRedo)
            Button("+") { store.showLibrary = true }
                .accessibilityLabel("Add block")
            Button("THEME") { store.showTheme = true }
            Button("STYLE") { store.showStyle = true }
                .disabled(store.selectedBlockID == nil)
            Button("REMOVE", action: store.removeSelected)
                .disabled(store.selectedBlockID == nil)
        }
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .foregroundStyle(Color.picardoStudioInk)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .overlay(alignment: .top) { Rectangle().fill(Color.picardoStudioHairline).frame(height: 1) }
    }

    private var library: some View {
        NavigationStack {
            List(StudioBlockKind.allCases) { kind in
                Button(kind.libraryLabel) {
                    store.addBlock(kind)
                    store.showLibrary = false
                }
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.picardoStudioInk)
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationTitle("Blocks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { store.showLibrary = false } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var themeSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    StudioQuoted(text: "TEMPLATE")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(StudioTemplate.allCases) { item in
                            Button(item.label) { store.applyTemplate(item) }
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(store.layout.template == item ? Color.white : Color.picardoStudioInk)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(store.layout.template == item ? accent : Color.white)
                                .overlay(Rectangle().strokeBorder(Color.picardoStudioInk, lineWidth: 1))
                        }
                    }
                    StudioQuoted(text: "ACCENT")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(StudioAccent.allCases) { item in
                            Button {
                                store.pushUndo()
                                store.layout.accent = item
                                store.persist()
                            } label: {
                                Circle().fill(item.color).frame(width: 28, height: 28)
                                    .overlay(Circle().strokeBorder(Color.picardoStudioInk, lineWidth: store.layout.accent == item ? 2 : 0.5))
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel(item.label)
                        }
                    }
                    StudioQuoted(text: "MATERIAL")
                    HStack {
                        ForEach(StudioMaterial.allCases) { item in
                            Button(item.rawValue.uppercased()) {
                                store.pushUndo()
                                store.layout.material = item
                                store.persist()
                            }
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.picardoStudioInk)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 8)
                            .overlay(Rectangle().strokeBorder(store.layout.material == item ? Color.picardoStudioInk : Color.picardoStudioHairline, lineWidth: 1))
                        }
                    }
                    StudioQuoted(text: "ENTRANCE")
                    HStack {
                        ForEach(StudioEntrance.allCases) { item in
                            Button(item.rawValue.uppercased()) {
                                store.pushUndo()
                                store.layout.entrance = item
                                store.persist()
                            }
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .frame(minHeight: 44)
                            .padding(.horizontal, 8)
                            .overlay(Rectangle().strokeBorder(store.layout.entrance == item ? Color.picardoStudioInk : Color.picardoStudioHairline, lineWidth: 1))
                        }
                    }
                    Button("DUPLICATE AS TEMPLATE", action: store.duplicateAsTemplate)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .frame(minHeight: 44)
                }
                .padding(20)
            }
            .background(Color.white)
            .navigationTitle("Studio")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { store.showTheme = false } } }
        }
        .presentationDetents([.large])
    }

    private var styleSheet: some View {
        NavigationStack {
            Group {
                if let id = store.selectedBlockID,
                   let index = store.layout.blocks.firstIndex(where: { $0.id == id }) {
                    Form {
                        Picker("Paper", selection: $store.layout.blocks[index].style.paper) {
                            ForEach(StudioPaper.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Border", selection: $store.layout.blocks[index].style.border) {
                            ForEach(StudioBorder.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Corner", selection: $store.layout.blocks[index].style.corner) {
                            ForEach(StudioCorner.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Shadow", selection: $store.layout.blocks[index].style.shadow) {
                            ForEach(StudioShadow.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Type", selection: $store.layout.blocks[index].style.typePair) {
                            ForEach(StudioTypePair.allCases) { Text($0.rawValue).tag($0) }
                        }
                    }
                } else {
                    Text("Tap a block in edit mode.")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(Color.picardoStudioMute)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Style")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { store.showStyle = false } } }
        }
        .presentationDetents([.medium])
    }
}

private struct StudioCanvasWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 390
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct StudioGridPaper: View {
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 16
            var path = Path()
            var x: CGFloat = 0
            while x < size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y < size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            ctx.stroke(path, with: .color(Color.picardoStudioHairline), lineWidth: 0.5)
        }
    }
}

struct StudioEntranceOverlay: View {
    let kind: StudioEntrance
    var onDone: () -> Void
    @State private var open = false

    var body: some View {
        ZStack {
            switch kind {
            case .curtain:
                HStack(spacing: 0) {
                    Color.picardoStudioInk.offset(x: open ? -240 : 0)
                    Color.picardoStudioInk.offset(x: open ? 240 : 0)
                }
            case .spotlight:
                Color.black.opacity(open ? 0 : 0.72)
            case .door:
                Color.picardoStudioInk.offset(x: open ? 420 : 0)
            case .ink:
                Color.picardoStudioInk.opacity(open ? 0 : 1)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9)) { open = true }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_050_000_000)
                onDone()
            }
        }
        .onTapGesture { onDone() }
        .accessibilityLabel("Skip entrance")
        .accessibilityAddTraits(.isButton)
    }
}
