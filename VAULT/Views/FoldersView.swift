import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private enum GlobalSearchScope: String, CaseIterable, Hashable {
    case everywhere
    case source
    case recognizedText

    var title: String {
        switch self {
        case .everywhere: "Везде"
        case .source: "В источнике"
        case .recognizedText: "Текст на изображении"
        }
    }
}

private enum GlobalSearchType: String, CaseIterable, Hashable {
    case all
    case photos
    case videos
    case links

    var title: String {
        switch self {
        case .all: "Все типы"
        case .photos: "Фото"
        case .videos: "Видео"
        case .links: "Ссылки"
        }
    }
}

private enum GlobalSearchPeriod: String, CaseIterable, Hashable {
    case anytime
    case week
    case month
    case year

    var title: String {
        switch self {
        case .anytime: "За всё время"
        case .week: "Последняя неделя"
        case .month: "Последний месяц"
        case .year: "Последний год"
        }
    }

    var cutoff: Date? {
        let days: Int
        switch self {
        case .anytime: return nil
        case .week: days = -7
        case .month: days = -30
        case .year: days = -365
        }
        return Calendar.current.date(byAdding: .day, value: days, to: .now)
    }
}

struct FoldersView: View {
    @Query(sort: \VaultFolder.sortOrder) private var folders: [VaultFolder]
    @Query(sort: \VaultMediaItem.createdAt, order: .reverse) private var allItems: [VaultMediaItem]

    @State private var showsCreateFolder = false
    @State private var showsQuickImport = false
    @State private var searchText = ""
    @State private var searchScope = GlobalSearchScope.everywhere
    @State private var searchType = GlobalSearchType.all
    @State private var searchPeriod = GlobalSearchPeriod.anytime

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    private var visibleFolders: [VaultFolder] {
        folders.sorted {
            if $0.isSystem != $1.isSystem { return $0.isSystem }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private var searchResults: [VaultMediaItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return allItems.filter { item in
            guard !item.isArchived else { return false }
            if let cutoff = searchPeriod.cutoff, item.createdAt < cutoff { return false }

            let matchesType: Bool
            switch searchType {
            case .all: matchesType = true
            case .photos: matchesType = item.mediaType == .photo
            case .videos: matchesType = item.mediaType == .video
            case .links: matchesType = item.mediaType == .link
            }
            guard matchesType else { return false }
            if query.isEmpty {
                switch searchScope {
                case .everywhere: return true
                case .source: return !item.sourceURLString.isEmpty
                case .recognizedText: return !item.recognizedText.isEmpty
                }
            }

            switch searchScope {
            case .everywhere:
                return item.searchableText.contains(query) ||
                    (item.folder?.name.lowercased().contains(query) ?? false)
            case .source:
                return item.sourceURLString.lowercased().contains(query)
            case .recognizedText:
                return item.recognizedText.lowercased().contains(query)
            }
        }
    }

    private var isSearchMode: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            searchScope != .everywhere || searchType != .all || searchPeriod != .anytime
    }

    private var searchFilterSummary: String {
        var parts: [String] = []
        if searchScope != .everywhere { parts.append(searchScope.title) }
        if searchType != .all { parts.append(searchType.title) }
        if searchPeriod != .anytime { parts.append(searchPeriod.title) }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSearchMode {
                    GlobalSearchResults(
                        items: searchResults,
                        query: searchText,
                        filterSummary: searchFilterSummary
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            CaptureBanner { showsQuickImport = true }

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
                    Menu {
                        Picker("Область поиска", selection: $searchScope) {
                            ForEach(GlobalSearchScope.allCases, id: \.rawValue) { Text($0.title).tag($0) }
                        }
                        Picker("Тип материала", selection: $searchType) {
                            ForEach(GlobalSearchType.allCases, id: \.rawValue) { Text($0.title).tag($0) }
                        }
                        Picker("Период", selection: $searchPeriod) {
                            ForEach(GlobalSearchPeriod.allCases, id: \.rawValue) { Text($0.title).tag($0) }
                        }
                        if isSearchMode {
                            Divider()
                            Button("Сбросить фильтры", role: .destructive) { resetSearchFilters() }
                        }
                    } label: {
                        Image(systemName: isSearchMode ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Фильтры поиска")
                    .accessibilityIdentifier("searchFilterButton")

                    Button {
                        showsQuickImport = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Быстро добавить материалы")
                    .accessibilityIdentifier("quickImportButton")

                    Button {
                        showsCreateFolder = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                    .accessibilityLabel("Создать папку")
                    .accessibilityIdentifier("createFolderButton")

                }
            }
            .sheet(isPresented: $showsCreateFolder) {
                FolderEditorSheet(
                    mode: .create,
                    nextSortOrder: (folders.map(\.sortOrder).max() ?? -1) + 1
                )
            }
            .sheet(isPresented: $showsQuickImport) {
                QuickImportSheet()
            }
        }
    }

    private func resetSearchFilters() {
        searchScope = .everywhere
        searchType = .all
        searchPeriod = .anytime
    }
}

private struct CaptureBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(.white.opacity(0.18)).frame(width: 54, height: 54)
                    Image(systemName: "photo.badge.plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Сохранить новую идею")
                        .font(.headline)
                    Text("Фото, видео или файл — сразу в нужную коллекцию")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(17)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.63, green: 0.34, blue: 1), Color(red: 0.36, green: 0.08, blue: 0.84)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .shadow(color: VaultPalette.purple.opacity(0.22), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct QuickImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \VaultFolder.sortOrder) private var folders: [VaultFolder]

    @State private var selectedFolderID: UUID?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showsFileImporter = false
    @State private var linkText = ""
    @State private var importer = MediaImportViewModel()

    private var destination: VaultFolder? {
        folders.first(where: { $0.id == selectedFolderID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Куда сохранить") {
                    Picker("Папка", selection: $selectedFolderID) {
                        ForEach(folders.sorted(by: {
                            if $0.isSystem != $1.isSystem { return $0.isSystem }
                            return $0.sortOrder < $1.sortOrder
                        })) { folder in
                            Label(folder.name, systemImage: folder.symbolName)
                                .tag(Optional(folder.id))
                        }
                    }
                }

                Section("Источник") {
                    PhotosPicker(
                        selection: $pickerItems,
                        maxSelectionCount: 50,
                        matching: .any(of: [.images, .videos])
                    ) {
                        ImportSourceRow(
                            title: "Выбрать из Фото",
                            subtitle: "Несколько фотографий или видео",
                            symbol: "photo.on.rectangle.angled",
                            color: .purple
                        )
                    }
                    .disabled(destination == nil || importer.isImporting)

                    Button { showsFileImporter = true } label: {
                        ImportSourceRow(
                            title: "Импортировать из Files",
                            subtitle: "Изображения и видео из iCloud Drive или устройства",
                            symbol: "folder",
                            color: .blue
                        )
                    }
                    .disabled(destination == nil || importer.isImporting)
                }

                Section("Ссылка или Instagram Reel") {
                    TextField("https://instagram.com/reel/…", text: $linkText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack {
                        PasteButton(payloadType: String.self) { values in
                            if let value = values.first { linkText = value }
                        }
                        Spacer()
                        Button("Сохранить ссылку") {
                            guard let destination else { return }
                            if importer.importLink(linkText, into: destination, context: context) {
                                linkText = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(destination == nil || linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section {
                    Label("В Instagram или «Фото» нажмите «Поделиться» и выберите VAULT — файл или ссылка попадёт во «Входящие».", systemImage: "square.and.arrow.up")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Добавить в VAULT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } }
            }
            .overlay {
                if importer.isImporting {
                    VStack(spacing: 12) {
                        ProgressView(value: importer.progress).frame(width: 200)
                        Text("Импорт \(importer.completedCount) из \(importer.totalCount)")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(22)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
            }
            .onAppear {
                if selectedFolderID == nil {
                    selectedFolderID = folders.first(where: { $0.isSystem })?.id ?? folders.first?.id
                }
            }
            .onChange(of: pickerItems) { _, newValue in
                guard let destination, !newValue.isEmpty else { return }
                Task {
                    await importer.importItems(newValue, into: destination, context: context)
                    pickerItems = []
                }
            }
            .fileImporter(
                isPresented: $showsFileImporter,
                allowedContentTypes: [.image, .movie],
                allowsMultipleSelection: true
            ) { result in
                guard let destination, case .success(let urls) = result else { return }
                Task { await importer.importFiles(urls, into: destination, context: context) }
            }
            .alert("VAULT", isPresented: importMessageBinding) {
                Button("ОК", role: .cancel) { importer.errorMessage = nil }
            } message: {
                Text(importer.errorMessage ?? "")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var importMessageBinding: Binding<Bool> {
        Binding(get: { importer.errorMessage != nil }, set: { if !$0 { importer.errorMessage = nil } })
    }
}

private struct ImportSourceRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
            }
        }
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
    let filterSummary: String
    @State private var viewerItem: VaultMediaItem?

    var body: some View {
        List {
            if !filterSummary.isEmpty {
                Label(filterSummary, systemImage: "line.3.horizontal.decrease.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(VaultPalette.purple)
            }
            ForEach(items) { item in
                Button { viewerItem = item } label: {
                HStack(spacing: 12) {
                    AsyncThumbnailView(item: item)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title.isEmpty ? (item.folder?.name ?? "Материал") : item.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(item.caption.isEmpty ? (item.folder?.name ?? "Без папки") : item.caption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        HStack(spacing: 7) {
                            Label(item.mediaType.searchTitle, systemImage: item.mediaType.searchSymbol)
                            if let host = URL(string: item.sourceURLString)?.host {
                                Text(host.replacingOccurrences(of: "www.", with: ""))
                                .lineLimit(1)
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(VaultPalette.purple)
                    }
                }
            }
                .buttonStyle(.plain)
            }
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

private extension VaultMediaType {
    var searchTitle: String {
        switch self {
        case .photo: "Фото"
        case .video: "Видео"
        case .link: "Ссылка"
        }
    }

    var searchSymbol: String {
        switch self {
        case .photo: "photo"
        case .video: "video"
        case .link: "link"
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
