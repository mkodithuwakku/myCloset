import Foundation
@testable import myCloset

enum TestFixtures {
    static func color(_ name: String) -> ClothingColor {
        ClothingColor.palette.first { $0.name == name }!
    }

    static func item(
        _ name: String,
        category: ClothingCategory,
        color: String = "Navy",
        seasons: Set<WardrobeSeason> = Set(WardrobeSeason.allCases),
        formalities: Set<FormalityLevel> = [.casual, .smartCasual],
        availability: ItemAvailability = .available,
        favorite: Bool = false
    ) -> ClosetItem {
        ClosetItem(
            name: name,
            category: category,
            dominantColor: self.color(color),
            seasons: seasons,
            formalities: formalities,
            availability: availability,
            isFavorite: favorite
        )
    }

    static var summerWeather: WeatherContext {
        .init(
            temperatureCelsius: 24,
            apparentTemperatureCelsius: 25,
            summary: "Clear",
            locationName: "Edmonton",
            season: .summer,
            source: .city
        )
    }

    static var winterWeather: WeatherContext {
        .init(
            temperatureCelsius: -12,
            apparentTemperatureCelsius: -18,
            summary: "Snowy",
            locationName: "Edmonton",
            season: .winter,
            source: .city
        )
    }

    static var completeCloset: [ClosetItem] {
        [
            item("Navy Shirt", category: .top, color: "Navy"),
            item("Cream Tee", category: .top, color: "White"),
            item("Beige Trousers", category: .bottom, color: "Beige"),
            item("Dark Jeans", category: .bottom, color: "Navy"),
            item("White Sneakers", category: .footwear, color: "White"),
            item("Brown Loafers", category: .footwear, color: "Brown"),
            item("Wool Coat", category: .outerwear, color: "Brown", seasons: [.winter]),
            item("Silver Watch", category: .accessory, color: "Grey")
        ]
    }
}
