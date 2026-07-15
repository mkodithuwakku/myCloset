import Foundation

struct OutfitEngine {
    func generate(
        from allItems: [ClosetItem],
        occasion: Occasion,
        formality: FormalityLevel,
        weather: WeatherContext,
        lockedIDs: Set<UUID> = [],
        excluding excludedIDs: Set<UUID> = []
    ) -> Result<GeneratedOutfit, OutfitGenerationError> {
        let available = allItems.filter {
            $0.isAvailable && !excludedIDs.contains($0.id)
        }

        guard !available.isEmpty else { return .failure(.emptyCloset) }

        let locked = allItems.filter { lockedIDs.contains($0.id) }
        if let unavailableLock = locked.first(where: { !$0.isAvailable }) {
            return .failure(.conflictingLocks("\(unavailableLock.name) is currently marked \(unavailableLock.availability.title.lowercased())."))
        }

        let lockedCategories = Dictionary(grouping: locked, by: \.category)
        if lockedCategories.contains(where: { category, items in category != .accessory && items.count > 1 }) {
            return .failure(.conflictingLocks("Unlock one of the pieces that fills the same outfit slot."))
        }

        let hasLockedOnePiece = lockedCategories[.onePiece] != nil
        let hasLockedSeparates = lockedCategories[.top] != nil || lockedCategories[.bottom] != nil
        if hasLockedOnePiece && hasLockedSeparates {
            return .failure(.conflictingLocks("A one-piece cannot be combined with a locked top or bottom in this prototype."))
        }

        var selected = locked
        let anchor = locked.first

        func candidates(for category: ClothingCategory) -> [ClosetItem] {
            let categoryItems = available.filter { item in
                item.category == category &&
                !selected.contains(where: { $0.id == item.id }) &&
                (item.seasons.contains(weather.season) || item.seasons.count == WardrobeSeason.allCases.count)
            }

            let formalMatches = categoryItems.filter { item in
                item.formalities.contains(formality) ||
                item.formalities.contains(where: { abs($0.rawValue - formality.rawValue) == 1 })
            }
            return formalMatches.isEmpty ? categoryItems : formalMatches
        }

        func choose(_ category: ClothingCategory) -> ClosetItem? {
            if let existing = selected.first(where: { $0.category == category }) {
                return existing
            }

            let reference = anchor ?? selected.first
            return candidates(for: category)
                .sorted { score($0, reference: reference, target: formality) > score($1, reference: reference, target: formality) }
                .prefix(3)
                .randomElement()
        }

        if hasLockedOnePiece {
            selected.removeAll { $0.category == .top || $0.category == .bottom }
        } else if !hasLockedSeparates,
                  let onePiece = choose(.onePiece),
                  Bool.random() {
            selected.append(onePiece)
        }

        if !selected.contains(where: { $0.category == .onePiece }) {
            guard let top = choose(.top) else { return .failure(.missingCategory("top")) }
            if !selected.contains(where: { $0.id == top.id }) { selected.append(top) }

            guard let bottom = choose(.bottom) else { return .failure(.missingCategory("bottom")) }
            if !selected.contains(where: { $0.id == bottom.id }) { selected.append(bottom) }
        }

        if let footwear = choose(.footwear), !selected.contains(where: { $0.id == footwear.id }) {
            selected.append(footwear)
        }

        let needsOuterwear = (weather.apparentTemperatureCelsius ?? weather.temperatureCelsius).map { $0 < 16 } ??
            [.autumn, .winter].contains(weather.season)
        if needsOuterwear,
           let outerwear = choose(.outerwear),
           !selected.contains(where: { $0.id == outerwear.id }) {
            selected.append(outerwear)
        }

        if occasion != .sport,
           let accessory = choose(.accessory),
           !selected.contains(where: { $0.id == accessory.id }),
           Bool.random() {
            selected.append(accessory)
        }

        let order: [ClothingCategory] = [.onePiece, .top, .bottom, .outerwear, .footwear, .accessory]
        selected.sort { lhs, rhs in
            (order.firstIndex(of: lhs.category) ?? 99) < (order.firstIndex(of: rhs.category) ?? 99)
        }

        let explanation = explanationFor(
            items: selected,
            locked: locked,
            occasion: occasion,
            formality: formality,
            weather: weather
        )

        return .success(.init(
            itemIDs: selected.map(\.id),
            occasion: occasion,
            formality: formality,
            weather: weather,
            explanation: explanation
        ))
    }

    private func score(_ item: ClosetItem, reference: ClosetItem?, target: FormalityLevel) -> Int {
        var value = Int.random(in: 0...4)
        if item.formalities.contains(target) { value += 14 }
        if item.isFavorite { value += 5 }
        if let reference {
            value += colorsWork(item.dominantColor, reference.dominantColor) ? 12 : -4
        }
        return value
    }

    private func colorsWork(_ lhs: ClothingColor, _ rhs: ClothingColor) -> Bool {
        if lhs == rhs || lhs.isNeutral || rhs.isNeutral { return true }
        let a = lhs.rgb
        let b = rhs.rgb
        let distance = sqrt(pow(a.red - b.red, 2) + pow(a.green - b.green, 2) + pow(a.blue - b.blue, 2))
        return distance < 0.48 || distance > 0.78
    }

    private func explanationFor(
        items: [ClosetItem],
        locked: [ClosetItem],
        occasion: Occasion,
        formality: FormalityLevel,
        weather: WeatherContext
    ) -> String {
        var parts: [String] = []
        if let firstLocked = locked.first {
            parts.append("Built around your locked \(firstLocked.name)")
        } else {
            parts.append("A \(formality.title.lowercased()) combination for \(occasion.title.lowercased())")
        }

        if let temperature = weather.displayTemperature {
            parts.append("balanced for \(temperature) and \(weather.summary.lowercased())")
        } else {
            parts.append("suited to \(weather.season.title.lowercased())")
        }

        let colorNames = Array(Set(items.map { $0.dominantColor.name })).prefix(3)
        if colorNames.count > 1 {
            parts.append("using \(colorNames.joined(separator: ", ").lowercased()) tones")
        }
        return parts.joined(separator: ", ") + "."
    }
}
