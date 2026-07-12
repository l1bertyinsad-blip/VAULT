import LinkPresentation
import SwiftData
import UniformTypeIdentifiers
import UIKit

@MainActor
enum LinkMetadataService {
    static func enrich(_ item: VaultMediaItem, context: ModelContext) async {
        guard item.mediaType == .link,
              let url = URL(string: item.sourceURLString) else { return }

        do {
            let metadataProvider = LPMetadataProvider()
            metadataProvider.timeout = 12
            let metadata = try await metadataProvider.startFetchingMetadata(for: url)

            if let metadataTitle = metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines),
               !metadataTitle.isEmpty,
               metadataTitle.localizedCaseInsensitiveCompare("Instagram") != .orderedSame,
               shouldReplaceTitle(item.title, sourceURL: url) {
                item.title = metadataTitle
            }

            let previewProvider = metadata.imageProvider ?? metadata.iconProvider
            if let previewProvider,
               let data = await loadImageData(from: previewProvider),
               let image = UIImage(data: data),
               let jpeg = image.jpegData(compressionQuality: 0.84) {
                if !item.thumbnailFileName.isEmpty {
                    LocalFileService.shared.delete(localFileName: "", thumbnailFileName: item.thumbnailFileName)
                }
                item.thumbnailFileName = try LocalFileService.shared.writeThumbnail(jpeg, id: item.id)
            }

            try? context.save()
        } catch {
            // Ссылка остаётся рабочей даже без сетевого превью.
        }
    }

    private static func shouldReplaceTitle(_ title: String, sourceURL: URL) -> Bool {
        let host = sourceURL.host?.replacingOccurrences(of: "www.", with: "") ?? ""
        return title.isEmpty || title == host || title == "Instagram" || title == "Instagram Reel"
    }

    private static func loadImageData(from provider: NSItemProvider) async -> Data? {
        let typeIdentifier = provider.registeredTypeIdentifiers.first { identifier in
            UTType(identifier)?.conforms(to: .image) == true
        } ?? UTType.image.identifier
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                continuation.resume(returning: data)
            }
        }
    }
}
