import CryptoKit
import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import Vision

struct ImportedMediaDraft: Sendable {
    let id: UUID
    let mediaType: VaultMediaType
    let localFileName: String
    let thumbnailFileName: String
    let originalFileName: String?
    let duration: Double?
    let recognizedText: String
    let contentHash: String
    let title: String
    let caption: String
    let sourceURLString: String
}

struct SharedLinkPayload: Codable, Sendable {
    let version: Int
    let url: String
    let title: String
    let caption: String
    let source: String
    let folderID: UUID?
}

struct SharedFolderCatalog: Codable, Sendable {
    struct Entry: Codable, Sendable {
        let id: UUID
        let name: String
        let symbolName: String
        let isSystem: Bool
    }

    let version: Int
    let folders: [Entry]
}

enum MediaImportOutcome {
    case success(ImportedMediaDraft)
    case failure
}

struct MediaImportService: Sendable {
    let storage: LocalFileService
    let thumbnailService: ThumbnailService

    init(
        storage: LocalFileService = .shared,
        thumbnailService: ThumbnailService = ThumbnailService()
    ) {
        self.storage = storage
        self.thumbnailService = thumbnailService
    }

    func importItem(_ item: PhotosPickerItem) async -> MediaImportOutcome {
        let type = resolveType(item)
        let contentType = preferredContentType(item, for: type)

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                return .failure
            }
            return await importData(
                data,
                type: type,
                fileExtension: contentType?.preferredFilenameExtension ?? (type == .video ? "mov" : "jpg"),
                originalFileName: nil
            )
        } catch {
            return .failure
        }
    }

    func importFile(at url: URL) async -> MediaImportOutcome {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            if url.pathExtension.lowercased() == "vaultlink" {
                return try importSharedLinkData(Data(contentsOf: url))
            }
            let values = try url.resourceValues(forKeys: [.contentTypeKey, .nameKey])
            let contentType = values.contentType ?? UTType(filenameExtension: url.pathExtension)
            guard let contentType else { return .failure }
            let type: VaultMediaType
            if contentType.conforms(to: .movie) { type = .video }
            else if contentType.conforms(to: .image) { type = .photo }
            else { return .failure }

            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            return await importData(
                data,
                type: type,
                fileExtension: contentType.preferredFilenameExtension ?? url.pathExtension,
                originalFileName: Self.cleanSharedFileName(values.name ?? url.lastPathComponent)
            )
        } catch {
            return .failure
        }
    }

    private func importData(
        _ data: Data,
        type: VaultMediaType,
        fileExtension: String,
        originalFileName: String?
    ) async -> MediaImportOutcome {
        let id = UUID()
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()

        do {
            let localFileName = try storage.writeMedia(data, id: id, fileExtension: fileExtension)
            do {
                let sourceURL = storage.url(for: localFileName, location: .media)
                let thumbnail = try await thumbnailService.create(
                    sourceURL: sourceURL,
                    mediaType: type,
                    id: id,
                    storage: storage
                )
                let recognizedText = type == .photo
                    ? await OCRService.recognizeText(at: sourceURL)
                    : ""
                return .success(ImportedMediaDraft(
                    id: id,
                    mediaType: type,
                    localFileName: localFileName,
                    thumbnailFileName: thumbnail.fileName,
                    originalFileName: originalFileName,
                    duration: thumbnail.duration,
                    recognizedText: recognizedText,
                    contentHash: hash,
                    title: "",
                    caption: "",
                    sourceURLString: ""
                ))
            } catch {
                storage.deleteMedia(named: localFileName)
                return .failure
            }
        } catch {
            return .failure
        }
    }

    func makeLinkDraft(from rawValue: String, title: String = "", caption: String = "") -> ImportedMediaDraft? {
        guard let normalizedURL = Self.normalizedWebURL(from: rawValue) else { return nil }
        let cleanCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let inferredCaption = rawValue
            .replacingOccurrences(of: normalizedURL.absoluteString, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return linkDraft(
            url: normalizedURL,
            title: title,
            caption: cleanCaption.isEmpty ? inferredCaption : cleanCaption
        )
    }

    static func normalizedWebURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let detectedSharedURL = trimmed
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .first(where: { $0.hasPrefix("https://") || $0.hasPrefix("http://") })
        let sharedURL = detectedSharedURL?.trimmingCharacters(
            in: CharacterSet(charactersIn: "<>[](){}\"'.,;!?")
        )
        let candidate = sharedURL ?? (trimmed.contains("://") ? trimmed : "https://\(trimmed)")
        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else { return nil }
        return url
    }

    private func importSharedLinkData(_ data: Data) throws -> MediaImportOutcome {
        let payload = try JSONDecoder().decode(SharedLinkPayload.self, from: data)
        guard let url = Self.normalizedWebURL(from: payload.url) else { return .failure }
        return .success(linkDraft(url: url, title: payload.title, caption: payload.caption))
    }

    private static func cleanSharedFileName(_ name: String) -> String {
        guard let separator = name.range(of: "--") else { return name }
        return String(name[separator.upperBound...])
    }

    private func linkDraft(url: URL, title: String, caption: String) -> ImportedMediaDraft {
        let urlString = url.absoluteString
        let hash = SHA256.hash(data: Data(urlString.utf8)).map { String(format: "%02x", $0) }.joined()
        let host = url.host?.replacingOccurrences(of: "www.", with: "") ?? "Ссылка"
        let suggestedTitle: String
        if host.contains("instagram.com") {
            suggestedTitle = url.path.contains("/reel") ? "Instagram Reel" : "Instagram"
        } else {
            suggestedTitle = host
        }
        return ImportedMediaDraft(
            id: UUID(),
            mediaType: .link,
            localFileName: "",
            thumbnailFileName: "",
            originalFileName: nil,
            duration: nil,
            recognizedText: "",
            contentHash: hash,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? suggestedTitle : title,
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceURLString: urlString
        )
    }

    private func resolveType(_ item: PhotosPickerItem) -> VaultMediaType {
        item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) ? .video : .photo
    }

    private func preferredContentType(_ item: PhotosPickerItem, for type: VaultMediaType) -> UTType? {
        item.supportedContentTypes.first(where: {
            $0.conforms(to: type == .video ? .movie : .image)
        })
    }
}

enum SharedImportQueue {
    static let appGroupIdentifier = "group.com.nevsk1y.vault"

    static func pendingFiles() -> [URL] {
        guard let directory = incomingDirectory(createIfNeeded: false),
              let files = try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
              ) else { return [] }

        return files.filter { url in
            (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        }.sorted { lhs, rhs in
            let left = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let right = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return left < right
        }
    }

    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    static func destinationFolderID(for url: URL) -> UUID? {
        if url.pathExtension.lowercased() == "vaultlink",
           let data = try? Data(contentsOf: url),
           let payload = try? JSONDecoder().decode(SharedLinkPayload.self, from: data) {
            return payload.folderID
        }

        let name = url.deletingPathExtension().lastPathComponent
        let parts = name.components(separatedBy: "--")
        guard parts.count == 2 else { return nil }
        return UUID(uuidString: parts[0])
    }

    static func publishFolderCatalog(_ folders: [VaultFolder]) {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else { return }
        let catalog = SharedFolderCatalog(
            version: 1,
            folders: folders.map {
                SharedFolderCatalog.Entry(
                    id: $0.id,
                    name: $0.name,
                    symbolName: $0.symbolName,
                    isSystem: $0.isSystem
                )
            }
        )
        guard let data = try? JSONEncoder().encode(catalog) else { return }
        try? data.write(to: groupURL.appendingPathComponent("FolderCatalog.json"), options: .atomic)
    }

    static func incomingDirectory(createIfNeeded: Bool) -> URL? {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else { return nil }
        let directory = groupURL.appendingPathComponent("Incoming", isDirectory: true)
        if createIfNeeded {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}

private enum OCRService {
    static func recognizeText(at url: URL) async -> String {
        await Task.detached(priority: .utility) {
            guard let image = UIImage(contentsOfFile: url.path)?.cgImage else { return "" }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                try VNImageRequestHandler(cgImage: image).perform([request])
                return (request.results ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
            } catch {
                return ""
            }
        }.value
    }
}
