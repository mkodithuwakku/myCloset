import Foundation
import XCTest
@testable import myCloset

@MainActor
final class ClosetStoreTests: XCTestCase {
    func testUpsertPersistsAndReloadsItem() {
        let url = temporaryStorageURL()
        let store = ClosetStore(storageURL: url)
        let shirt = TestFixtures.item("Blue Shirt", category: .top)

        store.upsert(shirt)
        let reloaded = ClosetStore(storageURL: url)

        let persisted = reloaded.items.first
        XCTAssertEqual(reloaded.items.count, 1)
        XCTAssertEqual(persisted?.id, shirt.id)
        XCTAssertEqual(persisted?.name, shirt.name)
        XCTAssertEqual(persisted?.category, shirt.category)
        XCTAssertEqual(persisted?.dominantColor, shirt.dominantColor)
        XCTAssertEqual(persisted?.seasons, shirt.seasons)
        XCTAssertEqual(persisted?.formalities, shirt.formalities)
        XCTAssertEqual(persisted?.availability, shirt.availability)
        // ISO-8601 persistence intentionally stores creation timestamps to whole seconds.
        XCTAssertEqual(persisted?.createdAt.timeIntervalSince1970 ?? 0, shirt.createdAt.timeIntervalSince1970, accuracy: 1)
    }

    func testBatchUpsertPersistsAllImportedItems() {
        let url = temporaryStorageURL()
        let store = ClosetStore(storageURL: url)
        let shirt = TestFixtures.item("Blue Shirt", category: .top)
        let jeans = TestFixtures.item("Dark Jeans", category: .bottom)

        store.upsert([shirt, jeans])
        let reloaded = ClosetStore(storageURL: url)

        XCTAssertEqual(Set(reloaded.items.map(\.id)), Set([shirt.id, jeans.id]))
    }

    func testDuplicateNameIgnoresCaseAndRepeatedWhitespace() {
        let store = makeStore()
        store.upsert(TestFixtures.item("Blue Shirt", category: .top))

        let duplicate = store.duplicateName(for: "  BLUE   shirt ")

        XCTAssertEqual(duplicate?.name, "Blue Shirt")
    }

    func testDuplicateNameExcludesEditedRecord() {
        let store = makeStore()
        let item = TestFixtures.item("Blue Shirt", category: .top)
        store.upsert(item)

        XCTAssertNil(store.duplicateName(for: "blue shirt", excluding: item.id))
    }

    func testSampleClosetContainsTwelveUsablePieces() {
        let store = makeStore()

        store.loadSamples()

        XCTAssertEqual(store.items.count, 12)
        XCTAssertTrue(store.items.contains { $0.category == .top })
        XCTAssertTrue(store.items.contains { $0.category == .bottom })
        XCTAssertTrue(store.items.contains { $0.category == .footwear })
    }

    func testLoadingSamplesIsIdempotent() {
        let store = makeStore()

        store.loadSamples()
        store.loadSamples()

        XCTAssertEqual(store.items.count, 12)
    }

    func testLegacySampleClosetIsRemovedOnNextLaunchWithoutTouchingImportedItems() {
        let url = temporaryStorageURL()
        let store = ClosetStore(storageURL: url)
        store.loadSamples()
        var imported = TestFixtures.item("My Blue Shirt", category: .top, color: "Blue")
        imported.photoData = Data([0x01, 0x02, 0x03])
        store.upsert(imported)

        let reloaded = ClosetStore(storageURL: url)

        XCTAssertEqual(reloaded.items.map(\.id), [imported.id])
    }

    func testArchivedItemIsNotVisible() {
        let store = makeStore()
        let item = TestFixtures.item("Archived Tee", category: .top)
        store.upsert(item)

        store.setAvailability(.archived, for: item.id)

        XCTAssertFalse(store.visibleItems.contains { $0.id == item.id })
        XCTAssertTrue(store.items.contains { $0.id == item.id })
    }

    func testUnavailableItemIsNotAvailable() {
        let store = makeStore()
        let item = TestFixtures.item("Laundry Tee", category: .top)
        store.upsert(item)

        store.setAvailability(.laundry, for: item.id)

        XCTAssertFalse(store.availableItems.contains { $0.id == item.id })
    }

    func testSavingSameOutfitTwiceDoesNotDuplicateRecord() throws {
        let store = makeStoreWithSamples()
        let outfit = try store.engine.generate(
            from: store.items,
            occasion: .errands,
            formality: .casual,
            weather: TestFixtures.summerWeather
        ).get()

        store.save(outfit)
        store.save(outfit)

        XCTAssertEqual(store.savedOutfits.count, 1)
    }

    func testWornOutfitSnapshotSurvivesClosetItemEdit() throws {
        let store = makeStoreWithSamples()
        let outfit = try store.engine.generate(
            from: store.items,
            occasion: .errands,
            formality: .casual,
            weather: TestFixtures.summerWeather
        ).get()
        let originalName = store.resolve(outfit)[0].name
        let changedID = store.resolve(outfit)[0].id

        store.markWorn(outfit)
        var changed = store.items.first { $0.id == changedID }!
        changed.name = "Renamed After Wearing"
        store.upsert(changed)

        XCTAssertEqual(store.wornOutfits[0].items.first { $0.id == changedID }?.name, originalName)
    }

    func testClearPrototypeDataRemovesAllUserContent() throws {
        let store = makeStoreWithSamples()
        let outfit = try store.engine.generate(
            from: store.items,
            occasion: .errands,
            formality: .casual,
            weather: TestFixtures.summerWeather
        ).get()
        store.save(outfit)
        store.markWorn(outfit)

        store.clearPrototypeData()

        XCTAssertTrue(store.items.isEmpty)
        XCTAssertTrue(store.savedOutfits.isEmpty)
        XCTAssertTrue(store.wornOutfits.isEmpty)
    }

    private func makeStore() -> ClosetStore {
        ClosetStore(storageURL: temporaryStorageURL())
    }

    private func makeStoreWithSamples() -> ClosetStore {
        let store = makeStore()
        store.loadSamples()
        return store
    }

    private func temporaryStorageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("closet.json")
    }
}
