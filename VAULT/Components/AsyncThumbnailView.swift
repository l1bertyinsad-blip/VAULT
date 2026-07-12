import SwiftUI
import UIKit

struct AsyncThumbnailView: View {
    let item: VaultMediaItem
    @State private var image: UIImage?
    @State private var isMissing = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if item.mediaType == .link {
                    LinkThumbnailPlaceholder(item: item)
                } else if isMissing {
                    Rectangle()
                        .fill(Color(.secondarySystemFill))
                        .overlay(Image(systemName: "exclamationmark.triangle").foregroundStyle(.secondary))
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemFill))
                        .overlay(ProgressView())
                }
            }

            if item.mediaType == .video {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                    if let duration = item.duration { Text(duration.formattedDuration) }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.black.opacity(0.65), in: Capsule())
                .padding(6)
            }
        }
        .clipped()
        .task(id: item.thumbnailFileName) {
            guard !item.thumbnailFileName.isEmpty else { return }
            let url = LocalFileService.shared.url(for: item.thumbnailFileName, location: .thumbnail)
            image = await Task.detached { UIImage(contentsOfFile: url.path) }.value
            isMissing = image == nil
        }
        .accessibilityLabel(accessibilityTitle)
    }

    private var accessibilityTitle: String {
        switch item.mediaType {
        case .photo: "Фотография"
        case .video: "Видео"
        case .link: "Сохранённая ссылка"
        }
    }
}

private struct LinkThumbnailPlaceholder: View {
    let item: VaultMediaItem

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isInstagram
                    ? [Color(red: 0.98, green: 0.25, blue: 0.42), Color(red: 0.55, green: 0.18, blue: 0.86)]
                    : [Color(red: 0.20, green: 0.46, blue: 0.96), VaultPalette.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 110, height: 110)
                .offset(x: 38, y: -32)
            VStack(spacing: 7) {
                Image(systemName: isInstagram ? "play.rectangle.on.rectangle.fill" : "link")
                    .font(.system(size: 31, weight: .semibold))
                Text(isInstagram ? "REEL" : host.uppercased())
                    .font(.caption2.bold())
                    .tracking(1.2)
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .padding(12)
        }
    }

    private var host: String {
        URL(string: item.sourceURLString)?.host?.replacingOccurrences(of: "www.", with: "") ?? "LINK"
    }

    private var isInstagram: Bool { host.contains("instagram.com") }
}

extension Double {
    var formattedDuration: String {
        guard isFinite, self >= 0 else { return "0:00" }
        let total = Int(self.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
