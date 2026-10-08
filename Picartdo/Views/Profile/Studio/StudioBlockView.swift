import SwiftUI

struct StudioBlockView: View {
    @Binding var block: StudioPlacedBlock
    let accent: Color
    var isOwner: Bool
    var reduceMotion: Bool
    var zoom: Namespace.ID
    var onOpenImage: (String) -> Void
    var onKnock: () -> Void

    var body: some View {
        switch block.kind {
        case .hero:
            HeroPieceBlock(block: $block, accent: accent, isOwner: isOwner, zoom: zoom, onInspect: onOpenImage, onOpen: onOpenImage)
        case .statement:
            ArtistStatementBlock(block: $block, accent: accent, isOwner: isOwner, reduceMotion: reduceMotion)
        case .nowWorking:
            NowWorkingOnBlock(block: $block, accent: accent)
        case .processReel:
            ProcessReelBlock(block: $block, accent: accent, zoom: zoom, onOpen: onOpenImage)
        case .contactSheet:
            ContactSheetBlock(block: $block, accent: accent, zoom: zoom, onOpen: onOpenImage)
        case .shelf:
            ShelfBlock(block: $block, accent: accent, zoom: zoom, onOpen: onOpenImage)
        case .commissions:
            CommissionsCounterBlock(block: $block, accent: accent, isOwner: isOwner, onKnock: onKnock)
        case .guestbook:
            GuestbookWallBlock(block: $block, accent: accent, isOwner: isOwner)
        case .timeline:
            TimelineBlock(block: $block, accent: accent)
        case .moodboard:
            MoodboardBlock(block: $block, accent: accent, isOwner: isOwner)
        case .ledger:
            SoldLedgerBlock(block: $block, accent: accent)
        case .signature:
            SignatureBlock(block: $block, accent: accent, isOwner: isOwner)
        }
    }
}

struct StudioEditableFrame<Content: View>: View {
    @Binding var block: StudioPlacedBlock
    var isEditing: Bool
    var selected: Bool
    var accent: Color
    var canvasWidth: CGFloat
    var reduceMotion: Bool
    var onMoveStart: () -> Void
    var onRemove: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var dragStart: StudioRect?
    @Environment(\.accessibilityReduceMotion) private var envReduce

    private var skipMotion: Bool { reduceMotion || envReduce }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content()
                .allowsHitTesting(!isEditing)

            if isEditing && selected {
                Circle()
                    .fill(accent)
                    .frame(width: 18, height: 18)
                    .padding(13)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if dragStart == nil {
                                    onMoveStart()
                                    dragStart = block.frame
                                }
                                if let start = dragStart {
                                    block.frame = StudioGridLayout.resize(
                                        translation: value.translation,
                                        start: start,
                                        width: canvasWidth
                                    )
                                }
                            }
                            .onEnded { _ in dragStart = nil }
                    )
                    .accessibilityLabel("Resize block")
            }
        }
        .scaleEffect(isEditing ? 0.985 : 1)
        .phaseAnimator([false, true], trigger: isEditing) { view, on in
            view.rotationEffect(.degrees(isEditing && !skipMotion && !selected ? (on ? 0.7 : -0.7) : 0))
        } animation: { _ in
            skipMotion ? .linear(duration: 0) : .easeInOut(duration: 0.14)
        }
        .gesture(isEditing ? moveOrSwipe : nil)
        .animation(PicardoMotion.transition, value: isEditing)
        .animation(PicardoMotion.quick, value: selected)
    }

    private var moveOrSwipe: some Gesture {
        DragGesture()
            .onChanged { value in
                if abs(value.translation.width) > 80, abs(value.translation.height) < 36 {
                    return
                }
                if dragStart == nil {
                    onMoveStart()
                    dragStart = block.frame
                }
                if let start = dragStart {
                    block.frame = StudioGridLayout.snap(
                        translation: value.translation,
                        start: start,
                        width: canvasWidth
                    )
                }
            }
            .onEnded { value in
                if value.translation.width < -80, abs(value.translation.height) < 40 {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    onRemove()
                }
                dragStart = nil
            }
    }
}
