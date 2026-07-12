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

@MainActor
enum InboxSuggestionService {
    static func suggestion(for item: VaultMediaItem, folders: [VaultFolder]) -> VaultFolder? {
        let candidates = folders.filter { !$0.isSystem && $0.id != item.folder?.id }
        guard !candidates.isEmpty else { return nil }
        let text = item.searchableText

        let ranked = candidates.map { folder in
            (folder: folder, score: score(folder: folder, text: text))
        }.sorted {
            if $0.score != $1.score { return $0.score > $1.score }
            return $0.folder.sortOrder < $1.folder.sortOrder
        }

        if let best = ranked.first, best.score > 0 { return best.folder }
        return nil
    }

    private static func score(folder: VaultFolder, text: String) -> Int {
        var result = 0
        let folderName = folder.name.lowercased()
        if !folderName.isEmpty && text.contains(folderName) { result += 8 }

        let keywords: [String]
        switch folder.template {
        case .purchases: keywords = ["купить", "цена", "магазин", "product", "shop", "ozon", "wildberries"]
        case .films: keywords = ["фильм", "сериал", "кино", "movie", "trailer", "netflix"]
        case .design: keywords = ["дизайн", "интерфейс", "цвет", "design", "ui", "font"]
        case .games: keywords = ["игра", "game", "steam", "playstation", "xbox"]
        case .recipes: keywords = ["рецепт", "ингредиент", "готовить", "recipe", "food", "cook"]
        case .travel: keywords = ["путешествие", "отель", "билет", "travel", "hotel", "flight"]
        case .general: keywords = []
        }
        result += keywords.filter { text.contains($0) }.count * 3
        return result
    }
}
