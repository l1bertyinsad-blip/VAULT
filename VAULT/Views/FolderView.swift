import PhotosUI
import SwiftData
import SwiftUI

struct FolderView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let folder: VaultFolder

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var importer = MediaImportViewModel()
    @State private var viewerItem: VaultMediaItem?
    @State private var isSelecting = false
    @State private var selection = Set<UUID>()
    @State private var showsEdit = false
    @State private var showsMove = false
    @State private var showsDeleteItems = false
    @State private var showsDeleteFolder = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
    private var items: [VaultMediaItem] { folder.items.sorted { $0.sortOrder < $1.sortOrder } }
    private var selectedItems: [VaultMediaItem] { items.filter { selection.contains($0.id) } }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("Здесь пока ничего нет", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("Добавьте фотографии и видео из галереи iPhone")
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
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(items) { item in
                            Button {
                                if isSelecting {
                                    toggleSelection(item)
                                } else {
                                    viewerItem = item
                                }
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    AsyncThumbnailView(item: item)
                                        .aspectRatio(1, contentMode: .fit)
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
                            .accessibilityLabel(item.mediaType == .video ? "Открыть видео" : "Открыть фото")
                        }
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) {
            if isSelecting { selectionBar }
        }
        .overlay {
            if importer.isImporting {
                importOverlay
            }
        }
        .onChange(of: pickerItems) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task {
                await importer.importItems(newValue, into: folder, context: context)
                pickerItems = []
            }
        }
        .alert("Импорт завершён не полностью", isPresented: errorBinding) {
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
        .sheet(isPresented: $showsEdit) {
            FolderEditorSheet(mode: .edit(folder))
        }
        .sheet(isPresented: $showsMove) {
            MoveItemsSheet(items: selectedItems, currentFolder: folder) {
                endSelection()
            }
        }
        .fullScreenCover(item: $viewerItem) { item in
            MediaViewer(items: items, initialItemID: item.id)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isSelecting {
            ToolbarItem(placement: .topBarLeading) {
                Button("Готово") { endSelection() }
            }
            ToolbarItem(placement: .principal) {
                Text("Выбрано: \(selection.count)").font(.headline)
            }
        } else {
            ToolbarItemGroup(placement: .topBarTrailing) {
                PhotosPicker(
                    selection: $pickerItems,
                    maxSelectionCount: 50,
                    matching: .any(of: [.images, .videos])
                ) {
                    Image(systemName: "plus")
                }
                .disabled(importer.isImporting)
                .accessibilityLabel("Добавить фото и видео")

                Menu {
                    Button { isSelecting = true } label: { Label("Выбрать", systemImage: "checkmark.circle") }
                    Button { showsEdit = true } label: { Label("Редактировать", systemImage: "pencil") }
                    Button(role: .destructive) { showsDeleteFolder = true } label: { Label("Удалить папку", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var selectionBar: some View {
        HStack {
            Button { showsMove = true } label: { Label("Переместить", systemImage: "folder") }
                .disabled(selection.isEmpty)
            Spacer()
            Button(role: .destructive) { showsDeleteItems = true } label: { Label("Удалить", systemImage: "trash") }
                .disabled(selection.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var importOverlay: some View {
        VStack(spacing: 14) {
            ProgressView(value: importer.progress)
                .progressViewStyle(.linear)
                .frame(width: 210)
            Text("Импорт \(importer.completedCount) из \(importer.totalCount)")
                .font(.subheadline.weight(.medium))
        }
        .padding(24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(radius: 20)
        .accessibilityElement(children: .combine)
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { importer.errorMessage != nil }, set: { if !$0 { importer.errorMessage = nil } })
    }

    private func toggleSelection(_ item: VaultMediaItem) {
        if selection.contains(item.id) { selection.remove(item.id) } else { selection.insert(item.id) }
    }

    private func deleteSelected() {
        selectedItems.forEach { VaultOperations.delete($0, in: context) }
        endSelection()
    }

    private func endSelection() {
        selection.removeAll()
        isSelecting = false
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
                    Label(folder.name, systemImage: folder.symbolName)
                        .foregroundStyle(.primary)
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
