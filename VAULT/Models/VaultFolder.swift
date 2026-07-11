import Foundation
import SwiftData

enum VaultFolderTemplate: String, Codable, CaseIterable, Identifiable, Sendable, Equatable {
    case general
    case purchases
    case films
    case design
    case games
    case recipes
    case travel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "Коллекция"
        case .purchases: "Покупки"
        case .films: "Фильмы"
        case .design: "Дизайн"
        case .games: "Игры"
        case .recipes: "Рецепты"
        case .travel: "Путешествия"
        }
    }

    var symbolName: String {
        switch self {
        case .general: "folder.fill"
        case .purchases: "cart.fill"
        case .films: "film.fill"
        case .design: "paintpalette.fill"
        case .games: "gamecontroller.fill"
        case .recipes: "fork.knife"
        case .travel: "airplane"
        }
    }

    var statuses: [String] {
        switch self {
        case .purchases: ["Хочу", "Сравниваю", "Заказано", "Куплено"]
        case .films: ["Посмотреть", "Смотрю", "Просмотрено"]
        case .design: ["Идея", "В работе", "Использовано"]
        case .games: ["Изучить", "Проверить", "Готово"]
        case .recipes: ["Попробовать", "Любимое", "Приготовлено"]
        case .travel: ["Мечта", "Запланировано", "Посещено"]
        case .general: []
        }
    }
}

@Model
final class VaultFolder {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorIdentifier: String
    var symbolName: String
    var createdAt: Date
    var sortOrder: Int
    var templateRaw: String = VaultFolderTemplate.general.rawValue
    var isSystem: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \VaultMediaItem.folder)
    var items: [VaultMediaItem]

    init(
        id: UUID = UUID(),
        name: String,
        colorIdentifier: String = "purple",
        symbolName: String = "folder.fill",
        createdAt: Date = .now,
        sortOrder: Int = 0,
        template: VaultFolderTemplate = .general,
        isSystem: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorIdentifier = colorIdentifier
        self.symbolName = symbolName
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.templateRaw = template.rawValue
        self.isSystem = isSystem
        self.items = []
    }

    var template: VaultFolderTemplate {
        get { VaultFolderTemplate(rawValue: templateRaw) ?? .general }
        set { templateRaw = newValue.rawValue }
    }
}
