import Observation
import PhotosUI
import SwiftData

@MainActor
@Observable
final class MediaImportViewModel {
    var isImporting = false
    var completedCount = 0
    var totalCount = 0
    var errorMessage: String?

    var progress: Double {
        totalCount == 0 ? 0 : Double(completedCount) / Double(totalCount)
    }

    private let service: MediaImportService

    init(service: MediaImportService = MediaImportService()) {
        self.service = service
    }

    func importItems(
        _ pickerItems: [PhotosPickerItem],
        into folder: VaultFolder,
        context: ModelContext
    ) async {
        guard !isImporting, !pickerItems.isEmpty else { return }
        isImporting = true
        completedCount = 0
        totalCount = pickerItems.count
        errorMessage = nil
        var failures = 0
        let folderID = folder.id

        for pickerItem in pickerItems {
            guard folderStillExists(id: folderID, context: context) else {
                errorMessage = "Папка была удалена. Импорт остановлен."
                break
            }

            switch await service.importItem(pickerItem) {
            case .success(let draft):
                let media = VaultMediaItem(
                    id: draft.id,
                    mediaType: draft.mediaType,
                    localFileName: draft.localFileName,
                    thumbnailFileName: draft.thumbnailFileName,
                    originalFileName: draft.originalFileName,
                    sortOrder: folder.items.count,
                    duration: draft.duration,
                    folder: folder
                )
                context.insert(media)
                try? context.save()
            case .failure:
                failures += 1
            }
            completedCount += 1
        }

        if failures > 0 {
            errorMessage = failures == 1
                ? "Один материал не удалось импортировать. Остальные сохранены."
                : "Не удалось импортировать материалов: \(failures). Остальные сохранены."
        }
        isImporting = false
    }

    private func folderStillExists(id: UUID, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<VaultFolder>(predicate: #Predicate { $0.id == id })
        return (try? context.fetchCount(descriptor)) == 1
    }
}
