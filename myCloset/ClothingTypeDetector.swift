import UIKit
import Vision

struct ClothingTypeDetection: Equatable {
    enum Source: Equatable {
        case filename
        case vision
        case fallback
    }

    let category: ClothingCategory
    let confidence: Float
    let source: Source

    var needsReview: Bool {
        source == .fallback || (source == .vision && confidence < 0.18)
    }
}

enum ClothingTypeDetector {
    static func detect(in data: Data, filename: String? = nil) async -> ClothingTypeDetection {
        if let filename,
           let category = category(forText: filename) {
            return .init(category: category, confidence: 1, source: .filename)
        }

        return await Task.detached(priority: .userInitiated) {
            Self.classify(data)
        }.value
    }

    static func category(forFilename filename: String) -> ClothingCategory? {
        category(forText: filename)
    }

    static func suggestedName(filename: String?, category: ClothingCategory, index: Int) -> String {
        guard let filename else { return "Imported \(category.title) \(index)" }
        let stem = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let words = stem
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let normalized = words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty,
              !normalized.lowercased().hasPrefix("img "),
              !normalized.lowercased().hasPrefix("dsc ") else {
            return "Imported \(category.title) \(index)"
        }
        return normalized.capitalized
    }

    private static func classify(_ data: Data) -> ClothingTypeDetection {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            return .init(category: .top, confidence: 0, source: .fallback)
        }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil else {
            return .init(category: .top, confidence: 0, source: .fallback)
        }

        let matches = (request.results ?? []).compactMap { observation -> (ClothingCategory, Float)? in
            guard let category = category(forText: observation.identifier) else { return nil }
            return (category, observation.confidence)
        }

        guard let best = matches.max(by: { $0.1 < $1.1 }), best.1 >= 0.06 else {
            return .init(category: .top, confidence: matches.map(\.1).max() ?? 0, source: .fallback)
        }
        return .init(category: best.0, confidence: best.1, source: .vision)
    }

    private static func category(forText text: String) -> ClothingCategory? {
        let value = text
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        let rules: [(ClothingCategory, [String])] = [
            (.footwear, ["sneaker", "trainer", "running shoe", "shoe", "loafer", "boot", "sandal", "slipper", "moccasin", "clog"]),
            (.outerwear, ["overcoat", "raincoat", "trench", "parka", "windbreaker", "jacket", "blazer", "cardigan", "coat", "poncho"]),
            (.onePiece, ["jumpsuit", "romper", "one piece", "dress", "gown"]),
            (.bottom, ["trouser", "pants", "jeans", "denim", "skirt", "shorts", "legging", "chino"]),
            (.top, ["t shirt", "tshirt", "tee", "shirt", "blouse", "sweater", "sweatshirt", "hoodie", "pullover", "jersey", "tank top", "top"]),
            (.accessory, ["sunglass", "glasses", "handbag", "purse", "backpack", "watch", "scarf", "belt", "necktie", "tie", "hat", "cap", "beanie"])
        ]

        return rules.first { _, keywords in
            keywords.contains { value.contains($0) }
        }?.0
    }
}

struct ImportedClosetPiece {
    let item: ClosetItem
    let detection: ClothingTypeDetection
}

enum TestClosetImageImporter {
    static func makePiece(
        from rawData: Data,
        filename: String? = nil,
        index: Int
    ) async -> ImportedClosetPiece? {
        guard let prepared = ImageUtilities.preparedImageData(from: rawData) else { return nil }
        let detection = await ClothingTypeDetector.detect(in: prepared, filename: filename)
        let colors = ImageUtilities.suggestedColors(from: prepared)
        let fallbackColor = ClothingColor.palette.first { $0.name == "Navy" } ?? ClothingColor.palette[0]
        let name = ClothingTypeDetector.suggestedName(
            filename: filename,
            category: detection.category,
            index: index
        )

        let item = ClosetItem(
            name: name,
            category: detection.category,
            photoData: prepared,
            dominantColor: colors?.dominant ?? fallbackColor,
            accentColor: colors?.accent,
            seasons: Set(WardrobeSeason.allCases),
            formalities: defaultFormalities(for: detection.category)
        )
        return .init(item: item, detection: detection)
    }

    private static func defaultFormalities(for category: ClothingCategory) -> Set<FormalityLevel> {
        switch category {
        case .footwear:
            [.active, .veryCasual, .casual, .smartCasual]
        case .outerwear:
            [.casual, .smartCasual, .business]
        case .accessory:
            [.casual, .smartCasual, .business, .formal]
        case .top, .bottom, .onePiece:
            [.veryCasual, .casual, .smartCasual]
        }
    }
}
