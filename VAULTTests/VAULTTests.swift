import Foundation
import SwiftData
import XCTest
@testable import VAULT

@MainActor
final class VAULTTests: XCTestCase {
    private var container: ModelContainer!

    override func setUpWithError() throws {
        container = try makeContainer()
    }

    override func tearDownWithError() throws {
        container = nil
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([VaultFolder.self, VaultMediaItem.self, VaultNote.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    func testCreateAndRenameFolder() throws {
        let context = container.mainContext
        let folder = try XCTUnwrap(VaultOperations.createFolder(
            name: "  Дизайн  ",
            colorIdentifier: "purple",
            symbolName: "paintpalette.fill",
            sortOrder: 0,
            in: context
        ))

        XCTAssertEqual(folder.name, "Дизайн")
        XCTAssertTrue(VaultOperations.update(
            folder,
            name: "Фильмы",
            colorIdentifier: "blue",
            symbolName: "film.fill",
            in: context
        ))
        XCTAssertEqual(folder.name, "Фильмы")
        XCTAssertNil(VaultOperations.createFolder(
            name: "   ",
            colorIdentifier: "purple",
            symbolName: "folder.fill",
            sortOrder: 1,
            in: context
        ))
    }

    func testAddItemAndCascadeDeleteFolder() throws {
        let context = container.mainContext
        let folder = VaultFolder(name: "CS2")
        let item = VaultMediaItem(
            mediaType: .photo,
            localFileName: "photo.jpg",
            thumbnailFileName: "thumb.jpg",
            folder: folder
        )
        context.insert(folder)
        context.insert(item)
        try context.save()

        XCTAssertEqual(folder.items.count, 1)
        context.delete(folder)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<VaultFolder>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<VaultMediaItem>()), 0)
    }

    func testDeleteFolderRemovesAssociatedFiles() throws {
        let context = container.mainContext
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let storage = LocalFileService(rootURL: temporary)
        defer { try? FileManager.default.removeItem(at: temporary) }

        let id = UUID()
        let mediaName = try storage.writeMedia(Data([1, 2, 3]), id: id, fileExtension: "jpg")
        let thumbName = try storage.writeThumbnail(Data([4, 5]), id: id)
        let folder = VaultFolder(name: "Покупки")
        let item = VaultMediaItem(
            id: id,
            mediaType: .photo,
            localFileName: mediaName,
            thumbnailFileName: thumbName,
            folder: folder
        )
        context.insert(folder)
        context.insert(item)
        try context.save()

        VaultOperations.delete(folder, in: context, storage: storage)

        XCTAssertFalse(FileManager.default.fileExists(atPath: storage.url(for: mediaName, location: .media).path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: storage.url(for: thumbName, location: .thumbnail).path))
    }

    func testStorageUsageAndSafePaths() throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let storage = LocalFileService(rootURL: temporary)
        defer { try? FileManager.default.removeItem(at: temporary) }

        let fileName = try storage.writeMedia(Data(repeating: 7, count: 1_024), id: UUID(), fileExtension: ".JPG")
        XCTAssertEqual(storage.usedBytes(), 1_024)
        XCTAssertEqual(storage.url(for: "../../\(fileName)", location: .media).lastPathComponent, fileName)
        XCTAssertTrue(storage.url(for: fileName, location: .media).path.hasPrefix(temporary.path))
    }

    func testMoveItems() throws {
        let context = container.mainContext
        let source = VaultFolder(name: "Источник")
        let destination = VaultFolder(name: "Назначение")
        let item = VaultMediaItem(
            mediaType: .video,
            localFileName: "video.mov",
            thumbnailFileName: "video.jpg",
            folder: source
        )
        context.insert(source)
        context.insert(destination)
        context.insert(item)
        try context.save()

        VaultOperations.move([item], to: destination, in: context)

        XCTAssertEqual(item.folder?.id, destination.id)
        XCTAssertTrue(destination.items.contains(where: { $0.id == item.id }))
    }

    func testTemplateAndSearchableMetadata() throws {
        let context = container.mainContext
        let folder = VaultFolder(name: "Покупки", template: .purchases)
        let item = VaultMediaItem(
            mediaType: .photo,
            localFileName: "shoes.jpg",
            thumbnailFileName: "shoes-thumb.jpg",
            folder: folder,
            title: "Кроссовки для бега",
            caption: "Лёгкая модель на каждый день",
            note: "Синие кроссовки",
            tags: ["обувь", "спорт"],
            status: "Хочу",
            price: 99.90,
            recognizedText: "RUN FAST"
        )
        context.insert(folder)
        context.insert(item)
        try context.save()

        XCTAssertEqual(folder.template, .purchases)
        XCTAssertTrue(item.searchableText.contains("кроссовки"))
        XCTAssertTrue(item.searchableText.contains("лёгкая"))
        XCTAssertTrue(item.searchableText.contains("run fast"))
        XCTAssertEqual(item.tags, ["обувь", "спорт"])
    }

    func testCreateStandaloneNote() throws {
        let context = container.mainContext
        let note = VaultNote(title: "Идея", body: "Собрать референсы", isPinned: true)
        context.insert(note)
        try context.save()

        let saved = try XCTUnwrap(context.fetch(FetchDescriptor<VaultNote>()).first)
        XCTAssertEqual(saved.displayTitle, "Идея")
        XCTAssertTrue(saved.isPinned)
    }

    func testSaveInstagramReelAsLinkCard() throws {
        let context = container.mainContext
        let folder = VaultFolder(name: "Входящие", isSystem: true)
        context.insert(folder)
        let importer = MediaImportViewModel()

        XCTAssertTrue(importer.importLink(
            "Посмотри это видео https://www.instagram.com/reel/ABC123/",
            into: folder,
            context: context
        ))

        let item = try XCTUnwrap(context.fetch(FetchDescriptor<VaultMediaItem>()).first)
        XCTAssertEqual(item.mediaType, .link)
        XCTAssertEqual(item.title, "Instagram Reel")
        XCTAssertTrue(item.sourceURLString.contains("instagram.com/reel"))
        XCTAssertEqual(item.caption, "Посмотри это видео")
        XCTAssertFalse(importer.importLink(item.sourceURLString, into: folder, context: context))
    }

    func testSharedImportKeepsSelectedFolder() throws {
        let folderID = UUID()
        let mediaURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(folderID.uuidString)--photo.jpg")
        XCTAssertEqual(SharedImportQueue.destinationFolderID(for: mediaURL), folderID)

        let payload = SharedLinkPayload(
            version: 1,
            url: "https://example.com",
            title: "Example",
            caption: "",
            source: "example.com",
            folderID: folderID
        )
        let linkURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).vaultlink")
        defer { try? FileManager.default.removeItem(at: linkURL) }
        try JSONEncoder().encode(payload).write(to: linkURL, options: .atomic)

        XCTAssertEqual(SharedImportQueue.destinationFolderID(for: linkURL), folderID)
    }

    func testInboxSuggestsRecipeFolder() throws {
        let context = container.mainContext
        let inbox = VaultFolder(name: "Входящие", isSystem: true)
        let recipes = VaultFolder(name: "Рецепты", sortOrder: 0, template: .recipes)
        let design = VaultFolder(name: "Дизайн", sortOrder: 1, template: .design)
        let item = VaultMediaItem(
            mediaType: .link,
            localFileName: "",
            thumbnailFileName: "",
            folder: inbox,
            title: "Рецепт домашней пасты",
            caption: "Ингредиенты и приготовление"
        )
        [inbox, recipes, design].forEach { context.insert($0) }
        context.insert(item)
        try context.save()

        let suggestion = InboxSuggestionService.suggestion(
            for: item,
            folders: [inbox, design, recipes]
        )
        XCTAssertEqual(suggestion?.id, recipes.id)
    }

    func testUsefulFeedPrioritizesInboxAndExplainsItems() throws {
        let context = container.mainContext
        let inbox = VaultFolder(name: "Входящие", isSystem: true)
        let ideas = VaultFolder(name: "Идеи")
        let inboxItem = VaultMediaItem(
            mediaType: .link,
            localFileName: "",
            thumbnailFileName: "",
            folder: inbox,
            title: "Новая идея"
        )
        let favorite = VaultMediaItem(
            mediaType: .photo,
            localFileName: "favorite.jpg",
            thumbnailFileName: "favorite-thumb.jpg",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            folder: ideas,
            title: "Любимая идея",
            isFavorite: true
        )
        let archived = VaultMediaItem(
            mediaType: .photo,
            localFileName: "archive.jpg",
            thumbnailFileName: "archive-thumb.jpg",
            folder: ideas,
            isArchived: true
        )
        [inbox, ideas].forEach { context.insert($0) }
        [inboxItem, favorite, archived].forEach { context.insert($0) }
        try context.save()

        let entries = UsefulFeedPlanner.entries(
            from: [favorite, archived, inboxItem],
            date: Date(timeIntervalSince1970: 1_710_000_000)
        )

        XCTAssertEqual(entries.map(\.item.id), [inboxItem.id, favorite.id])
        XCTAssertEqual(entries.first?.reason, .inbox)
        XCTAssertEqual(entries.last?.reason, .favorite)
    }
}
