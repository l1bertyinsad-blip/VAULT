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
        let id = UUID()
        let type = resolveType(item)
        let contentType = preferredContentType(item, for: type)
        let fileExtension = contentType?.preferredFilenameExtension ?? (type == .video ? "mov" : "jpg")

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                return .failure
            }
            let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
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
                    originalFileName: nil,
                    duration: thumbnail.duration,
                    recognizedText: recognizedText,
                    contentHash: hash
                ))
            } catch {
                storage.deleteMedia(named: localFileName)
                return .failure
            }
        } catch {
            return .failure
        }
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
