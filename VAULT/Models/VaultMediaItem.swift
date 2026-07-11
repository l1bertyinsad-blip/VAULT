import Foundation
import SwiftData

enum VaultMediaType: String, Codable, CaseIterable, Sendable {
    case photo
    case video
}

@Model
final class VaultMediaItem {
    @Attribute(.unique) var id: UUID
    var mediaTypeRaw: String
    var localFileName: String
    var thumbnailFileName: String
    var originalFileName: String?
    var createdAt: Date
    var sortOrder: Int
    var duration: Double?
    var folder: VaultFolder?
    var note: String = ""
    var tagsRaw: String = ""
    var sourceURLString: String = ""
    var isFavorite: Bool = false
    var isArchived: Bool = false
    var statusRaw: String = ""
    var rating: Int = 0
    var price: Double?
    var recognizedText: String = ""
    var contentHash: String = ""

    var mediaType: VaultMediaType {
        get { VaultMediaType(rawValue: mediaTypeRaw) ?? .photo }
        set { mediaTypeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        mediaType: VaultMediaType,
        localFileName: String,
        thumbnailFileName: String,
        originalFileName: String? = nil,
        createdAt: Date = .now,
        sortOrder: Int = 0,
        duration: Double? = nil,
        folder: VaultFolder? = nil,
        note: String = "",
        tags: [String] = [],
        sourceURLString: String = "",
        isFavorite: Bool = false,
        isArchived: Bool = false,
        status: String = "",
        rating: Int = 0,
        price: Double? = nil,
        recognizedText: String = "",
        contentHash: String = ""
    ) {
        self.id = id
        self.mediaTypeRaw = mediaType.rawValue
        self.localFileName = localFileName
        self.thumbnailFileName = thumbnailFileName
        self.originalFileName = originalFileName
        self.createdAt = createdAt
        self.sortOrder = sortOrder
        self.duration = duration
        self.folder = folder
        self.note = note
        self.tagsRaw = tags.joined(separator: "\n")
        self.sourceURLString = sourceURLString
        self.isFavorite = isFavorite
        self.isArchived = isArchived
        self.statusRaw = status
        self.rating = rating
        self.price = price
        self.recognizedText = recognizedText
        self.contentHash = contentHash
    }

    var tags: [String] {
        get {
            tagsRaw.split(separator: "\n")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            tagsRaw = Array(Set(newValue.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }.filter { !$0.isEmpty })).sorted().joined(separator: "\n")
        }
    }

    var searchableText: String {
        [originalFileName ?? "", note, tagsRaw, sourceURLString, statusRaw, recognizedText]
            .joined(separator: " ")
            .lowercased()
    }
}
