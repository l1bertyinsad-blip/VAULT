import SwiftData
import SwiftUI

struct FoldersView: View {
    @Query(sort: \VaultFolder.sortOrder) private var folders: [VaultFolder]
    @State private var showsCreateFolder = false

    private let columns = [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            Group {
                if folders.isEmpty {
                    VaultEmptyState(
                        title: "Создайте первую папку",
                        message: "Собирайте фотографии и видео по своим темам",
                        buttonTitle: "Создать папку"
                    ) { showsCreateFolder = true }
                    .accessibilityIdentifier("foldersEmptyState")
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(folders) { folder in
                                NavigationLink {
                                    FolderView(folder: folder)
                                } label: {
                                    FolderCard(folder: folder)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("folderCard_\(folder.name)")
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Мои папки")
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
        }
    }
}

private struct FolderCard: View {
    let folder: VaultFolder

    private var latestItem: VaultMediaItem? {
        folder.items.max(by: { $0.createdAt < $1.createdAt })
    }

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
                Text(folder.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(folder.items.count.formattedItems)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.07), lineWidth: 0.5)
        }
    }
}

private extension Int {
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
