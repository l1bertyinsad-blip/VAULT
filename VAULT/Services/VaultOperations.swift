import Foundation
import SwiftData

@MainActor
enum VaultOperations {
    static func createFolder(
        name: String,
        colorIdentifier: String,
        symbolName: String,
        sortOrder: Int,
        template: VaultFolderTemplate = .general,
        in context: ModelContext
    ) -> VaultFolder? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let folder = VaultFolder(
            name: trimmed,
            colorIdentifier: colorIdentifier,
            symbolName: symbolName,
            sortOrder: sortOrder,
            template: template
        )
        context.insert(folder)
        try? context.save()
        return folder
    }

    static func update(
        _ folder: VaultFolder,
        name: String,
        colorIdentifier: String,
        symbolName: String,
        template: VaultFolderTemplate? = nil,
        in context: ModelContext
    ) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        folder.name = trimmed
        folder.colorIdentifier = colorIdentifier
        folder.symbolName = symbolName
        if let template { folder.template = template }
        try? context.save()
        return true
    }

    static func delete(
        _ item: VaultMediaItem,
        in context: ModelContext,
        storage: LocalFileService = .shared
    ) {
        storage.delete(media: item)
        context.delete(item)
        try? context.save()
    }

    static func delete(
        _ folder: VaultFolder,
        in context: ModelContext,
        storage: LocalFileService = .shared
    ) {
        folder.items.forEach { storage.delete(media: $0) }
        context.delete(folder)
        try? context.save()
    }

    static func move(_ items: [VaultMediaItem], to folder: VaultFolder, in context: ModelContext) {
        let baseOrder = (folder.items.map(\.sortOrder).max() ?? -1) + 1
        for (offset, item) in items.enumerated() {
            item.folder = folder
            item.sortOrder = baseOrder + offset
        }
        try? context.save()
    }

    static func reorder(_ items: [VaultMediaItem], in context: ModelContext) {
        for (index, item) in items.enumerated() {
            item.sortOrder = index
        }
        try? context.save()
    }
}
