import SwiftData
import SwiftUI

enum VaultTab: String, CaseIterable {
    case home
    case folders
    case favorites
    case profile

    var title: String {
        switch self {
        case .home: "Лента"
        case .folders: "Папки"
        case .favorites: "Избранное"
        case .profile: "Профиль"
        }
    }

    var symbol: String {
        switch self {
        case .home: "rectangle.stack.fill"
        case .folders: "folder.fill"
        case .favorites: "star.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \VaultFolder.sortOrder) private var folders: [VaultFolder]
    @Query(sort: \VaultMediaItem.createdAt, order: .reverse) private var allItems: [VaultMediaItem]
    @State private var selectedTab = VaultTab.home
    @State private var showsQuickImport = false
    @State private var sharedImporter = MediaImportViewModel()
    @State private var lastSharedImportIDs: [UUID] = []

    private var folderSignature: String {
        folders.map { "\($0.id.uuidString):\($0.name):\($0.sortOrder)" }.joined(separator: "|")
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            UsefulFeedView(openImport: { showsQuickImport = true })
                .tag(VaultTab.home)
            FoldersView()
                .tag(VaultTab.folders)
            FavoritesGalleryView()
                .tag(VaultTab.favorites)
            ProfileView()
                .tag(VaultTab.profile)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VaultTabBar(selection: $selectedTab) { showsQuickImport = true }
        }
        .sheet(isPresented: $showsQuickImport) { QuickImportSheet() }
        .overlay {
            if sharedImporter.isImporting {
                VStack(spacing: 12) {
                    ProgressView(value: sharedImporter.progress).frame(width: 210)
                    Text("Сохраняем полученное во «Входящие»")
                        .font(.subheadline.weight(.medium))
                }
                .padding(22)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                .shadow(radius: 18)
            }
        }
        .overlay(alignment: .bottom) {
            if !lastSharedImportIDs.isEmpty {
                ImportUndoToast(count: lastSharedImportIDs.count, undo: undoSharedImport)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 86)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .alert("Импорт из другого приложения", isPresented: sharedImportMessageBinding) {
            Button("ОК", role: .cancel) { sharedImporter.errorMessage = nil }
        } message: {
            Text(sharedImporter.errorMessage ?? "")
        }
        .task { seedAppStorePreviewIfNeeded() }
        .task { await importSharedItemsIfNeeded() }
        .task { await refreshMissingLinkPreviews() }
        .task(id: lastSharedImportIDs) {
            guard !lastSharedImportIDs.isEmpty else { return }
            try? await Task.sleep(for: .seconds(6))
            withAnimation { lastSharedImportIDs = [] }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await importSharedItemsIfNeeded() } }
        }
        .onChange(of: folderSignature, initial: true) { _, _ in
            SharedImportQueue.publishFolderCatalog(folders)
        }
    }

    @MainActor
    private func seedAppStorePreviewIfNeeded() {
        guard ProcessInfo.processInfo.arguments.contains("-AppStoreScreenshots"),
              folders.isEmpty else { return }
        AppStorePreviewData.seed(in: context)
    }

    private var sharedImportMessageBinding: Binding<Bool> {
        Binding(
            get: { sharedImporter.errorMessage != nil },
            set: { if !$0 { sharedImporter.errorMessage = nil } }
        )
    }

    @discardableResult
    private func ensureInbox() -> VaultFolder {
        if let inbox = folders.first(where: \.isSystem) { return inbox }
        let inbox = VaultFolder(
            name: "Входящие",
            colorIdentifier: "purple",
            symbolName: "tray.full.fill",
            sortOrder: -1_000,
            isSystem: true
        )
        context.insert(inbox)
        try? context.save()
        return inbox
    }

    private func importSharedItemsIfNeeded() async {
        guard !sharedImporter.isImporting else { return }
        let pending = SharedImportQueue.pendingFiles()
        guard !pending.isEmpty else {
            _ = ensureInbox()
            return
        }
        let inbox = ensureInbox()
        let grouped = Dictionary(grouping: pending) { SharedImportQueue.destinationFolderID(for: $0) }
        var importedIDs: [UUID] = []
        for (destinationID, urls) in grouped {
            let destination = destinationID.flatMap { id in
                folders.first(where: { $0.id == id })
            } ?? inbox
            await sharedImporter.importFiles(
                urls,
                into: destination,
                context: context,
                removeSourcesAfterImport: true
            )
            importedIDs.append(contentsOf: sharedImporter.importedItemIDs)
        }
        if !importedIDs.isEmpty {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                lastSharedImportIDs = importedIDs
            }
        }
    }

    private func undoSharedImport() {
        let imported = Set(lastSharedImportIDs)
        let descriptor = FetchDescriptor<VaultMediaItem>()
        let items = ((try? context.fetch(descriptor)) ?? []).filter { imported.contains($0.id) }
        items.forEach { VaultOperations.delete($0, in: context) }
        withAnimation { lastSharedImportIDs = [] }
    }

    private func refreshMissingLinkPreviews() async {
        guard !ProcessInfo.processInfo.arguments.contains("-AppStoreScreenshots") else { return }
        let links = allItems.filter {
            $0.mediaType == .link && $0.thumbnailFileName.isEmpty
        }.prefix(5)
        for item in links {
            await LinkMetadataService.enrich(item, context: context)
        }
    }
}

private struct ImportUndoToast: View {
    let count: Int
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(count == 1 ? "Материал сохранён" : "Сохранено: \(count)")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button("Отменить", action: undo)
                .font(.subheadline.bold())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.35), lineWidth: 1) }
        .shadow(color: .black.opacity(0.16), radius: 18, y: 8)
    }
}

private struct VaultTabBar: View {
    @Binding var selection: VaultTab
    let add: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.folders)
                Color.clear.frame(width: 68, height: 1)
                tabButton(.favorites)
                tabButton(.profile)
            }
            .padding(.horizontal, 8)
            .padding(.top, 13)
            .padding(.bottom, 7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.38), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.12), radius: 22, y: 8)

            Button(action: add) {
                Image(systemName: "plus")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.28, blue: 1), Color(red: 0.20, green: 0.22, blue: 0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .overlay { Circle().stroke(.white.opacity(0.45), lineWidth: 1) }
                    .shadow(color: VaultPalette.purple.opacity(0.38), radius: 13, y: 7)
            }
            .offset(y: -18)
            .accessibilityLabel("Добавить фото, видео или файл")
            .accessibilityIdentifier("globalImportButton")
        }
        .padding(.horizontal, 12)
        .padding(.top, 20)
        .background(Color.clear)
    }

    private func tabButton(_ tab: VaultTab) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolEffect(.bounce, value: selection == tab)
                Text(tab.title)
                    .font(.system(size: 10.5, weight: selection == tab ? .semibold : .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(selection == tab ? VaultPalette.purple : .secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tab_\(tab.rawValue)")
    }
}

private struct HomeDashboardView: View {
    @Query(sort: \VaultFolder.sortOrder) private var folders: [VaultFolder]
    @Query(sort: \VaultMediaItem.createdAt, order: .reverse) private var allItems: [VaultMediaItem]
    @Query(sort: \VaultNote.updatedAt, order: .reverse) private var notes: [VaultNote]
    @State private var viewerItem: VaultMediaItem?
    let openImport: () -> Void

    private var activeItems: [VaultMediaItem] { allItems.filter { !$0.isArchived } }
    private var favoriteItems: [VaultMediaItem] { activeItems.filter(\.isFavorite) }
    private var recentItems: [VaultMediaItem] { Array(activeItems.prefix(4)) }
    private var inboxFolder: VaultFolder? { folders.first(where: \.isSystem) }
    private var inboxCount: Int { inboxFolder?.items.filter { !$0.isArchived }.count ?? 0 }
    private var memoryItem: VaultMediaItem? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let eligible = activeItems.filter { $0.createdAt < cutoff && $0.folder?.isSystem != true }
        guard !eligible.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return eligible[day % eligible.count]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VaultAmbientBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        dashboardHeader
                        favoritesHero
                        rememberSection
                        recentSection
                        notesSection
                        foldersSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 26)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(item: $viewerItem) { item in
                MediaViewer(items: activeItems, initialItemID: item.id)
            }
        }
    }

    @ViewBuilder
    private var rememberSection: some View {
        if inboxCount > 0 || memoryItem != nil {
            DashboardSection(title: "Не забыть", symbol: "sparkles") {
                VStack(spacing: 0) {
                    if let inboxFolder, inboxCount > 0 {
                        NavigationLink { FolderView(folder: inboxFolder) } label: {
                            RememberRow(
                                symbol: "tray.full.fill",
                                color: VaultPalette.purple,
                                title: "Разобрать входящие",
                                subtitle: inboxCount.formattedItems
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    if inboxCount > 0, memoryItem != nil {
                        Divider().padding(.leading, 70)
                    }

                    if let memoryItem {
                        Button { viewerItem = memoryItem } label: {
                            HStack(spacing: 12) {
                                AsyncThumbnailView(item: memoryItem)
                                    .frame(width: 48, height: 48)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Вспомнить сохранённое")
                                        .font(.subheadline.weight(.semibold))
                                    Text(memoryItem.title.isEmpty ? (memoryItem.folder?.name ?? "Старая идея") : memoryItem.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .vaultGlassCard()
            }
        }
    }

    private var dashboardHeader: some View {
        HStack(spacing: 12) {
            Image("VaultMark")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 40)
            VStack(alignment: .leading, spacing: 1) {
                Text("VAULT")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                Text("Ваше визуальное пространство")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: openImport) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 43, height: 43)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .accessibilityLabel("Импортировать")
        }
    }

    private var favoritesHero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Моё избранное")
                        .font(.title2.bold())
                    Text("\(favoriteItems.count) вдохновляющих материалов")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.76))
                }
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
            }

            if let item = favoriteItems.first ?? activeItems.first {
                Button { viewerItem = item } label: {
                    HStack(spacing: 13) {
                        AsyncThumbnailView(item: item)
                            .frame(width: 94, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title.isEmpty ? (item.folder?.name ?? "Сохранённая идея") : item.title)
                                .font(.headline)
                                .lineLimit(1)
                            Text(item.caption.isEmpty ? "Откройте и добавьте описание" : item.caption)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.subheadline.bold())
                    }
                    .padding(11)
                    .foregroundStyle(.primary)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                Button(action: openImport) {
                    Label("Добавить первую идею", systemImage: "photo.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.36, green: 0.35, blue: 0.96), Color(red: 0.28, green: 0.22, blue: 0.88)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            Circle().fill(.white.opacity(0.08)).frame(width: 170).offset(x: 55, y: -75)
        }
        .shadow(color: VaultPalette.purple.opacity(0.24), radius: 22, y: 12)
    }

    @ViewBuilder
    private var recentSection: some View {
        if !recentItems.isEmpty {
            DashboardSection(title: "Недавно добавлено", symbol: "clock") {
                VStack(spacing: 0) {
                    ForEach(Array(recentItems.enumerated()), id: \.element.id) { index, item in
                        Button { viewerItem = item } label: {
                            MediaDashboardRow(item: item)
                        }
                        .buttonStyle(.plain)
                        if index < recentItems.count - 1 { Divider().padding(.leading, 72) }
                    }
                }
                .padding(10)
                .vaultGlassCard()
            }
        }
    }

    private var notesSection: some View {
        DashboardSection(title: "Заметки", symbol: "note.text") {
            NavigationLink {
                NotesView()
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "square.and.pencil")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(VaultPalette.purple.gradient, in: RoundedRectangle(cornerRadius: 15))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(notes.first?.displayTitle ?? "Запишите важную мысль")
                            .font(.headline)
                            .lineLimit(1)
                        Text(notes.isEmpty ? "Идеи, списки и детали всегда под рукой" : "Всего заметок: \(notes.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                .padding(15)
                .vaultGlassCard()
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var foldersSection: some View {
        let visible = folders.filter { !$0.isSystem }.prefix(3)
        if !visible.isEmpty {
            DashboardSection(title: "Коллекции", symbol: "folder") {
                VStack(spacing: 10) {
                    ForEach(Array(visible)) { folder in
                        NavigationLink { FolderView(folder: folder) } label: {
                            HStack(spacing: 13) {
                                Image(systemName: folder.symbolName)
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(VaultPalette.color(for: folder.colorIdentifier).gradient, in: RoundedRectangle(cornerRadius: 13))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(folder.name).font(.headline)
                                    Text("\(folder.items.filter { !$0.isArchived }.count) материалов")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .vaultGlassCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct RememberRow: View {
    let symbol: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .contentShape(Rectangle())
    }
}

private struct DashboardSection<Content: View>: View {
    let title: String
    let symbol: String
    let content: Content

    init(title: String, symbol: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Label(title, systemImage: symbol)
                .font(.title3.bold())
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MediaDashboardRow: View {
    let item: VaultMediaItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncThumbnailView(item: item)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title.isEmpty ? (item.folder?.name ?? "Материал") : item.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(item.caption.isEmpty ? item.createdAt.formatted(date: .abbreviated, time: .omitted) : item.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if item.isFavorite { Image(systemName: "star.fill").foregroundStyle(.yellow) }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

struct FavoritesGalleryView: View {
    @Query(sort: \VaultMediaItem.createdAt, order: .reverse) private var allItems: [VaultMediaItem]
    @State private var viewerItem: VaultMediaItem?
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    private var items: [VaultMediaItem] { allItems.filter { $0.isFavorite && !$0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                VaultAmbientBackground()
                if items.isEmpty {
                    ContentUnavailableView(
                        "Здесь будет любимое",
                        systemImage: "star",
                        description: Text("Отмечайте материалы звёздочкой — они появятся в этой коллекции.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(items) { item in
                                Button { viewerItem = item } label: {
                                    FavoriteMediaCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(18)
                        .padding(.bottom, 22)
                    }
                }
            }
            .navigationTitle("Избранное")
            .fullScreenCover(item: $viewerItem) { item in
                MediaViewer(items: items, initialItemID: item.id)
            }
        }
    }
}

private struct FavoriteMediaCard: View {
    let item: VaultMediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .topTrailing) {
                AsyncThumbnailView(item: item)
                    .frame(height: 154)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .padding(9)
                    .background(.ultraThinMaterial, in: Circle())
                    .padding(8)
            }
            Text(item.title.isEmpty ? (item.folder?.name ?? "Сохранённая идея") : item.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            if !item.caption.isEmpty {
                Text(item.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .vaultGlassCard(cornerRadius: 23)
    }
}

struct NotesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \VaultNote.updatedAt, order: .reverse) private var notes: [VaultNote]
    @State private var editedNote: VaultNote?
    @State private var showsNewNote = false

    private var sortedNotes: [VaultNote] {
        notes.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.updatedAt > $1.updatedAt
        }
    }

    var body: some View {
        ZStack {
            VaultAmbientBackground()
            if notes.isEmpty {
                ContentUnavailableView {
                    Label("Ни одной заметки", systemImage: "note.text")
                } description: {
                    Text("Сохраняйте мысли, списки и идеи отдельно от фотографий.")
                } actions: {
                    Button("Создать заметку") { showsNewNote = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedNotes) { note in
                            Button { editedNote = note } label: {
                                NoteCard(note: note)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(note.isPinned ? "Открепить" : "Закрепить") {
                                    note.isPinned.toggle()
                                    note.updatedAt = .now
                                    try? context.save()
                                }
                                Button("Удалить", role: .destructive) {
                                    context.delete(note)
                                    try? context.save()
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
        }
        .navigationTitle("Заметки")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showsNewNote = true } label: { Image(systemName: "square.and.pencil") }
            }
        }
        .sheet(isPresented: $showsNewNote) { NoteEditorSheet() }
        .sheet(item: $editedNote) { note in NoteEditorSheet(note: note) }
    }
}

private struct NoteCard: View {
    let note: VaultNote

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: note.isPinned ? "pin.fill" : "note.text")
                .foregroundStyle(.white)
                .frame(width: 43, height: 43)
                .background(VaultPalette.color(for: note.colorIdentifier).gradient, in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 5) {
                Text(note.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                Text(note.body.isEmpty ? "Пустая заметка" : note.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .vaultGlassCard()
    }
}

private struct NoteEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let note: VaultNote?

    @State private var title: String
    @State private var bodyText: String
    @State private var isPinned: Bool
    @State private var colorIdentifier: String

    init(note: VaultNote? = nil) {
        self.note = note
        _title = State(initialValue: note?.title ?? "")
        _bodyText = State(initialValue: note?.body ?? "")
        _isPinned = State(initialValue: note?.isPinned ?? false)
        _colorIdentifier = State(initialValue: note?.colorIdentifier ?? "purple")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название заметки", text: $title)
                        .font(.headline)
                    TextField("Начните писать…", text: $bodyText, axis: .vertical)
                        .lineLimit(10...22)
                }
                Section("Оформление") {
                    Toggle("Закрепить", isOn: $isPinned)
                    HStack {
                        ForEach(VaultPalette.colors, id: \.id) { option in
                            Button { colorIdentifier = option.id } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if colorIdentifier == option.id {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(note == nil ? "Новая заметка" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Сохранить", action: save) }
            }
        }
    }

    private func save() {
        let target = note ?? VaultNote()
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.body = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        target.isPinned = isPinned
        target.colorIdentifier = colorIdentifier
        target.updatedAt = .now
        if note == nil { context.insert(target) }
        try? context.save()
        dismiss()
    }
}

private struct ProfileView: View {
    @Query private var folders: [VaultFolder]
    @Query private var items: [VaultMediaItem]
    @Query private var notes: [VaultNote]

    var body: some View {
        NavigationStack {
            ZStack {
                VaultAmbientBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 11) {
                            ZStack {
                                Circle().fill(VaultPalette.purple.opacity(0.12)).frame(width: 94, height: 94)
                                Image("VaultMark").resizable().scaledToFit().frame(width: 68, height: 56)
                            }
                            Text("Мой VAULT").font(.title2.bold())
                            Text("Личное пространство для идей")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        HStack(spacing: 10) {
                            ProfileStat(value: folders.filter { !$0.isSystem }.count, title: "Папки", symbol: "folder.fill")
                            ProfileStat(value: items.filter { !$0.isArchived }.count, title: "Материалы", symbol: "photo.fill")
                            ProfileStat(value: notes.count, title: "Заметки", symbol: "note.text")
                        }

                        VStack(spacing: 0) {
                            NavigationLink { NotesView() } label: {
                                ProfileRow(title: "Мои заметки", subtitle: "Идеи и списки", symbol: "note.text", color: .orange)
                            }
                            Divider().padding(.leading, 62)
                            NavigationLink { SettingsView() } label: {
                                ProfileRow(title: "Настройки", subtitle: "Тема, Face ID и хранилище", symbol: "gearshape.fill", color: VaultPalette.purple)
                            }
                        }
                        .buttonStyle(.plain)
                        .vaultGlassCard()

                        Label("Все материалы VAULT хранятся локально на устройстве", systemImage: "lock.shield.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .padding(18)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Профиль")
        }
    }
}

private struct ProfileStat: View {
    let value: Int
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: symbol).foregroundStyle(VaultPalette.purple)
            Text("\(value)").font(.title3.bold())
            Text(title).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .vaultGlassCard(cornerRadius: 18)
    }
}

private struct ProfileRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(14)
        .contentShape(Rectangle())
    }
}

private struct VaultAmbientBackground: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
            Circle()
                .fill(Color.blue.opacity(0.09))
                .frame(width: 300, height: 300)
                .blur(radius: 45)
                .offset(x: 150, y: -270)
            Circle()
                .fill(VaultPalette.purple.opacity(0.08))
                .frame(width: 340, height: 340)
                .blur(radius: 55)
                .offset(x: -150, y: 310)
        }
        .ignoresSafeArea()
    }
}

private extension View {
    func vaultGlassCard(cornerRadius: CGFloat = 20) -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.32), lineWidth: 0.8)
            }
            .shadow(color: .black.opacity(0.055), radius: 15, y: 7)
    }
}
