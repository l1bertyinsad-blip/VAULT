import Foundation

enum LocalFileServiceError: LocalizedError {
    case invalidFileName
    case missingFile

    var errorDescription: String? {
        switch self {
        case .invalidFileName: "Не удалось подготовить имя файла."
        case .missingFile: "Сохранённый файл больше недоступен."
        }
    }
}

final class LocalFileService: @unchecked Sendable {
    static let shared = LocalFileService()

    enum Location { case media, thumbnail }

    let rootURL: URL
    private let fileManager: FileManager

    private var mediaURL: URL { rootURL.appendingPathComponent("Media", isDirectory: true) }
    private var thumbnailURL: URL { rootURL.appendingPathComponent("Thumbnails", isDirectory: true) }

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.rootURL = documents.appendingPathComponent("VAULT", isDirectory: true)
        }
    }

    func prepareDirectories() throws {
        try fileManager.createDirectory(at: mediaURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: thumbnailURL, withIntermediateDirectories: true)
    }

    func writeMedia(_ data: Data, id: UUID, fileExtension: String) throws -> String {
        try prepareDirectories()
        let cleanExtension = fileExtension
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            .lowercased()
        guard !cleanExtension.isEmpty else { throw LocalFileServiceError.invalidFileName }
        let fileName = "\(id.uuidString).\(cleanExtension)"
        let destination = url(for: fileName, location: .media)
        try data.write(to: destination, options: .atomic)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: destination.path
        )
        return fileName
    }

    func writeThumbnail(_ data: Data, id: UUID) throws -> String {
        try prepareDirectories()
        let fileName = "\(id.uuidString).jpg"
        let destination = url(for: fileName, location: .thumbnail)
        try data.write(to: destination, options: .atomic)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: destination.path
        )
        return fileName
    }

    func url(for fileName: String, location: Location) -> URL {
        let safeName = URL(fileURLWithPath: fileName).lastPathComponent
        let directory: URL
        switch location {
        case .media: directory = mediaURL
        case .thumbnail: directory = thumbnailURL
        }
        return directory.appendingPathComponent(safeName)
    }

    func existingURL(for fileName: String, location: Location) throws -> URL {
        let candidate = url(for: fileName, location: location)
        guard fileManager.fileExists(atPath: candidate.path) else {
            throw LocalFileServiceError.missingFile
        }
        return candidate
    }

    func delete(media item: VaultMediaItem) {
        if !item.localFileName.isEmpty {
            try? fileManager.removeItem(at: url(for: item.localFileName, location: .media))
        }
        if !item.thumbnailFileName.isEmpty {
            try? fileManager.removeItem(at: url(for: item.thumbnailFileName, location: .thumbnail))
        }
    }

    func deleteMedia(named fileName: String) {
        try? fileManager.removeItem(at: url(for: fileName, location: .media))
    }

    func delete(localFileName: String, thumbnailFileName: String) {
        if !localFileName.isEmpty {
            try? fileManager.removeItem(at: url(for: localFileName, location: .media))
        }
        if !thumbnailFileName.isEmpty {
            try? fileManager.removeItem(at: url(for: thumbnailFileName, location: .thumbnail))
        }
    }

    func deleteAll() throws {
        if fileManager.fileExists(atPath: rootURL.path) {
            try fileManager.removeItem(at: rootURL)
        }
        try prepareDirectories()
    }

    func usedBytes() -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        ) else { return 0 }

        return enumerator.compactMap { $0 as? URL }.reduce(into: Int64(0)) { total, url in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true else { return }
            total += Int64(values.fileSize ?? 0)
        }
    }
}
