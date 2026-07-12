import AVKit
import SwiftData
import SwiftUI

struct MediaViewer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var items: [VaultMediaItem]
    @State private var currentID: UUID
    @State private var showsDeleteConfirmation = false
    @State private var showsMove = false
    @State private var showsMetadata = false
    @State private var showsShare = false

    init(items: [VaultMediaItem], initialItemID: UUID) {
        _items = State(initialValue: items)
        _currentID = State(initialValue: initialItemID)
    }

    private var currentItem: VaultMediaItem? { items.first(where: { $0.id == currentID }) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentID) {
                ForEach(items) { item in
                    MediaPage(item: item)
                        .tag(item.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .frame(width: 42, height: 42)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                    .accessibilityLabel("Закрыть")
                    Spacer()
                    Button { toggleFavorite() } label: {
                        Image(systemName: currentItem?.isFavorite == true ? "star.fill" : "star")
                            .foregroundStyle(currentItem?.isFavorite == true ? .yellow : .white)
                            .frame(width: 42, height: 42)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                    .accessibilityLabel("Избранное")
                    Text(positionText)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.45), in: Capsule())
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                if let item = currentItem,
                   item.mediaType != .link,
                   !item.title.isEmpty || !item.caption.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        if !item.title.isEmpty {
                            Text(item.title)
                                .font(.headline)
                        }
                        if !item.caption.isEmpty {
                            Text(item.caption)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.78))
                                .lineLimit(3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }

                HStack(spacing: 28) {
                    Button { showsMetadata = true } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Описание и теги")
                    Button { showsShare = true } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Поделиться")
                    Button { showsMove = true } label: {
                        Image(systemName: "folder")
                    }
                    .accessibilityLabel("Переместить")
                    Button(role: .destructive) { showsDeleteConfirmation = true } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel("Удалить")
                }
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(.black.opacity(0.48), in: Capsule())
                .padding(.bottom, 12)
            }
            .foregroundStyle(.white)
        }
        .statusBarHidden()
        .alert("Удалить материал?", isPresented: $showsDeleteConfirmation) {
            Button("Удалить", role: .destructive) { deleteCurrent() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Файл будет удалён без возможности восстановления.")
        }
        .sheet(isPresented: $showsMove) {
            if let item = currentItem, let folder = item.folder {
                MoveItemsSheet(items: [item], currentFolder: folder) { dismiss() }
            }
        }
        .sheet(isPresented: $showsMetadata) {
            if let item = currentItem { MediaMetadataSheet(item: item) }
        }
        .sheet(isPresented: $showsShare) {
            if let item = currentItem {
                ActivityView(activityItems: shareItems(for: item))
            }
        }
    }

    private var positionText: String {
        guard let index = items.firstIndex(where: { $0.id == currentID }) else { return "" }
        return "\(index + 1) из \(items.count)"
    }

    private func deleteCurrent() {
        guard let index = items.firstIndex(where: { $0.id == currentID }) else { return }
        let item = items[index]
        let next = items.indices.contains(index + 1) ? items[index + 1] : (index > 0 ? items[index - 1] : nil)
        VaultOperations.delete(item, in: context)
        items.remove(at: index)
        if let next { currentID = next.id } else { dismiss() }
    }

    private func toggleFavorite() {
        guard let item = currentItem else { return }
        item.isFavorite.toggle()
        try? context.save()
    }

    private func shareItems(for item: VaultMediaItem) -> [Any] {
        if item.mediaType == .link,
           let url = URL(string: item.sourceURLString) {
            var result: [Any] = []
            if !item.caption.isEmpty { result.append(item.caption) }
            result.append(url)
            return result
        }
        var result: [Any] = []
        if !item.caption.isEmpty { result.append(item.caption) }
        result.append(LocalFileService.shared.url(for: item.localFileName, location: .media))
        return result
    }
}

private struct MediaPage: View {
    let item: VaultMediaItem

    var body: some View {
        let url = LocalFileService.shared.url(for: item.localFileName, location: .media)
        Group {
            switch item.mediaType {
            case .photo:
                ZoomableImage(url: url)
            case .video:
                VaultVideoPlayer(url: url)
            case .link:
                LinkMediaPage(item: item)
            }
        }
        .accessibilityLabel(accessibilityTitle)
    }

    private var accessibilityTitle: String {
        switch item.mediaType {
        case .photo: "Фото на весь экран"
        case .video: "Видеоплеер"
        case .link: "Сохранённая ссылка"
        }
    }
}

private struct LinkMediaPage: View {
    let item: VaultMediaItem

    private var url: URL? { URL(string: item.sourceURLString) }
    private var host: String {
        url?.host?.replacingOccurrences(of: "www.", with: "") ?? "Ссылка"
    }
    private var isInstagram: Bool { host.contains("instagram.com") }

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                AsyncThumbnailView(item: item)
                    .frame(height: 310)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                    .shadow(color: (isInstagram ? Color.pink : VaultPalette.purple).opacity(0.35), radius: 26, y: 14)
                LinearGradient(
                    colors: [.clear, .black.opacity(0.62)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
                VStack(spacing: 13) {
                    Image(systemName: isInstagram ? "play.rectangle.on.rectangle.fill" : "link")
                        .font(.system(size: 58, weight: .semibold))
                    Text(isInstagram ? "INSTAGRAM REEL" : host.uppercased())
                        .font(.caption.bold())
                        .tracking(1.8)
                }
                .foregroundStyle(.white)
            }
            .frame(height: 310)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)

            VStack(spacing: 7) {
                Text(item.title.isEmpty ? (isInstagram ? "Instagram Reel" : host) : item.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("Ссылка сохранена в VAULT")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }

            if let url {
                Link(destination: url) {
                    Label(isInstagram ? "Открыть в Instagram" : "Открыть источник", systemImage: "arrow.up.right.square.fill")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 15)
                        .background(.white, in: Capsule())
                }
            }
        }
        .padding(.top, 36)
        .padding(.bottom, 110)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ZoomableImage: View {
    let url: URL
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in scale = min(max(lastScale * value, 1), 5) }
                            .onEnded { _ in lastScale = scale }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3)) {
                            scale = scale > 1 ? 1 : 2.5
                            lastScale = scale
                        }
                    }
            } else {
                ContentUnavailableView("Файл недоступен", systemImage: "photo.badge.exclamationmark")
                    .foregroundStyle(.white)
            }
        }
        .task { image = await Task.detached { UIImage(contentsOfFile: url.path) }.value }
    }
}

private struct VaultVideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        if FileManager.default.fileExists(atPath: url.path) {
            VideoPlayer(player: player)
                .onDisappear { player.pause() }
        } else {
            ContentUnavailableView("Видео недоступно", systemImage: "video.slash")
                .foregroundStyle(.white)
        }
    }
}
