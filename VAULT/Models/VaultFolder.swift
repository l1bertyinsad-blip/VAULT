import Foundation
import SwiftData

@Model
final class VaultFolder {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorIdentifier: String
    var symbolName: String
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \VaultMediaItem.folder)
    var items: [VaultMediaItem]

    init(
        id: UUID = UUID(),
        name: String,
        colorIdentifier: String = "purple",
        symbolName: String = "folder.fill",
        createdAt: Date = .now,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorIdentifier = colorIdentifier
        self.symbolName = symbolName
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.items = []
    }
}
