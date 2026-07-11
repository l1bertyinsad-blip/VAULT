import SwiftData
import SwiftUI

struct FoldersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VaultFolder.sortOrder) private var folders: [VaultFolder]
    @Query(sort: \VaultMediaItem.createdAt, order: .reverse) private var allItems: [VaultMediaItem]

    @State private var showsCreateFolder = false
    @State private var searchText = ""

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var visibleFolders: [VaultFolder] {
        folders.sorted {
            if $0.isSystem != $1.isSystem { return $0.isSystem }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private var searchResults: [VaultMediaItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return [] }
        return allItems.filter {
            !$0.isArchived && (
                $0.searchableText.contains(query) ||
                ($0.folder?.name.lowercased().contains(query) ?? false)
            )
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    GlobalSearchResults(items: searchResults, query: searchText)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            QuickCollectionsRow(
                                favoriteCount: allItems.filter(\.isFavorite).count,
                                archivedCount: allItems.filter(\.isArchived).count
                            )

                            if visibleFolders.isEmpty {
                                VaultEmptyState(
                                    title: "Создайте первую папку",
                                    message: "Собирайте визуальные идеи и превращайте их в полезные коллекции",
                                    buttonTitle: "Создать папку"
                                ) { showsCreateFolder = true }
                                .frame(minHeight: 420)
                                .accessibilityIdentifier("foldersEmptyState")
                            } else {
                                LazyVGrid(columns: columns, spacing: 14) {
                                    ForEach(visibleFolders) { folder in
                                        NavigationLink {
                                            FolderView(folder: folder)
                                        } label: {
                                            FolderCard(folder: folder)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityIdentifier("folderCard_\(folder.name)")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Мои папки")
            .searchable(text: $searchText, prompt: "Текст, тег, заметка или папка")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showsCreateFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("Создать папку")
                    .accessibilityIdentifier("createFolderButton")

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Настройки")
                }
            }
            .sheet(isPresented: $showsCreateFolder) {
                FolderEditorSheet(
                    mode: .create,
                    nextSortOrder: (folders.map(\.sortOrder).max() ?? -1) + 1
                )
            }
            .task { ensureInbox() }
        }
    }

    private func ensureInbox() {
        guard !folders.contains(where: { $0.isSystem }) else { return }
        let inbox = VaultFolder(
            name: "Входящие",
            colorIdentifier: "purple",
            symbolName: "tray.full.fill",
            sortOrder: -1_000,
            template: .general,
            isSystem: true
        )
        context.insert(inbox)
        try? context.save()
    }
}

private struct QuickCollectionsRow: View {
    let favoriteCount: Int
    let archivedCount: Int

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                SmartMediaCollectionView(mode: .favorites)
            } label: {
                QuickCollectionCard(
                    title: "Избранное",
                    count: favoriteCount,
                    symbol: "star.fill",
                    color: .yellow
                )
            }
            NavigationLink {
                SmartMediaCollectionView(mode: .archive)
            } label: {
                QuickCollectionCard(
                    title: "Архив",
                    count: archivedCount,
                    symbol: "archivebox.fill",
                    color: .secondary
                )
            }
        }
        .buttonStyle(.plain)
    }
}

private struct QuickCollectionCard: View {
    let title: String
    let count: Int
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.13), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text("\(count)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct FolderCard: View {
    let folder: VaultFolder

    private var activeItems: [VaultMediaItem] { folder.items.filter { !$0.isArchived } }
    private var latestItem: VaultMediaItem? { activeItems.max(by: { $0.createdAt < $1.createdAt }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Group {
                    if let latestItem {
                        AsyncThumbnailView(item: latestItem)
                    } else {
                        Rectangle()
                            .fill(VaultPalette.color(for: folder.colorIdentifier).opacity(0.14))
                            .overlay {
                                Image(systemName: folder.symbolName)
                                    .font(.system(size: 42, weight: .medium))
                                    .foregroundStyle(VaultPalette.color(for: folder.colorIdentifier))
                            }
                    }
                }
                .frame(height: 126)

                Image(systemName: folder.symbolName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(VaultPalette.color(for: folder.colorIdentifier), in: Circle())
                    .padding(10)
                    .shadow(color: .black.opacity(0.16), radius: 5, y: 2)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(folder.name).font(.headline).lineLimit(1)
                    if folder.isSystem {
                        Image(systemName: "sparkles").font(.caption2).foregroundStyle(VaultPalette.purple)
                    }
                }
                Text(activeItems.count.formattedItems)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if folder.template != .general {
                    Text(folder.template.title)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(VaultPalette.color(for: folder.colorIdentifier))
                }
            }
            .padding(12)
        }
        .foregroundStyle(.primary)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
        }
    }
}

private struct GlobalSearchResults: View {
    let items: [VaultMediaItem]
    let query: String
    @State private var viewerItem: VaultMediaItem?

    var body: some View {
        List(items) { item in
            Button { viewerItem = item } label: {
                HStack(spacing: 12) {
                    AsyncThumbnailView(item: item)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.note.isEmpty ? (item.folder?.name ?? "Материал") : item.note)
                            .font(.headline)
                            .lineLimit(2)
                        Text(item.folder?.name ?? "Без папки")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !item.tags.isEmpty {
                            Text(item.tags.map { "#\($0)" }.joined(separator: "  "))
                                .font(.caption2)
                                .foregroundStyle(VaultPalette.purple)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .fullScreenCover(item: $viewerItem) { item in
            MediaViewer(items: items, initialItemID: item.id)
        }
    }
}

private struct SmartMediaCollectionView: View {
    enum Mode: Equatable { case favorites, archive }
    @Query(sort: \VaultMediaItem.createdAt, order: .reverse) private var allItems: [VaultMediaItem]
    @State private var viewerItem: VaultMediaItem?
    let mode: Mode

    private var items: [VaultMediaItem] {
        switch mode {
        case .favorites: allItems.filter(\.isFavorite)
        case .archive: allItems.filter(\.isArchived)
        }
    }

    private var title: String { mode == .favorites ? "Избранное" : "Архив" }
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(items) { item in
                    Button { viewerItem = item } label: {
                        AsyncThumbnailView(item: item).aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(title, systemImage: mode == .favorites ? "star" : "archivebox")
            }
        }
        .navigationTitle(title)
        .fullScreenCover(item: $viewerItem) { item in
            MediaViewer(items: items, initialItemID: item.id)
        }
    }
}

extension Int {
    var formattedItems: String {
        let rem10 = self % 10
        let rem100 = self % 100
        let noun: String
        if rem10 == 1 && rem100 != 11 { noun = "материал" }
        else if (2...4).contains(rem10) && !(12...14).contains(rem100) { noun = "материала" }
        else { noun = "материалов" }
        return "\(self) \(noun)"
    }
}
