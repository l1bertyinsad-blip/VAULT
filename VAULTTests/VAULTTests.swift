import Foundation
import SwiftData
import XCTest
@testable import VAULT

@MainActor
final class VAULTTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([VaultFolder.self, VaultMediaItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    func testCreateAndRenameFolder() throws {
        let context = try makeContainer().mainContext
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
        let context = try makeContainer().mainContext
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
        let context = try makeContainer().mainContext
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
        let context = try makeContainer().mainContext
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
}
