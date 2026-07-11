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
        folder: VaultFolder? = nil
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
    }
}
