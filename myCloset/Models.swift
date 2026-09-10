import Foundation

enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case top
    case bottom
    case onePiece
    case outerwear
    case footwear
    case accessory

    var id: String { rawValue }

    var outfitSlot: ClothingCategory { self == .outerwear ? .top : self }

    var title: String {
        switch self {
        case .top: "Top"
        case .bottom: "Bottom"
        case .onePiece: "One-piece"
        case .outerwear: "Outerwear"
        case .footwear: "Footwear"
        case .accessory: "Accessory"
        }
    }

    var icon: String {
        switch self {
        case .top: "tshirt.fill"
        case .bottom: "figure.stand.dress"
        case .onePiece: "hanger"
        case .outerwear: "jacket.fill"
        case .footwear: "shoe.fill"
        case .accessory: "sunglasses"
        }
    }

    var suggestedSeasons: Set<WardrobeSeason> {
        switch self {
        case .outerwear: [.spring, .autumn, .winter]
        case .onePiece: [.spring, .summer, .autumn]
        case .top, .bottom, .footwear, .accessory: Set(WardrobeSeason.allCases)
        }
    }

    var suggestedFormalities: Set<FormalityLevel> {
        switch self {
        case .footwear: [.active, .veryCasual, .casual, .smartCasual]
        case .outerwear: [.casual, .smartCasual, .business]
        case .accessory: [.casual, .smartCasual, .business, .formal]
        case .top, .bottom, .onePiece: [.veryCasual, .casual, .smartCasual]
        }
    }
}

enum GarmentKind: String, Codable, CaseIterable, Hashable, Identifiable {
    case tShirt, longSleeve, shirt, blouse, tankTop, sweater, hoodie
    case trousers, jeans, shorts, skirt, leggings
    case dress, jumpsuit
    case coat, jacket, blazer, cardigan
    case sneakers, shoes, loafers, boots, sandals
    case watch, bag, scarf, belt, tie, hat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tShirt: "T-Shirt"
        case .longSleeve: "Long Sleeve"
        case .tankTop: "Tank Top"
        default: rawValue.capitalized
        }
    }

    var category: ClothingCategory {
        switch self {
        case .tShirt, .longSleeve, .shirt, .blouse, .tankTop, .sweater: .top
        case .trousers, .jeans, .shorts, .skirt, .leggings: .bottom
        case .dress, .jumpsuit: .onePiece
        case .hoodie, .coat, .jacket, .blazer, .cardigan: .outerwear
        case .sneakers, .shoes, .loafers, .boots, .sandals: .footwear
        case .watch, .bag, .scarf, .belt, .tie, .hat: .accessory
        }
    }

    var suggestedSeasons: Set<WardrobeSeason> {
        switch self {
        case .shorts, .tankTop, .sandals:
            [.spring, .summer]
        case .coat, .boots:
            [.autumn, .winter]
        case .longSleeve, .sweater, .hoodie, .jacket, .cardigan, .scarf:
            [.spring, .autumn, .winter]
        case .dress, .skirt:
            [.spring, .summer, .autumn]
        default:
            Set(WardrobeSeason.allCases)
        }
    }

    var suggestedFormalities: Set<FormalityLevel> {
        switch self {
        case .tShirt, .longSleeve, .tankTop, .hoodie, .shorts, .leggings, .sneakers:
            [.active, .veryCasual, .casual]
        case .jeans, .sweater, .cardigan, .sandals, .hat, .bag:
            [.veryCasual, .casual, .smartCasual]
        case .shirt, .blouse, .trousers, .jacket, .shoes, .watch, .belt:
            [.casual, .smartCasual, .business]
        case .dress, .coat, .boots, .scarf:
            [.casual, .smartCasual, .business, .formal]
        case .jumpsuit, .skirt:
            [.casual, .smartCasual, .business]
        case .blazer, .loafers, .tie:
            [.smartCasual, .business, .formal]
        }
    }
}


/// Specific garment types keep the broad outfit slots stable for generation
/// and for closets saved before subcategories were available.
enum GarmentType: Hashable {
    case category(ClothingCategory)
    case kind(GarmentKind)

    var category: ClothingCategory {
        switch self {
        case .category(let category): category
        case .kind(let kind): kind.category
        }
    }

    var kind: GarmentKind? {
        if case .kind(let kind) = self { kind } else { nil }
    }

    var title: String { kind?.title ?? category.title }
}

enum WardrobeSeason: String, Codable, CaseIterable, Identifiable {
    case spring
    case summer
    case autumn
    case winter

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    static func current(on date: Date = Date(), latitude: Double? = nil) -> WardrobeSeason {
        let month = Calendar.current.component(.month, from: date)
        let northern: WardrobeSeason
        switch month {
        case 3...5: northern = .spring
        case 6...8: northern = .summer
        case 9...11: northern = .autumn
        default: northern = .winter
        }

        guard let latitude, latitude < 0 else { return northern }
        switch northern {
        case .spring: return .autumn
        case .summer: return .winter
        case .autumn: return .spring
        case .winter: return .summer
        }
    }
}

enum FormalityLevel: Int, Codable, CaseIterable, Identifiable, Comparable {
    case active = 1
    case veryCasual = 2
    case casual = 3
    case smartCasual = 4
    case business = 5
    case formal = 6

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .active: "Active"
        case .veryCasual: "Very casual"
        case .casual: "Casual"
        case .smartCasual: "Smart casual"
        case .business: "Business"
        case .formal: "Formal"
        }
    }

    static func < (lhs: FormalityLevel, rhs: FormalityLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum ItemAvailability: String, Codable, CaseIterable, Identifiable {
    case available
    case unavailable
    case laundry
    case archived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .available: "Available"
        case .unavailable: "Unavailable"
        case .laundry: "In laundry"
        case .archived: "Archived"
        }
    }

    var icon: String {
        switch self {
        case .available: "checkmark.circle.fill"
        case .unavailable: "clock.fill"
        case .laundry: "washer.fill"
        case .archived: "archivebox.fill"
        }
    }
}

struct ClothingColor: Codable, Hashable, Identifiable {
    let name: String
    let hex: String

    var id: String { hex }

    static let palette: [ClothingColor] = [
        .init(name: "Black", hex: "202124"),
        .init(name: "White", hex: "F4F1EA"),
        .init(name: "Grey", hex: "8B8D91"),
        .init(name: "Navy", hex: "283653"),
        .init(name: "Blue", hex: "4D76A8"),
        .init(name: "Teal", hex: "3E7C78"),
        .init(name: "Green", hex: "66765A"),
        .init(name: "Beige", hex: "C8B89F"),
        .init(name: "Brown", hex: "725746"),
        .init(name: "Red", hex: "A94E4A"),
        .init(name: "Pink", hex: "D79AA4"),
        .init(name: "Purple", hex: "77658E"),
        .init(name: "Orange", hex: "C47A45"),
        .init(name: "Yellow", hex: "D3B657")
    ]

    static func nearest(red: Double, green: Double, blue: Double) -> ClothingColor {
        palette.min { lhs, rhs in
            distance(lhs, red: red, green: green, blue: blue) <
                distance(rhs, red: red, green: green, blue: blue)
        } ?? palette[2]
    }

    private static func distance(_ color: ClothingColor, red: Double, green: Double, blue: Double) -> Double {
        let components = color.rgb
        return pow(components.red - red, 2) + pow(components.green - green, 2) + pow(components.blue - blue, 2)
    }

    var rgb: (red: Double, green: Double, blue: Double) {
        let normalized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard let value = UInt64(normalized, radix: 16), normalized.count == 6 else {
            return (0.5, 0.5, 0.5)
        }
        return (
            Double((value >> 16) & 0xFF) / 255,
            Double((value >> 8) & 0xFF) / 255,
            Double(value & 0xFF) / 255
        )
    }

    var isNeutral: Bool {
        ["Black", "White", "Grey", "Navy", "Beige", "Brown"].contains(name)
    }
}

struct ClosetItem: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var category: ClothingCategory
    var kind: GarmentKind? = nil
    var photoData: Data?
    var isolatedPhotoData: Data? = nil
    var dominantColor: ClothingColor
    var accentColor: ClothingColor?
    var seasons: Set<WardrobeSeason>
    var formalities: Set<FormalityLevel>
    var availability: ItemAvailability = .available
    var isFavorite: Bool = false
    var createdAt: Date = Date()

    var garmentType: GarmentType {
        if let kind, kind.category == category { .kind(kind) } else { .category(category) }
    }
    var typeTitle: String { garmentType.title }
    var suggestedName: String { "\(dominantColor.name) \(typeTitle)" }

    mutating func applyType(_ type: GarmentType, updateName: Bool) {
        category = type.category
        kind = type.kind
        seasons = kind?.suggestedSeasons ?? category.suggestedSeasons
        formalities = kind?.suggestedFormalities ?? category.suggestedFormalities
        if updateName { name = suggestedName }
    }

    var isAvailable: Bool { availability == .available }
    var outfitPhotoData: Data? { isolatedPhotoData ?? photoData }
}

enum Occasion: String, Codable, CaseIterable, Identifiable {
    case bar
    case walk
    case sport
    case work
    case school
    case date
    case dinner
    case party
    case wedding
    case travel
    case errands
    case home

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bar: "Bar / night out"
        case .sport: "Sport / workout"
        case .home: "Stay at home"
        default: rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .bar: "wineglass.fill"
        case .walk: "figure.walk"
        case .sport: "figure.run"
        case .work: "briefcase.fill"
        case .school: "book.fill"
        case .date: "heart.fill"
        case .dinner: "fork.knife"
        case .party: "party.popper.fill"
        case .wedding: "sparkles"
        case .travel: "airplane"
        case .errands: "basket.fill"
        case .home: "house.fill"
        }
    }

    var suggestedFormality: FormalityLevel {
        switch self {
        case .sport: .active
        case .home: .veryCasual
        case .walk, .errands: .casual
        case .bar, .date, .dinner, .party: .smartCasual
        case .work: .business
        case .wedding: .formal
        case .school, .travel: .casual
        }
    }
}

struct WeatherContext: Codable, Equatable {
    var temperatureCelsius: Double?
    var apparentTemperatureCelsius: Double?
    var summary: String
    var locationName: String?
    var season: WardrobeSeason
    var source: Source

    enum Source: String, Codable {
        case currentLocation
        case city
        case seasonOnly
    }

    static var seasonalFallback: WeatherContext {
        .init(
            temperatureCelsius: nil,
            apparentTemperatureCelsius: nil,
            summary: "Season-based",
            locationName: nil,
            season: .current(),
            source: .seasonOnly
        )
    }

    var displayTemperature: String? {
        guard let temperatureCelsius else { return nil }
        return "\(Int(temperatureCelsius.rounded()))°C"
    }
}

struct OutfitSnapshotItem: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var category: ClothingCategory
    var kind: GarmentKind? = nil
    var photoData: Data?
    var dominantColor: ClothingColor

    var typeTitle: String { kind?.category == category ? kind?.title ?? category.title : category.title }

    init(item: ClosetItem) {
        id = item.id
        name = item.name
        category = item.category
        kind = item.garmentType.kind
        photoData = item.outfitPhotoData
        dominantColor = item.dominantColor
    }
}

struct OutfitRecord: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var items: [OutfitSnapshotItem]
    var occasion: Occasion
    var formality: FormalityLevel
    var weatherSummary: String
    var createdAt: Date = Date()
    var wornAt: Date?
    var note: String = ""

    var isWorn: Bool { wornAt != nil }
}

struct UserProfile: Codable, Equatable {
    var displayName = "Your name"
    var handle = "mycloset_user"
    var bio = "Building outfits from the pieces I already love."
    var photoData: Data?
}

struct PersistedCloset: Codable {
    var items: [ClosetItem]
    var savedOutfits: [OutfitRecord]
    var wornOutfits: [OutfitRecord]
    var profile: UserProfile
}

struct GeneratedOutfit: Equatable {
    var itemIDs: [UUID]
    var occasion: Occasion
    var formality: FormalityLevel
    var weather: WeatherContext
    var explanation: String
}

enum OutfitGenerationError: LocalizedError, Equatable {
    case emptyCloset
    case missingCategory(String)
    case conflictingLocks(String)
    case noMatch

    var errorDescription: String? {
        switch self {
        case .emptyCloset:
            "Add a few pieces to your closet before generating an outfit."
        case .missingCategory(let category):
            "Add an available \(category.lowercased()) to complete an outfit."
        case .conflictingLocks(let message):
            message
        case .noMatch:
            "No valid combination fits every choice. Try another formality level or unlock a piece."
        }
    }
}
