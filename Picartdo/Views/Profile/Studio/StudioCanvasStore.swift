import Foundation
import SwiftUI

@MainActor
@Observable
final class StudioCanvasStore {
    var layout: StudioLayout
    var isEditing = false
    var previewAsVisitor = false
    var selectedBlockID: UUID?
    var showLibrary = false
    var showTheme = false
    var showStyle = false
    var entrancePlayed = false
    var lastError: String = ""

    private var undoStack: [StudioLayout] = []
    private var redoStack: [StudioLayout] = []
    private let url: URL
    private var persistTask: Task<Void, Never>?
    private var suppressPersist = false

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var isOwner: Bool { !previewAsVisitor }

    init(filename: String = "studio-layout.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        url = docs.appendingPathComponent(filename)
        if let data = try? Data(contentsOf: url),
           let saved = try? JSONDecoder().decode(StudioLayout.self, from: data) {
            layout = saved
        } else {
            layout = StudioTemplates.make(
                .galleryWall,
                name: ArtistMarketplaceProfile.oscar.name,
                tagline: "Oil Painter · Miami, FL"
            )
        }
        applyLaunchArguments()
    }

    private func applyLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains(where: { $0.hasPrefix("--studio-") }) {
            suppressPersist = true
        }
        if let i = args.firstIndex(of: "--studio-template"), i + 1 < args.count,
           let template = StudioTemplate(rawValue: args[i + 1]) {
            layout = StudioTemplates.make(template, name: layout.artistName, tagline: layout.tagline)
        }
        if args.contains("--studio-edit") { isEditing = true }
        if args.contains("--studio-visitor") { previewAsVisitor = true }
        if args.contains("--studio-skip-entrance") { entrancePlayed = true }
        if args.contains("--studio-style") {
            isEditing = true
            selectedBlockID = layout.blocks.first?.id
            showStyle = true
        }
        if args.contains("--studio-mid-drag"), !layout.blocks.isEmpty {
            isEditing = true
            selectedBlockID = layout.blocks[0].id
            layout.blocks[0].frame.col = min(4, max(1, layout.blocks[0].frame.col + 2))
            layout.blocks[0].frame.row = min(layout.blocks[0].frame.row + 1, 6)
        }
    }

    func persist() {
        guard !suppressPersist else { return }
        do {
            let data = try JSONEncoder().encode(layout)
            try data.write(to: url, options: [.atomic])
        } catch {
            lastError = error.localizedDescription
        }
    }

    func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            persist()
        }
    }

    func pushUndo() {
        undoStack.append(layout)
        if undoStack.count > 30 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(layout)
        layout = previous
        persist()
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(layout)
        layout = next
        persist()
    }

    func applyTemplate(_ template: StudioTemplate) {
        pushUndo()
        layout = StudioTemplates.make(template, name: layout.artistName, tagline: layout.tagline)
        selectedBlockID = nil
        persist()
    }

    func addBlock(_ kind: StudioBlockKind) {
        pushUndo()
        let span = kind.defaultSpan
        let row = layout.blocks.map(\.frame.maxRow).max() ?? 0
        var block = StudioTemplates.seed(kind)
        block.frame = StudioRect(col: 0, row: row, colSpan: span.cols, rowSpan: span.rows)
        layout.blocks.append(block)
        selectedBlockID = block.id
        persist()
    }

    func removeSelected() {
        guard let id = selectedBlockID else { return }
        remove(id)
    }

    func remove(_ id: UUID) {
        pushUndo()
        layout.blocks.removeAll { $0.id == id }
        if selectedBlockID == id { selectedBlockID = nil }
        persist()
    }

    func duplicateAsTemplate() {
        let copyURL = url.deletingLastPathComponent()
            .appendingPathComponent("studio-template-\(layout.template.rawValue).json")
        try? JSONEncoder().encode(layout).write(to: copyURL, options: [.atomic])
    }
}
