import PhotosUI
import SwiftData
import SwiftUI
import UIKit

private enum FolderDisplayMode: String, CaseIterable, Equatable {
    case grid
    case list
    case board

    var title: String {
        switch self {
        case .grid: "Сетка"
        case .list: "Список"
        case .board: "Доска"
        }
    }

    var symbol: String {
        switch self {
        case .grid: "square.grid.3x3"
        case .list: "list.bullet"
        case .board: "rectangle.3.group"
        }
    }
}

private enum FolderFilter: String, CaseIterable, Equatable {
    case all
    case favorites
    case photos
    case videos
    case links
    case archived

    var title: String {
        switch self {
        case .all: "Все"
        case .favorites: "Избранное"
        case .photos: "Фото"
        case .videos: "Видео"
        case .links: "Ссылки"
        case .archived: "Архив"
        }
    }
}

struct FolderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \VaultFolder.sortOrder) private var allFolders: [VaultFolder]

    let folder: VaultFolder

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var importer = MediaImportViewModel()
    @State private var viewerItem: VaultMediaItem?
    @State private var metadataItem: VaultMediaItem?
    @State private var isSelecting = false
    @State private var selection = Set<UUID>()
    @State private var showsEdit = false
    @State private var showsMove = false
    @State private var showsArrange = false
    @State private var showsDeleteItems = false
    @State private var showsDeleteFolder = false
    @State private var displayMode: FolderDisplayMode = .grid
    @State private var filter: FolderFilter = .all
    @State private var searchText = ""
    @State private var shareItems: [Any] = []
    @State private var showsShareSheet = false
    @State private var exportError: String?
    @State private var didConfigureInbox = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    private var sortedItems: [VaultMediaItem] {
        folder.items.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var visibleItems: [VaultMediaItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return sortedItems.filter { item in
            let matchesFilter: Bool
            switch filter {
            case .all: matchesFilter = !item.isArchived
            case .favorites: matchesFilter = item.isFavorite && !item.isArchived
            case .photos: matchesFilter = item.mediaType == .photo && !item.isArchived
            case .videos: matchesFilter = item.mediaType == .video && !item.isArchived
            case .links: matchesFilter = item.mediaType == .link && !item.isArchived
            case .archived: matchesFilter = item.isArchived
            }
            return matchesFilter && (query.isEmpty || item.searchableText.contains(query))
        }
    }

    private var selectedItems: [VaultMediaItem] {
        sortedItems.filter { selection.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if folder.isSystem && !sortedItems.filter({ !$0.isArchived }).isEmpty {
                InboxTriageHeader(
                    count: sortedItems.filter { !$0.isArchived }.count,
                    selectAll: selectAllVisible
                )
            }

            Group {
                if sortedItems.filter({ !$0.isArchived }).isEmpty && filter != .archived {
                    emptyState
                } else if visibleItems.isEmpty {
                    ContentUnavailableView.search(text: searchText.isEmpty ? filter.title : searchText)
                } else {
                    switch displayMode {
                    case .grid: gridContent
                    case .list: listContent
                    case .board: boardContent
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Текст, тег или заметка")
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) {
            if isSelecting { selectionBar }
        }
        .overlay {
            if importer.isImporting { importOverlay }
        }
        .onChange(of: pickerItems) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task {
                await importer.importItems(newValue, into: folder, context: context)
                pickerItems = []
            }
        }
        .alert("Импорт завершён", isPresented: importerMessageBinding) {
            Button("ОК", role: .cancel) { importer.errorMessage = nil }
        } message: {
            Text(importer.errorMessage ?? "")
        }
        .alert("Удалить выбранные материалы?", isPresented: $showsDeleteItems) {
            Button("Удалить", role: .destructive) { deleteSelected() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Файлы будут удалены без возможности восстановления.")
        }
        .alert("Удалить папку?", isPresented: $showsDeleteFolder) {
            Button("Удалить", role: .destructive) {
                VaultOperations.delete(folder, in: context)
                dismiss()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Папка и все сохранённые в ней материалы будут удалены без возможности восстановления.")
        }
        .alert("Не удалось подготовить подборку", isPresented: exportErrorBinding) {
            Button("ОК", role: .cancel) { exportError = nil }
        } message: {
            Text(exportError ?? "")
        }
        .sheet(isPresented: $showsEdit) {
            FolderEditorSheet(mode: .edit(folder))
        }
        .sheet(item: $metadataItem) { item in
            MediaMetadataSheet(item: item)
        }
        .sheet(isPresented: $showsMove) {
            MoveItemsSheet(items: selectedItems, currentFolder: folder) { endSelection() }
        }
        .sheet(isPresented: $showsArrange) {
            ArrangeItemsSheet(folder: folder)
        }
        .sheet(isPresented: $showsShareSheet) {
            ActivityView(activityItems: shareItems)
        }
        .fullScreenCover(item: $viewerItem) { item in
            MediaViewer(items: visibleItems, initialItemID: item.id)
        }
        .onAppear {
            guard folder.isSystem, !didConfigureInbox else { return }
            displayMode = .list
            didConfigureInbox = true
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Здесь пока ничего нет", systemImage: "photo.on.rectangle.angled")
        } description: {
            Text(folder.isSystem
                 ? "Сохраняйте сюда новые материалы, а затем распределяйте их по коллекциям"
                 : "Добавьте фотографии и видео из галереи iPhone")
        } actions: {
            PhotosPicker(
                selection: $pickerItems,
                maxSelectionCount: 50,
                matching: .any(of: [.images, .videos])
            ) {
                Text("Добавить фото и видео")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(importer.isImporting)
        }
        .accessibilityIdentifier("folderEmptyState")
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(visibleItems) { item in
                    mediaButton(item) {
                        AsyncThumbnailView(item: item)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private var listContent: some View {
        List(visibleItems) { item in
            mediaButton(item) {
                MediaListRow(item: item)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button { toggleFavorite(item) } label: {
                    Label(item.isFavorite ? "Убрать" : "Избранное", systemImage: item.isFavorite ? "star.slash" : "star.fill")
                }
                .tint(.yellow)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if folder.isSystem, let suggestion = suggestedFolder(for: item) {
                    Button { move(item, to: suggestion) } label: {
                        Label(suggestion.name, systemImage: "folder.fill")
                    }
                    .tint(VaultPalette.color(for: suggestion.colorIdentifier))
                }
                if folder.isSystem {
                    Button { chooseDestination(for: item) } label: {
                        Label("Другая папка", systemImage: "folder.badge.plus")
                    }
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }

    private var boardContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                ForEach(boardStatuses, id: \.self) { status in
                    let statusItems = visibleItems.filter { $0.statusRaw == status }
                    if !statusItems.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(status.isEmpty ? "Без статуса" : status)
                                .font(.headline)
                                .padding(.horizontal, 16)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(statusItems) { item in
                                        mediaButton(item) {
                                            MediaBoardCard(item: item)
                                        }
                                        .frame(width: 156)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }

    private var boardStatuses: [String] {
        let configured = folder.template.statuses
        let custom = Set(visibleItems.map(\.statusRaw).filter { !$0.isEmpty && !configured.contains($0) })
        return configured + custom.sorted() + [""]
    }

    private func mediaButton<Content: View>(_ item: VaultMediaItem, @ViewBuilder content: () -> Content) -> some View {
        Button {
            if isSelecting { toggleSelection(item) } else { viewerItem = item }
        } label: {
            ZStack(alignment: .topTrailing) {
                content()
                if item.isFavorite && !isSelecting {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                        .padding(7)
                        .shadow(color: .black.opacity(0.45), radius: 2)
                }
                if isSelecting {
                    Image(systemName: selection.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, selection.contains(item.id) ? VaultPalette.purple : .black.opacity(0.35))
                        .padding(7)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            if folder.isSystem, let suggestion = suggestedFolder(for: item) {
                Button { move(item, to: suggestion) } label: {
                    Label("В папку «\(suggestion.name)»", systemImage: "folder.fill")
                }
            }
            if folder.isSystem {
                Button { chooseDestination(for: item) } label: {
                    Label("Выбрать другую папку", systemImage: "folder.badge.plus")
                }
            }
            Button { toggleFavorite(item) } label: {
                Label(item.isFavorite ? "Убрать из избранного" : "В избранное", systemImage: item.isFavorite ? "star.slash" : "star")
            }
            Button { metadataItem = item } label: { Label("Описание и теги", systemImage: "info.circle") }
            Button { toggleArchive(item) } label: {
                Label(item.isArchived ? "Вернуть из архива" : "В архив", systemImage: "archivebox")
            }
            Button {
                isSelecting = true
                selection.insert(item.id)
            } label: {
                Label("Выбрать несколько", systemImage: "checkmark.circle")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isSelecting {
            ToolbarItem(placement: .topBarLeading) { Button("Готово") { endSelection() } }
            ToolbarItem(placement: .principal) { Text("Выбрано: \(selection.count)").font(.headline) }
        } else {
            ToolbarItemGroup(placement: .topBarTrailing) {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 50,
                    matching: .any(of: [.images, .videos])
                ) { Image(systemName: "plus") }
                .disabled(importer.isImporting)
                .accessibilityLabel("Добавить фото и видео")

                Menu {
                    Button { isSelecting = true } label: { Label("Выбрать", systemImage: "checkmark.circle") }

                    Menu("Вид") {
                        ForEach(FolderDisplayMode.allCases, id: \.rawValue) { mode in
                            Button { displayMode = mode } label: {
                                Label(mode.title, systemImage: displayMode == mode ? "checkmark" : mode.symbol)
                            }
                        }
                    }

                    Menu("Фильтр") {
                        ForEach(FolderFilter.allCases, id: \.rawValue) { option in
                            Button { filter = option } label: {
                                if filter == option { Label(option.title, systemImage: "checkmark") }
                                else { Text(option.title) }
                            }
                        }
                    }

                    Button { showsArrange = true } label: { Label("Изменить порядок", systemImage: "arrow.up.arrow.down") }
                    Button { export(sortedItems.filter { !$0.isArchived }) } label: { Label("Экспорт VAULT Pack", systemImage: "square.and.arrow.up") }

                    if !folder.isSystem {
                        Button { showsEdit = true } label: { Label("Редактировать папку", systemImage: "pencil") }
                        Button(role: .destructive) { showsDeleteFolder = true } label: { Label("Удалить папку", systemImage: "trash") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var selectionBar: some View {
        HStack {
            Button { export(selectedItems) } label: { Label("Поделиться", systemImage: "square.and.arrow.up") }
                .disabled(selection.isEmpty)
            Spacer()
            Button { showsMove = true } label: { Label("Переместить", systemImage: "folder") }
                .disabled(selection.isEmpty)
            Spacer()
            Button(role: .destructive) { showsDeleteItems = true } label: { Label("Удалить", systemImage: "trash") }
                .disabled(selection.isEmpty)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var importOverlay: some View {
        VStack(spacing: 14) {
            ProgressView(value: importer.progress).frame(width: 210)
            Text("Импорт \(importer.completedCount) из \(importer.totalCount)")
                .font(.subheadline.weight(.medium))
            Text("OCR и проверка дубликатов выполняются на устройстве")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .shadow(radius: 20)
    }

    private var importerMessageBinding: Binding<Bool> {
        Binding(get: { importer.errorMessage != nil }, set: { if !$0 { importer.errorMessage = nil } })
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })
    }

    private func toggleSelection(_ item: VaultMediaItem) {
        if selection.contains(item.id) { selection.remove(item.id) } else { selection.insert(item.id) }
    }

    private func toggleFavorite(_ item: VaultMediaItem) {
        item.isFavorite.toggle()
        try? context.save()
    }

    private func toggleArchive(_ item: VaultMediaItem) {
        item.isArchived.toggle()
        try? context.save()
    }

    private func deleteSelected() {
        selectedItems.forEach { VaultOperations.delete($0, in: context) }
        endSelection()
    }

    private func endSelection() {
        selection.removeAll()
        isSelecting = false
    }

    private func selectAllVisible() {
        isSelecting = true
        selection = Set(visibleItems.map(\.id))
    }

    private func suggestedFolder(for item: VaultMediaItem) -> VaultFolder? {
        InboxSuggestionService.suggestion(for: item, folders: allFolders)
    }

    private func move(_ item: VaultMediaItem, to destination: VaultFolder) {
        VaultOperations.move([item], to: destination, in: context)
    }

    private func chooseDestination(for item: VaultMediaItem) {
        selection = [item.id]
        showsMove = true
    }

    private func export(_ items: [VaultMediaItem]) {
        guard !items.isEmpty else { return }
        do {
            shareItems = try VaultPackExporter.activityItems(folder: folder, items: items)
            showsShareSheet = true
        } catch {
            exportError = "Проверьте, что локальные файлы доступны, и попробуйте ещё раз."
        }
    }
}

private struct InboxTriageHeader: View {
    let count: Int
    let selectAll: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray.full.fill")
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(VaultPalette.purple.gradient, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text("Разберите входящие")
                    .font(.subheadline.weight(.semibold))
                Text("Смахните карточку влево — VAULT предложит папку")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Button("Выбрать все", action: selectAll)
                .font(.caption.weight(.semibold))
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.thinMaterial)
        .accessibilityLabel("Во входящих \(count) материалов")
    }
}

private struct MediaListRow: View {
    let item: VaultMediaItem

    var body: some View {
        HStack(spacing: 12) {
            AsyncThumbnailView(item: item)
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title.isEmpty ? (item.originalFileName ?? "Материал") : item.title)
                    .font(.headline)
                    .lineLimit(2)
                if !item.caption.isEmpty {
                    Text(item.caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !item.statusRaw.isEmpty {
                    Text(item.statusRaw)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(VaultPalette.purple)
                }
                if !item.tags.isEmpty {
                    Text(item.tags.prefix(3).map { "#\($0)" }.joined(separator: "  "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if item.rating > 0 {
                Label("\(item.rating)", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
            }
        }
        .contentShape(Rectangle())
    }
}

private struct MediaBoardCard: View {
    let item: VaultMediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncThumbnailView(item: item)
                .frame(height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 13))
            Text(item.title.isEmpty ? "Материал" : item.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            if !item.caption.isEmpty {
                Text(item.caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if !item.tags.isEmpty {
                Text(item.tags.prefix(2).map { "#\($0)" }.joined(separator: "  "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct MediaMetadataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: VaultMediaItem

    @State private var title: String
    @State private var caption: String
    @State private var note: String
    @State private var tagsText: String
    @State private var sourceURL: String
    @State private var status: String
    @State private var rating: Int
    @State private var priceText: String
    @State private var isFavorite: Bool
    @State private var isArchived: Bool

    init(item: VaultMediaItem) {
        self.item = item
        _title = State(initialValue: item.title)
        _caption = State(initialValue: item.caption)
        _note = State(initialValue: item.note)
        _tagsText = State(initialValue: item.tags.joined(separator: ", "))
        _sourceURL = State(initialValue: item.sourceURLString)
        _status = State(initialValue: item.statusRaw)
        _rating = State(initialValue: item.rating)
        _priceText = State(initialValue: item.price.map { String(format: "%.2f", $0) } ?? "")
        _isFavorite = State(initialValue: item.isFavorite)
        _isArchived = State(initialValue: item.isArchived)
    }

    private var template: VaultFolderTemplate { item.folder?.template ?? .general }

    var body: some View {
        NavigationStack {
            Form {
                Section("Название и описание") {
                    TextField("Название", text: $title)
                    TextField("Короткое описание для карточки", text: $caption, axis: .vertical)
                        .lineLimit(3...7)
                }

                Section("Личная заметка") {
                    TextField("Мысли, детали, что сделать позже…", text: $note, axis: .vertical)
                        .lineLimit(4...10)
                    TextField("Теги через запятую", text: $tagsText)
                        .textInputAutocapitalization(.never)
                }

                Section("Источник") {
                    TextField("https://…", text: $sourceURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if let url = URL(string: sourceURL), !sourceURL.isEmpty {
                        Link("Открыть источник", destination: url)
                    }
                }

                if !template.statuses.isEmpty {
                    Section(template.title) {
                        Picker("Статус", selection: $status) {
                            Text("Без статуса").tag("")
                            ForEach(template.statuses, id: \.self) { Text($0).tag($0) }
                        }
                        if template == .purchases {
                            TextField("Цена", text: $priceText)
                                .keyboardType(.decimalPad)
                        }
                    }
                }

                Section("Оценка") {
                    Stepper("\(rating) из 5", value: $rating, in: 0...5)
                    Toggle("Избранное", isOn: $isFavorite)
                    Toggle("В архиве", isOn: $isArchived)
                }

                if !item.recognizedText.isEmpty {
                    Section("Распознанный текст") {
                        Text(item.recognizedText)
                            .font(.footnote)
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Карточка материала")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Сохранить") { save() } }
            }
        }
    }

    private func save() {
        item.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.caption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        item.tags = tagsText.split(separator: ",").map(String.init)
        item.sourceURLString = sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)
        item.statusRaw = status
        item.rating = rating
        item.price = Double(priceText.replacingOccurrences(of: ",", with: "."))
        item.isFavorite = isFavorite
        item.isArchived = isArchived
        try? context.save()
        dismiss()
    }
}

private struct ArrangeItemsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let folder: VaultFolder
    @State private var items: [VaultMediaItem]

    init(folder: VaultFolder) {
        self.folder = folder
        _items = State(initialValue: folder.items.sorted { $0.sortOrder < $1.sortOrder })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    HStack {
                        AsyncThumbnailView(item: item)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(item.note.isEmpty ? "Материал" : item.note).lineLimit(1)
                    }
                }
                .onMove { source, destination in items.move(fromOffsets: source, toOffset: destination) }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Порядок материалов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        VaultOperations.reorder(items, in: context)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MoveItemsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \VaultFolder.sortOrder) private var folders: [VaultFolder]

    let items: [VaultMediaItem]
    let currentFolder: VaultFolder
    let onMove: () -> Void

    var body: some View {
        NavigationStack {
            List(folders.filter { $0.id != currentFolder.id }) { folder in
                Button {
                    VaultOperations.move(items, to: folder, in: context)
                    onMove()
                    dismiss()
                } label: {
                    Label(folder.name, systemImage: folder.symbolName).foregroundStyle(.primary)
                }
            }
            .overlay {
                if folders.count < 2 {
                    ContentUnavailableView("Нет другой папки", systemImage: "folder.badge.questionmark")
                }
            }
            .navigationTitle("Переместить в папку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private enum VaultPackExporter {
    private struct Manifest: Codable {
        let format: String
        let version: Int
        let exportedAt: Date
        let folderName: String
        let template: String
        let items: [Item]

        struct Item: Codable {
            let id: UUID
            let type: String
            let fileName: String
            let title: String
            let caption: String
            let note: String
            let tags: [String]
            let sourceURL: String
            let status: String
            let rating: Int
            let price: Double?
            let order: Int
        }
    }

    static func activityItems(folder: VaultFolder, items: [VaultMediaItem]) throws -> [Any] {
        let manifest = Manifest(
            format: "VAULT Pack",
            version: 1,
            exportedAt: .now,
            folderName: folder.name,
            template: folder.template.rawValue,
            items: items.enumerated().map { index, item in
                Manifest.Item(
                    id: item.id,
                    type: item.mediaType.rawValue,
                    fileName: item.localFileName,
                    title: item.title,
                    caption: item.caption,
                    note: item.note,
                    tags: item.tags,
                    sourceURL: item.sourceURLString,
                    status: item.statusRaw,
                    rating: item.rating,
                    price: item.price,
                    order: index
                )
            }
        )

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("VAULT Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let safeName = folder.name.replacingOccurrences(of: "/", with: "-")
        let manifestURL = directory.appendingPathComponent("\(safeName)-VAULT-Pack.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(manifest).write(to: manifestURL, options: .atomic)

        let mediaURLs = items.compactMap { item -> URL? in
            guard item.mediaType != .link, !item.localFileName.isEmpty else { return nil }
            let url = LocalFileService.shared.url(for: item.localFileName, location: .media)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        return [manifestURL as Any] + mediaURLs.map { $0 as Any }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
