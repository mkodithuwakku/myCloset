import Foundation
import SwiftUI

@MainActor
final class ClosetStore: ObservableObject {
    @Published private(set) var items: [ClosetItem] = []
    @Published private(set) var savedOutfits: [OutfitRecord] = []
    @Published private(set) var wornOutfits: [OutfitRecord] = []
    @Published var profile = UserProfile()
    @Published var dailyOutfit: GeneratedOutfit?
    @Published var dailyError: OutfitGenerationError?

    let engine = OutfitEngine()
    private let storageURL: URL
    private var dailyDate: Date?

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        if let storageURL {
            self.storageURL = storageURL
            try? fileManager.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } else {
            let directory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("myClosetPrototype", isDirectory: true)
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            self.storageURL = directory.appendingPathComponent("closet.json")
        }
        load()
    }

    var visibleItems: [ClosetItem] {
        items.filter { $0.availability != .archived }
    }

    var availableItems: [ClosetItem] {
        items.filter(\.isAvailable)
    }

    func duplicateName(for name: String, excluding id: UUID? = nil) -> ClosetItem? {
        let normalized = Self.normalize(name)
        return items.first {
            $0.id != id && $0.availability != .archived && Self.normalize($0.name) == normalized
        }
    }

    func upsert(_ item: ClosetItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
        items.sort { $0.createdAt > $1.createdAt }
        persistAndRefresh()
    }

    func setAvailability(_ availability: ItemAvailability, for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].availability = availability
        persistAndRefresh()
    }

    func toggleFavorite(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isFavorite.toggle()
        persistAndRefresh()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        persistAndRefresh()
    }

    func refreshDaily(weather: WeatherContext, force: Bool = false) {
        if !force,
           let dailyDate,
           Calendar.current.isDate(dailyDate, inSameDayAs: Date()),
           dailyOutfit != nil {
            return
        }
        switch engine.generate(
            from: items,
            occasion: .errands,
            formality: .casual,
            weather: weather
        ) {
        case .success(let outfit):
            dailyOutfit = outfit
            dailyError = nil
            dailyDate = Date()
        case .failure(let error):
            dailyOutfit = nil
            dailyError = error
        }
    }

    func resolve(_ outfit: GeneratedOutfit) -> [ClosetItem] {
        outfit.itemIDs.compactMap { id in items.first { $0.id == id } }
    }

    func save(_ outfit: GeneratedOutfit) {
        let record = makeRecord(outfit, wornAt: nil)
        guard !savedOutfits.contains(where: { $0.items.map(\.id) == record.items.map(\.id) && $0.occasion == record.occasion }) else {
            return
        }
        savedOutfits.insert(record, at: 0)
        persist()
    }

    func markWorn(_ outfit: GeneratedOutfit, date: Date = Date()) {
        wornOutfits.insert(makeRecord(outfit, wornAt: date), at: 0)
        persist()
    }

    func removeSaved(_ id: UUID) {
        savedOutfits.removeAll { $0.id == id }
        persist()
    }

    func removeWorn(_ id: UUID) {
        wornOutfits.removeAll { $0.id == id }
        persist()
    }

    func updateProfile(_ newProfile: UserProfile) {
        profile = newProfile
        persist()
    }

    func loadSamples() {
        guard items.isEmpty else { return }
        let allSeasons = Set(WardrobeSeason.allCases)
        items = [
            .init(name: "Navy Oxford Shirt", category: .top, dominantColor: color("Navy"), accentColor: color("White"), seasons: allSeasons, formalities: [.casual, .smartCasual, .business], isFavorite: true),
            .init(name: "Cream T-Shirt", category: .top, dominantColor: color("White"), seasons: [.spring, .summer], formalities: [.veryCasual, .casual]),
            .init(name: "Black Active Tee", category: .top, dominantColor: color("Black"), seasons: allSeasons, formalities: [.active]),
            .init(name: "Beige Trousers", category: .bottom, dominantColor: color("Beige"), seasons: allSeasons, formalities: [.casual, .smartCasual, .business]),
            .init(name: "Dark Jeans", category: .bottom, dominantColor: color("Navy"), seasons: allSeasons, formalities: [.veryCasual, .casual, .smartCasual], isFavorite: true),
            .init(name: "Black Joggers", category: .bottom, dominantColor: color("Black"), seasons: allSeasons, formalities: [.active, .veryCasual]),
            .init(name: "Olive Overshirt", category: .outerwear, dominantColor: color("Green"), seasons: [.spring, .autumn], formalities: [.casual, .smartCasual]),
            .init(name: "Camel Wool Coat", category: .outerwear, dominantColor: color("Brown"), seasons: [.autumn, .winter], formalities: [.smartCasual, .business, .formal]),
            .init(name: "White Sneakers", category: .footwear, dominantColor: color("White"), seasons: [.spring, .summer, .autumn], formalities: [.active, .veryCasual, .casual, .smartCasual]),
            .init(name: "Brown Loafers", category: .footwear, dominantColor: color("Brown"), seasons: allSeasons, formalities: [.smartCasual, .business, .formal]),
            .init(name: "Black Trainers", category: .footwear, dominantColor: color("Black"), seasons: allSeasons, formalities: [.active, .veryCasual]),
            .init(name: "Silver Watch", category: .accessory, dominantColor: color("Grey"), seasons: allSeasons, formalities: [.casual, .smartCasual, .business, .formal])
        ]
        persistAndRefresh()
    }

    func clearPrototypeData() {
        items = []
        savedOutfits = []
        wornOutfits = []
        dailyOutfit = nil
        dailyError = nil
        persist()
    }

    private func makeRecord(_ outfit: GeneratedOutfit, wornAt: Date?) -> OutfitRecord {
        .init(
            items: resolve(outfit).map(OutfitSnapshotItem.init),
            occasion: outfit.occasion,
            formality: outfit.formality,
            weatherSummary: outfit.weather.displayTemperature.map { "\($0), \(outfit.weather.summary)" } ?? outfit.weather.summary,
            wornAt: wornAt
        )
    }

    private func persistAndRefresh() {
        dailyDate = nil
        persist()
    }

    private func persist() {
        let value = PersistedCloset(items: items, savedOutfits: savedOutfits, wornOutfits: wornOutfits, profile: profile)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let value = try? decoder.decode(PersistedCloset.self, from: data) else { return }
        items = value.items
        savedOutfits = value.savedOutfits
        wornOutfits = value.wornOutfits
        profile = value.profile
    }

    private static func normalize(_ name: String) -> String {
        name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .lowercased()
    }

    private func color(_ name: String) -> ClothingColor {
        ClothingColor.palette.first { $0.name == name } ?? ClothingColor.palette[2]
    }
}
