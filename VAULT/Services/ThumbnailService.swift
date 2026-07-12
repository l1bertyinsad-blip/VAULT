import AVFoundation
import UIKit

enum ThumbnailError: LocalizedError {
    case unreadableImage
    case encodingFailed
    case unsupportedType

    var errorDescription: String? { "Не удалось создать превью материала." }
}

struct ThumbnailResult {
    let fileName: String
    let duration: Double?
}

struct ThumbnailService: Sendable {
    func create(
        sourceURL: URL,
        mediaType: VaultMediaType,
        id: UUID,
        storage: LocalFileService
    ) async throws -> ThumbnailResult {
        let result: (Data, Double?) = try await Task.detached(priority: .userInitiated) {
            switch mediaType {
            case .photo:
                guard let image = UIImage(contentsOfFile: sourceURL.path) else {
                    throw ThumbnailError.unreadableImage
                }
                return (try Self.jpegThumbnail(from: image), nil)
            case .video:
                let asset = AVURLAsset(url: sourceURL)
                let assetDuration = try await asset.load(.duration)
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                generator.maximumSize = CGSize(width: 700, height: 700)
                let totalSeconds = CMTimeGetSeconds(assetDuration)
                let seconds = totalSeconds.isFinite ? max(0, min(totalSeconds * 0.15, 2)) : 0
                let (imageRef, _) = try await generator.image(
                    at: CMTime(seconds: seconds, preferredTimescale: 600)
                )
                let image = UIImage(cgImage: imageRef)
                return (try Self.jpegThumbnail(from: image), totalSeconds.isFinite ? totalSeconds : nil)
            case .link:
                throw ThumbnailError.unsupportedType
            }
        }.value

        let fileName = try storage.writeThumbnail(result.0, id: id)
        return ThumbnailResult(fileName: fileName, duration: result.1)
    }

    private static func jpegThumbnail(from image: UIImage) throws -> Data {
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, 700 / max(longest, 1))
        let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let renderer = UIGraphicsImageRenderer(size: size)
        let rendered = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let data = rendered.jpegData(compressionQuality: 0.82) else {
            throw ThumbnailError.encodingFailed
        }
        return data
    }
}
