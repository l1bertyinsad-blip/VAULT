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
            let url = LocalFileService.shared.url(for: item.thumbnailFileName, location: .thumbnail)
            image = await Task.detached { UIImage(contentsOfFile: url.path) }.value
            isMissing = image == nil
        }
        .accessibilityLabel(item.mediaType == .video ? "Видео" : "Фотография")
    }
}

extension Double {
    var formattedDuration: String {
        guard isFinite, self >= 0 else { return "0:00" }
        let total = Int(self.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
