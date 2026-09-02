import CoreGraphics
import UIKit
import Vision

struct ForegroundMaskReader {
    private let baseAddress: UnsafeMutableRawPointer
    private let bytesPerRow: Int
    private let pixelFormat: OSType

    init?(buffer: CVPixelBuffer) {
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        self.baseAddress = baseAddress
        bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        pixelFormat = CVPixelBufferGetPixelFormatType(buffer)
    }

    func containsForeground(x: Int, y: Int) -> Bool {
        let row = baseAddress.advanced(by: y * bytesPerRow)
        switch pixelFormat {
        case kCVPixelFormatType_OneComponent8:
            return row.assumingMemoryBound(to: UInt8.self)[x] != 0
        case kCVPixelFormatType_OneComponent16Half:
            return row.assumingMemoryBound(to: UInt16.self)[x] != 0
        case kCVPixelFormatType_OneComponent32Float:
            return row.assumingMemoryBound(to: Float.self)[x] > 0.001
        default:
            return false
        }
    }
}

enum ImageUtilities {
    static func preparedImageData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maximumDimension: CGFloat = 1_200
        let scale = min(1, maximumDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        // Persist a predictable pixel size regardless of the source device's screen scale.
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.82)
    }

    static func suggestedColors(from data: Data) -> (dominant: ClothingColor, accent: ClothingColor?)? {
        guard let source = UIImage(data: data), let cgImage = source.cgImage else { return nil }
        let width = 64
        let height = 64
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let background = estimatedBackground(in: pixels, width: width, height: height, bytesPerRow: bytesPerRow)
        let foregroundMask = foregroundMask(for: cgImage, width: width, height: height)
        let foregroundSamples = foregroundMask.map {
            colorSamples(
                in: pixels,
                width: width,
                height: height,
                bytesPerRow: bytesPerRow,
                including: $0,
                excluding: background
            )
        } ?? []
        let backgroundFilteredSamples = colorSamples(
            in: pixels,
            width: width,
            height: height,
            bytesPerRow: bytesPerRow,
            including: nil,
            excluding: background
        )
        let samples = foregroundSamples.count >= 120
            ? foregroundSamples
            : (backgroundFilteredSamples.count >= 120
                ? backgroundFilteredSamples
                : colorSamples(
                    in: pixels,
                    width: width,
                    height: height,
                    bytesPerRow: bytesPerRow,
                    including: nil,
                    excluding: nil
                ))

        return rankedColors(from: samples)
    }

    struct ColorSample {
        let red: Double
        let green: Double
        let blue: Double
        let weight: Int
    }

    static func rankedColors(from samples: [ColorSample]) -> (dominant: ClothingColor, accent: ClothingColor?)? {
        var buckets: [ClothingColor: Int] = [:]
        for sample in samples {
            let mapped = perceptuallyNearest(red: sample.red, green: sample.green, blue: sample.blue)
            buckets[mapped, default: 0] += sample.weight
        }

        let ranked = buckets.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key.name < rhs.key.name : lhs.value > rhs.value
        }
        guard let dominant = ranked.first else { return nil }
        let totalWeight = ranked.reduce(0) { $0 + $1.value }
        let minimumAccentWeight = max(
            Int(ceil(Double(totalWeight) * 0.20)),
            Int(ceil(Double(dominant.value) * 0.30))
        )
        let accent = ranked.dropFirst().first { candidate in
            candidate.value >= minimumAccentWeight &&
                labDistance(candidate.key.rgb, dominant.key.rgb) >= 12
        }?.key
        return (dominant.key, accent)
    }

    private static func estimatedBackground(
        in pixels: [UInt8],
        width: Int,
        height: Int,
        bytesPerRow: Int
    ) -> (red: Double, green: Double, blue: Double)? {
        var border: [(red: Double, green: Double, blue: Double)] = []
        let borderWidth = 3

        for y in 0..<height {
            for x in 0..<width where x < borderWidth || x >= width - borderWidth || y < borderWidth || y >= height - borderWidth {
                let index = y * bytesPerRow + x * 4
                guard pixels[index + 3] > 50 else { continue }
                border.append((
                    Double(pixels[index]) / 255,
                    Double(pixels[index + 1]) / 255,
                    Double(pixels[index + 2]) / 255
                ))
            }
        }

        guard !border.isEmpty else { return nil }
        let count = Double(border.count)
        let average = (
            red: border.reduce(0) { $0 + $1.0 } / count,
            green: border.reduce(0) { $0 + $1.1 } / count,
            blue: border.reduce(0) { $0 + $1.2 } / count
        )
        let variance = border.reduce(0) { result, color in
            result + squaredDistance(color, average)
        } / count

        // Only treat the border as background when it is visually consistent.
        return variance < 0.025 ? average : nil
    }

    private static func colorSamples(
        in pixels: [UInt8],
        width: Int,
        height: Int,
        bytesPerRow: Int,
        including foregroundMask: [Bool]?,
        excluding background: (red: Double, green: Double, blue: Double)?
    ) -> [ColorSample] {
        var samples: [ColorSample] = []
        let centerX = Double(width - 1) / 2
        let centerY = Double(height - 1) / 2

        for y in 0..<height {
            for x in 0..<width {
                if let foregroundMask, !foregroundMask[y * width + x] { continue }
                let index = y * bytesPerRow + x * 4
                guard pixels[index + 3] > 50 else { continue }
                let color = (
                    red: Double(pixels[index]) / 255,
                    green: Double(pixels[index + 1]) / 255,
                    blue: Double(pixels[index + 2]) / 255
                )
                if let background, squaredDistance(color, background) < 0.035 {
                    continue
                }
                let isCentral = abs(Double(x) - centerX) < Double(width) * 0.25 &&
                    abs(Double(y) - centerY) < Double(height) * 0.25
                samples.append(.init(red: color.red, green: color.green, blue: color.blue, weight: isCentral ? 5 : 1))
            }
        }
        return samples
    }

    private static func foregroundMask(for cgImage: CGImage, width: Int, height: Int) -> [Bool]? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first,
              !observation.allInstances.isEmpty else {
            return nil
        }

        var bestMask: [Bool]?
        var bestScore = -Double.infinity
        for instance in observation.allInstances {
            guard let buffer = try? observation.generateScaledMaskForImage(
                forInstances: IndexSet(integer: instance),
                from: handler
            ), let candidate = sampledMask(from: buffer, width: width, height: height) else {
                continue
            }

            let score = foregroundScore(candidate, width: width, height: height)
            if score > bestScore {
                bestScore = score
                bestMask = candidate
            }
        }

        guard let bestMask else { return nil }
        let inset = eroded(bestMask, width: width, height: height)
        return inset.filter { $0 }.count >= 120 ? inset : bestMask
    }

    private static func sampledMask(from buffer: CVPixelBuffer, width: Int, height: Int) -> [Bool]? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let maskWidth = CVPixelBufferGetWidth(buffer)
        let maskHeight = CVPixelBufferGetHeight(buffer)
        guard let reader = ForegroundMaskReader(buffer: buffer) else { return nil }
        var mask = [Bool](repeating: false, count: width * height)

        for y in 0..<height {
            let maskY = min(maskHeight - 1, y * maskHeight / height)
            for x in 0..<width {
                let maskX = min(maskWidth - 1, x * maskWidth / width)
                mask[y * width + x] = reader.containsForeground(x: maskX, y: maskY)
            }
        }
        return mask
    }

    private static func foregroundScore(_ mask: [Bool], width: Int, height: Int) -> Double {
        let centerX = Double(width - 1) / 2
        let centerY = Double(height - 1) / 2
        let maximumDistance = hypot(centerX, centerY)
        var count = 0
        var centrality = 0.0

        for y in 0..<height {
            for x in 0..<width where mask[y * width + x] {
                count += 1
                let distance = hypot(Double(x) - centerX, Double(y) - centerY)
                centrality += max(0, 1 - distance / maximumDistance)
            }
        }

        guard count > 0 else { return -Double.infinity }
        let areaRatio = Double(count) / Double(width * height)
        let frameFillingPenalty = areaRatio > 0.65 ? 0.08 : 1
        return Double(count) * (1 + 0.75 * centrality / Double(count)) * frameFillingPenalty
    }

    private static func eroded(_ mask: [Bool], width: Int, height: Int) -> [Bool] {
        var result = [Bool](repeating: false, count: mask.count)
        guard width > 2, height > 2 else { return result }

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) where mask[y * width + x] {
                var neighbours = 0
                for offsetY in -1...1 {
                    for offsetX in -1...1 where mask[(y + offsetY) * width + x + offsetX] {
                        neighbours += 1
                    }
                }
                result[y * width + x] = neighbours >= 8
            }
        }
        return result
    }

    private struct LabColor {
        let lightness: Double
        let a: Double
        let b: Double
    }

    private static func perceptuallyNearest(red: Double, green: Double, blue: Double) -> ClothingColor {
        let source = lab(red: red, green: green, blue: blue)
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let saturation = maximum == 0 ? 0 : (maximum - minimum) / maximum
        let hue = hueDegrees(red: red, green: green, blue: blue)
        if maximum < 0.16 || (source.lightness < 24 && saturation < 0.22) {
            return paletteColor(named: "Black")
        }
        if saturation < 0.22 {
            if source.lightness < 40 { return paletteColor(named: "Black") }
            if source.lightness > 78 { return paletteColor(named: "White") }
            if saturation > 0.06 && source.lightness > 52 && (15..<75).contains(hue) {
                return paletteColor(named: "Beige")
            }
            return paletteColor(named: "Grey")
        }

        switch hue {
        case 0..<16, 344...360:
            return paletteColor(named: source.lightness > 70 ? "Pink" : "Red")
        case 16..<45:
            if source.lightness > 66 && saturation < 0.38 { return paletteColor(named: "Beige") }
            return paletteColor(named: source.lightness < 48 ? "Brown" : "Orange")
        case 45..<70:
            return paletteColor(named: saturation < 0.28 ? "Beige" : "Yellow")
        case 70..<165:
            return paletteColor(named: "Green")
        case 165..<195:
            return paletteColor(named: "Teal")
        case 195..<255:
            return paletteColor(named: source.lightness < 34 ? "Navy" : "Blue")
        case 255..<295:
            return paletteColor(named: "Purple")
        default:
            return paletteColor(named: source.lightness > 64 ? "Pink" : "Purple")
        }
    }

    private static func paletteColor(named name: String) -> ClothingColor {
        ClothingColor.palette.first { $0.name == name } ?? ClothingColor.palette[2]
    }

    private static func hueDegrees(red: Double, green: Double, blue: Double) -> Double {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum
        guard delta > 0 else { return 0 }

        let hue: Double
        if maximum == red {
            hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maximum == green {
            hue = 60 * ((blue - red) / delta + 2)
        } else {
            hue = 60 * ((red - green) / delta + 4)
        }
        return hue < 0 ? hue + 360 : hue
    }

    private static func labDistance(
        _ lhs: (red: Double, green: Double, blue: Double),
        _ rhs: (red: Double, green: Double, blue: Double)
    ) -> Double {
        let first = lab(red: lhs.red, green: lhs.green, blue: lhs.blue)
        let second = lab(red: rhs.red, green: rhs.green, blue: rhs.blue)
        return sqrt(
            pow(first.lightness - second.lightness, 2) +
                pow(first.a - second.a, 2) +
                pow(first.b - second.b, 2)
        )
    }

    private static func lab(red: Double, green: Double, blue: Double) -> LabColor {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        let r = linear(red)
        let g = linear(green)
        let b = linear(blue)
        let x = (r * 0.4124564 + g * 0.3575761 + b * 0.1804375) / 0.95047
        let y = r * 0.2126729 + g * 0.7151522 + b * 0.072175
        let z = (r * 0.0193339 + g * 0.119192 + b * 0.9503041) / 1.08883

        func transform(_ value: Double) -> Double {
            value > 0.008856 ? pow(value, 1.0 / 3.0) : 7.787 * value + 16.0 / 116.0
        }

        let transformedX = transform(x)
        let transformedY = transform(y)
        let transformedZ = transform(z)
        return LabColor(
            lightness: 116 * transformedY - 16,
            a: 500 * (transformedX - transformedY),
            b: 200 * (transformedY - transformedZ)
        )
    }

    private static func squaredDistance(
        _ lhs: (red: Double, green: Double, blue: Double),
        _ rhs: (red: Double, green: Double, blue: Double)
    ) -> Double {
        pow(lhs.red - rhs.red, 2) + pow(lhs.green - rhs.green, 2) + pow(lhs.blue - rhs.blue, 2)
    }
}
