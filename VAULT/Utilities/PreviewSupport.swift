import SwiftData
import SwiftUI

@MainActor
enum PreviewSupport {
    static func container(withSamples: Bool = true) -> ModelContainer {
        let schema = Schema([VaultFolder.self, VaultMediaItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        guard withSamples else { return container }

        let samples = [
            VaultFolder(name: "CS2", colorIdentifier: "purple", symbolName: "gamecontroller.fill", sortOrder: 0),
            VaultFolder(name: "Дизайн", colorIdentifier: "pink", symbolName: "paintpalette.fill", sortOrder: 1),
            VaultFolder(name: "Фильмы", colorIdentifier: "blue", symbolName: "film.fill", sortOrder: 2)
        ]
        samples.forEach { container.mainContext.insert($0) }
        return container
    }

    static func emptyFolderPreview() -> (container: ModelContainer, folder: VaultFolder) {
        let container = container(withSamples: false)
        let folder = VaultFolder(name: "Дизайн", symbolName: "paintpalette.fill")
        container.mainContext.insert(folder)
        return (container, folder)
    }
}

#Preview("Папки") {
    FoldersView()
        .modelContainer(PreviewSupport.container())
}

#Preview("Пустая папка") {
    let preview = PreviewSupport.emptyFolderPreview()
    NavigationStack {
        FolderView(folder: preview.folder)
    }
    .modelContainer(preview.container)
}
