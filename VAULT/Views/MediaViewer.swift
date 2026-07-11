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
                ActivityView(activityItems: [
                    LocalFileService.shared.url(for: item.localFileName, location: .media)
                ])
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
}

private struct MediaPage: View {
    let item: VaultMediaItem

    var body: some View {
        let url = LocalFileService.shared.url(for: item.localFileName, location: .media)
        Group {
            if item.mediaType == .photo {
                ZoomableImage(url: url)
            } else {
                VaultVideoPlayer(url: url)
            }
        }
        .accessibilityLabel(item.mediaType == .photo ? "Фото на весь экран" : "Видеоплеер")
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
