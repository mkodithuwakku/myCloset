import UIKit
import Vision

enum GarmentKind: String, CaseIterable, Equatable {
    case tShirt, shirt, blouse, tankTop, sweater, hoodie
    case trousers, jeans, shorts, skirt, leggings
    case dress, jumpsuit
    case coat, jacket, blazer, cardigan
    case sneakers, shoes, loafers, boots, sandals
    case watch, bag, scarf, belt, tie, hat

    var title: String {
        switch self {
        case .tShirt: "T-Shirt"
        case .tankTop: "Tank Top"
        default: rawValue.capitalized
        }
    }

    var category: ClothingCategory {
        switch self {
        case .tShirt, .shirt, .blouse, .tankTop, .sweater: .top
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
        case .sweater, .hoodie, .cardigan, .scarf:
            [.spring, .autumn, .winter]
        case .dress, .skirt:
            [.spring, .summer, .autumn]
        default:
            Set(WardrobeSeason.allCases)
        }
    }

    var suggestedFormalities: Set<FormalityLevel> {
        switch self {
        case .tShirt, .tankTop, .hoodie, .shorts, .leggings, .sneakers:
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

struct ClothingTypeDetection: Equatable {
    enum Source: Equatable {
        case filename
        case silhouette
        case vision
        case fallback
    }

    let category: ClothingCategory
    let kind: GarmentKind?
    let confidence: Float
    let source: Source

    var needsReview: Bool {
        source == .fallback || kind == nil || (source == .vision && confidence < 0.35)
    }
}

struct GarmentSilhouetteFeatures: Equatable {
    let heightToWidthRatio: Double
    let centerOccupancyByBand: [Double]

    private var middleCenterOccupancy: Double {
        let middle = centerOccupancyByBand.dropFirst(2).prefix(5)
        guard !middle.isEmpty else { return 0 }
        return middle.reduce(0, +) / Double(middle.count)
    }

    private var openEndCenterOccupancy: Double {
        min(centerOccupancyByBand.first ?? 1, centerOccupancyByBand.last ?? 1)
    }

    private var splitEndCenterOccupancy: Double {
        let firstEnd = centerOccupancyByBand.prefix(4)
        let lastEnd = centerOccupancyByBand.suffix(4)
        guard !firstEnd.isEmpty, !lastEnd.isEmpty else { return 1 }
        let firstAverage = firstEnd.reduce(0, +) / Double(firstEnd.count)
        let lastAverage = lastEnd.reduce(0, +) / Double(lastEnd.count)
        return min(firstAverage, lastAverage)
    }

    func suggestedBottomKind(
        jeansConfidence: Float,
        outerwearConfidence: Float = 0
    ) -> GarmentKind? {
        // Two separated legs leave the lower centre of a garment mask empty. This
        // is substantially more dependable than Apple's generic "clothing" and
        // "jacket" labels for distinguishing trousers from tops.
        if splitEndCenterOccupancy < 0.32 {
            return .trousers
        }

        // Shorts are compact, filled through the body, and open at one end. A
        // jacket can have a similar center opening, so a strong outerwear label
        // keeps the less-distinct short shape conservative.
        let looksLikeShorts = heightToWidthRatio < 0.9 &&
            openEndCenterOccupancy < 0.58 &&
            middleCenterOccupancy > 0.8
        if looksLikeShorts && (outerwearConfidence < 0.45 || jeansConfidence >= 0.35) {
            return .shorts
        }
        return nil
    }
}

enum ClothingTypeDetector {
    private struct Match {
        let kind: GarmentKind?
        let category: ClothingCategory
    }

    static func detect(in data: Data, filename: String? = nil) async -> ClothingTypeDetection {
        if let filename, let match = match(forText: filename) {
            return .init(category: match.category, kind: match.kind, confidence: 1, source: .filename)
        }

        return await Task.detached(priority: .userInitiated) {
            Self.classify(data)
        }.value
    }

    static func category(forFilename filename: String) -> ClothingCategory? {
        match(forText: filename)?.category
    }

    static func kind(forFilename filename: String) -> GarmentKind? {
        match(forText: filename)?.kind
    }

    static func suggestedName(
        filename: String?,
        category: ClothingCategory,
        kind: GarmentKind? = nil,
        dominantColor: ClothingColor? = nil,
        index: Int
    ) -> String {
        let garmentName = kind?.title ?? category.title
        if let filename, let cleaned = cleanedName(from: filename) {
            if let dominantColor, cleaned.caseInsensitiveCompare(garmentName) == .orderedSame {
                return "\(dominantColor.name) \(garmentName)"
            }
            return cleaned
        }

        if let dominantColor {
            return "\(dominantColor.name) \(garmentName)"
        }
        return "Imported \(garmentName) \(index)"
    }

    static func metadataName(category: ClothingCategory, dominantColor: ClothingColor) -> String {
        "\(dominantColor.name) \(category.title)"
    }

    private static func classify(_ data: Data) -> ClothingTypeDetection {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            return .init(category: .top, kind: nil, confidence: 0, source: .fallback)
        }

        let request = VNClassifyImageRequest()
        let maskRequest = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request, maskRequest])) != nil else {
            return .init(category: .top, kind: nil, confidence: 0, source: .fallback)
        }

        return detection(forVisionObservations: (request.results ?? []).map {
            (identifier: $0.identifier, confidence: $0.confidence)
        }, silhouette: silhouette(from: maskRequest.results?.first))
    }

    static func detection(
        forVisionObservations observations: [(identifier: String, confidence: Float)],
        silhouette: GarmentSilhouetteFeatures? = nil
    ) -> ClothingTypeDetection {
        let matches = observations.compactMap { observation -> (Match, Float)? in
            guard let match = match(forText: observation.identifier) else { return nil }
            return (match, observation.confidence)
        }

        let footwearMatches = matches.filter { match, _ in
            match.category == .footwear && match.kind != nil
        }
        if let best = footwearMatches.max(by: { $0.1 < $1.1 }), best.1 >= 0.08 {
            return .init(category: best.0.category, kind: best.0.kind, confidence: best.1, source: .vision)
        }

        let jeansConfidence = matches
            .filter { $0.0.kind == .jeans }
            .map(\.1)
            .max() ?? 0
        let outerwearConfidence = matches
            .filter { $0.0.category == .outerwear }
            .map(\.1)
            .max() ?? 0
        if let kind = silhouette?.suggestedBottomKind(
            jeansConfidence: jeansConfidence,
            outerwearConfidence: outerwearConfidence
        ) {
            return .init(category: .bottom, kind: kind, confidence: 0.9, source: .silhouette)
        }

        // Foreground shape gets first refusal for split-leg garments, then a
        // specific outerwear label can identify jackets and hoodies. The import
        // review remains the final authority when Vision is uncertain.
        let outerwearMatches = matches.filter { match, _ in
            match.category == .outerwear && match.kind != nil
        }
        if let best = outerwearMatches.max(by: { $0.1 < $1.1 }), best.1 >= 0.18 {
            return .init(category: .outerwear, kind: best.0.kind, confidence: best.1, source: .vision)
        }

        // Restrict the remaining semantic labels to garment kinds that Apple's
        // general image classifier identifies consistently.
        let reliableSpecificMatches = matches.filter { match, _ in
            guard let kind = match.kind else { return false }
            switch kind {
            case .dress, .jumpsuit, .watch, .bag, .scarf, .belt, .tie, .hat,
                    .tShirt, .shirt, .blouse, .tankTop, .sweater:
                return true
            case .trousers, .jeans, .shorts, .skirt, .leggings, .hoodie, .coat, .jacket,
                    .blazer, .cardigan, .sneakers, .shoes, .loafers, .boots, .sandals:
                return false
            }
        }
        if let best = reliableSpecificMatches.max(by: { $0.1 < $1.1 }), best.1 >= 0.18 {
            return .init(category: best.0.category, kind: best.0.kind, confidence: best.1, source: .vision)
        }

        let genericMatches = matches.filter { $0.0.kind == nil }
        if let best = genericMatches.max(by: { $0.1 < $1.1 }), best.1 >= 0.06 {
            if best.0.category == .top, silhouette != nil {
                return .init(category: .top, kind: nil, confidence: 0.7, source: .silhouette)
            }
            return .init(category: best.0.category, kind: nil, confidence: best.1, source: .vision)
        }

        return .init(
            category: .top,
            kind: nil,
            confidence: matches.map(\.1).max() ?? 0,
            source: .fallback
        )
    }

    private static func silhouette(from observation: VNInstanceMaskObservation?) -> GarmentSilhouetteFeatures? {
        guard let observation else { return nil }
        let buffer = observation.instanceMask
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        guard let reader = ForegroundMaskReader(buffer: buffer) else { return nil }

        var minimumX = width
        var maximumX = -1
        var minimumY = height
        var maximumY = -1
        for y in 0..<height {
            for x in 0..<width where reader.containsForeground(x: x, y: y) {
                minimumX = min(minimumX, x)
                maximumX = max(maximumX, x)
                minimumY = min(minimumY, y)
                maximumY = max(maximumY, y)
            }
        }

        guard maximumX > minimumX, maximumY > minimumY else { return nil }
        let garmentWidth = maximumX - minimumX + 1
        let garmentHeight = maximumY - minimumY + 1
        let centreStart = minimumX + Int(Double(garmentWidth) * 0.4)
        let centreEnd = minimumX + Int(Double(garmentWidth) * 0.6)
        let bandCount = 10
        var occupancy: [Double] = []

        for band in 0..<bandCount {
            let startY = minimumY + garmentHeight * band / bandCount
            let endY = minimumY + garmentHeight * (band + 1) / bandCount
            var foreground = 0
            var total = 0
            for y in startY..<max(startY + 1, endY) {
                for x in centreStart...max(centreStart, centreEnd) {
                    total += 1
                    if reader.containsForeground(x: x, y: y) { foreground += 1 }
                }
            }
            occupancy.append(total == 0 ? 1 : Double(foreground) / Double(total))
        }

        return .init(
            heightToWidthRatio: Double(garmentHeight) / Double(garmentWidth),
            centerOccupancyByBand: occupancy
        )
    }

    private static func match(forText text: String) -> Match? {
        let normalized = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let value = " \(normalized) "

        if value.contains(" shirt dress ") {
            return Match(kind: .dress, category: .onePiece)
        }

        let kindRules: [(GarmentKind, [String])] = [
            (.tShirt, ["t shirt", "tshirt", "tee shirt", " tee "]),
            (.tankTop, ["tank top", "singlet"]),
            (.blouse, ["blouse"]),
            (.hoodie, ["hoodie", "hooded sweatshirt"]),
            (.sweater, ["sweater", "sweatshirt", "pullover", "jersey"]),
            (.shirt, ["dress shirt", "oxford shirt", " shirt "]),
            (.shorts, ["short pants", " shorts ", "swim trunks", "trunks"]),
            (.jeans, ["jeans", "denim pants", "blue jean"]),
            (.trousers, ["trouser", " pants ", "chino", "slacks"]),
            (.skirt, ["skirt", "miniskirt"]),
            (.leggings, ["legging", "tights"]),
            (.jumpsuit, ["jumpsuit", "romper", "one piece"]),
            (.dress, ["shirt dress", " dress ", "gown"]),
            (.blazer, ["blazer", "sport coat"]),
            (.coat, ["overcoat", "raincoat", "trench", "parka", " coat "]),
            (.jacket, ["windbreaker", " jacket "]),
            (.cardigan, ["cardigan"]),
            (.sneakers, ["sneaker", "trainer", "running shoe", "tennis shoe"]),
            (.loafers, ["loafer", "moccasin"]),
            (.boots, [" boot ", "boots"]),
            (.sandals, ["sandal", "slipper", "clog"]),
            (.shoes, [" shoe ", "footwear"]),
            (.watch, ["watch", "timepiece"]),
            (.bag, ["handbag", "purse", "backpack", "tote bag"]),
            (.scarf, ["scarf", "shawl"]),
            (.belt, [" belt "]),
            (.tie, ["necktie", "bow tie", " tie "]),
            (.hat, [" hat ", " cap ", "beanie"])
        ]

        if let rule = kindRules.first(where: { _, keywords in
            keywords.contains { value.contains($0) }
        }) {
            return Match(kind: rule.0, category: rule.0.category)
        }

        let categoryRules: [(ClothingCategory, [String])] = [
            (.footwear, ["footwear"]),
            (.outerwear, ["outerwear"]),
            (.onePiece, ["onepiece"]),
            (.bottom, ["bottoms", "bottomwear"]),
            (.accessory, ["accessory", "sunglass", "glasses"]),
            (.top, ["clothing", "apparel", " top "])
        ]

        return categoryRules.first { _, keywords in
            keywords.contains { value.contains($0) }
        }.map { Match(kind: nil, category: $0.0) }
    }

    private static func cleanedName(from filename: String) -> String? {
        let stem = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let words = stem.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let normalized = words.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = normalized.lowercased()
        let genericPrefixes = ["image ", "images ", "photo ", "scan "]

        guard !normalized.isEmpty,
              !["image", "images", "photo", "scan"].contains(lowercased),
              !genericPrefixes.contains(where: lowercased.hasPrefix),
              !lowercased.hasPrefix("img "),
              !lowercased.hasPrefix("dsc "),
              !lowercased.hasPrefix("screenshot "),
              !looksMachineGenerated(normalized) else {
            return nil
        }
        return normalized.capitalized
    }

    private static func looksMachineGenerated(_ value: String) -> Bool {
        let compact = value.replacingOccurrences(of: " ", with: "")
        let hexadecimal = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return compact.count >= 12 && compact.unicodeScalars.allSatisfy(hexadecimal.contains)
    }
}

struct ImportedClosetPiece {
    let item: ClosetItem
    let detection: ClothingTypeDetection
}

enum ClosetImageImporter {
    static func makePiece(from rawData: Data, filename: String? = nil, index: Int) async -> ImportedClosetPiece? {
        guard let prepared = await Task.detached(priority: .userInitiated, operation: {
            ImageUtilities.preparedImageData(from: rawData)
        }).value else { return nil }
        async let detectionTask = ClothingTypeDetector.detect(in: prepared, filename: filename)
        async let colorsTask = Task.detached(priority: .userInitiated) {
            ImageUtilities.suggestedColors(from: prepared)
        }.value
        let (detection, colors) = await (detectionTask, colorsTask)
        let fallbackColor = ClothingColor.palette.first { $0.name == "Grey" } ?? ClothingColor.palette[0]
        let dominantColor = colors?.dominant ?? fallbackColor
        let name = ClothingTypeDetector.suggestedName(
            filename: filename,
            category: detection.category,
            kind: detection.kind,
            dominantColor: dominantColor,
            index: index
        )

        let item = ClosetItem(
            name: name,
            category: detection.category,
            photoData: prepared,
            dominantColor: dominantColor,
            accentColor: colors?.accent,
            seasons: detection.kind?.suggestedSeasons ?? Set(WardrobeSeason.allCases),
            formalities: detection.kind?.suggestedFormalities ?? defaultFormalities(for: detection.category)
        )
        return .init(item: item, detection: detection)
    }

    static func defaultFormalities(for category: ClothingCategory) -> Set<FormalityLevel> {
        switch category {
        case .footwear: [.active, .veryCasual, .casual, .smartCasual]
        case .outerwear: [.casual, .smartCasual, .business]
        case .accessory: [.casual, .smartCasual, .business, .formal]
        case .top, .bottom, .onePiece: [.veryCasual, .casual, .smartCasual]
        }
    }
}
