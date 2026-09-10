import CoreGraphics
import CoreImage
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
        instanceIdentifier(x: x, y: y) != 0
    }

    func instanceIdentifier(x: Int, y: Int) -> Int {
        let row = baseAddress.advanced(by: y * bytesPerRow)
        switch pixelFormat {
        case kCVPixelFormatType_OneComponent8:
            return Int(row.assumingMemoryBound(to: UInt8.self)[x])
        case kCVPixelFormatType_OneComponent16Half:
            let rawValue = row.assumingMemoryBound(to: UInt16.self)[x]
            return Int(Float16(bitPattern: rawValue).rounded())
        case kCVPixelFormatType_OneComponent32Float:
            return Int(row.assumingMemoryBound(to: Float.self)[x].rounded())
        default:
            return 0
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
        return resized.jpegData(compressionQuality: 0.92)
    }

    static func rotatedImageData(from data: Data, quarterTurns: Int) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let normalizedTurns = ((quarterTurns % 4) + 4) % 4
        guard normalizedTurns != 0 else { return data }

        let swapsDimensions = normalizedTurns.isMultiple(of: 2) == false
        let outputSize = swapsDimensions
            ? CGSize(width: image.size.height, height: image.size.width)
            : image.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
        let rotated = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: outputSize.width / 2, y: outputSize.height / 2)
            cgContext.rotate(by: CGFloat(normalizedTurns) * .pi / 2)
            image.draw(
                in: CGRect(
                    x: -image.size.width / 2,
                    y: -image.size.height / 2,
                    width: image.size.width,
                    height: image.size.height
                )
            )
        }
        return preparedImageData(from: rotated.jpegData(compressionQuality: 0.9) ?? Data())
    }

    static func outlinedCutoutData(
        from data: Data,
        normalizedOutlines: [[CGPoint]]
    ) -> Data? {
        guard let source = UIImage(data: data),
              normalizedOutlines.contains(where: { $0.count >= 3 }) else { return nil }
        let maximumDimension: CGFloat = 1_200
        let scale = min(1, maximumDimension / max(source.size.width, source.size.height))
        let size = CGSize(width: source.size.width * scale, height: source.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        let mask = UIGraphicsImageRenderer(size: size, format: format).image { rendererContext in
            let context = rendererContext.cgContext
            context.setFillColor(UIColor.white.cgColor)
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            for outline in normalizedOutlines where outline.count >= 3 {
                let points = outline.map { point in
                    CGPoint(
                        x: min(1, max(0, point.x)) * size.width,
                        y: min(1, max(0, point.y)) * size.height
                    )
                }
                guard let first = points.first else { continue }
                context.beginPath()
                context.move(to: first)
                for point in points.dropFirst() { context.addLine(to: point) }
                context.closePath()
                context.fillPath()
            }
        }

        let normalizedSource = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            source.draw(in: CGRect(origin: .zero, size: size))
        }
        let cutout = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            normalizedSource.draw(in: CGRect(origin: .zero, size: size))
            // Keep the mask in UIKit's top-left coordinates, just like the
            // source and lasso preview. Drawing its raw CGImage here flips
            // it vertically and cuts away correctly outlined hems/sleeves.
            mask.draw(in: CGRect(origin: .zero, size: size), blendMode: .destinationIn, alpha: 1)
        }
        guard let cutoutImage = cutout.cgImage,
              let cropped = croppedToVisibleAlpha(cutoutImage) else { return nil }
        return transparentImageData(from: UIImage(cgImage: cropped))
    }

    static func isolatedGarmentData(from data: Data) -> Data? {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else { return nil }
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first,
              let instance = bestForegroundInstance(
                in: observation,
                width: 64,
                height: 64
              ),
              let sampled = sampledMask(
                from: observation.instanceMask,
                instance: instance,
                width: 64,
                height: 64
              ),
              maskHasCredibleGarmentCoverage(sampled, width: 64, height: 64),
              let mask = binaryMaskImage(from: observation.instanceMask, instance: instance) else {
            return adaptiveBorderCutout(from: cgImage)
        }

        let sourceImage = CIImage(cgImage: cgImage)
        let sourceExtent = sourceImage.extent
        let maskImage = CIImage(cgImage: mask).transformed(
            by: CGAffineTransform(
                scaleX: sourceExtent.width / CGFloat(mask.width),
                y: sourceExtent.height / CGFloat(mask.height)
            )
        ).cropped(to: sourceExtent)
        let clearBackground = CIImage(color: CIColor.clear).cropped(to: sourceImage.extent)
        let isolatedImage = sourceImage.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: clearBackground,
                kCIInputMaskImageKey: maskImage
            ]
        ).cropped(to: sourceImage.extent)
        let context = CIContext(options: nil)
        guard let fullSize = context.createCGImage(isolatedImage, from: sourceImage.extent),
              let isolated = croppedToVisibleAlpha(fullSize) else {
            return adaptiveBorderCutout(from: cgImage)
        }
        return transparentImageData(from: UIImage(cgImage: isolated))
    }

    /// A conservative local fallback for environments where Vision's foreground
    /// model is unavailable (notably some Simulator runtimes). It models several
    /// colors around the photo border rather than one average background color,
    /// which handles floorboards and patterned rugs without treating their mean as
    /// a garment color. Ambiguous results are rejected rather than presenting a
    /// visibly damaged automatic cutout as a trustworthy suggestion.
    private static func adaptiveBorderCutout(from source: CGImage) -> Data? {
        let maximumDimension = 1_200.0
        let scale = min(1, maximumDimension / Double(max(source.width, source.height)))
        let width = max(1, Int((Double(source.width) * scale).rounded()))
        let height = max(1, Int((Double(source.height) * scale).rounded()))
        let bytesPerRow = width * 4
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
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))

        struct Bucket {
            var red = 0
            var green = 0
            var blue = 0
            var count = 0
        }
        let borderWidth = max(4, min(width, height) / 24)
        var buckets: [Int: Bucket] = [:]
        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2)
            where x < borderWidth || x >= width - borderWidth || y < borderWidth || y >= height - borderWidth {
                let index = y * bytesPerRow + x * 4
                let key = (Int(pixels[index]) / 16) << 8 |
                    (Int(pixels[index + 1]) / 16) << 4 |
                    Int(pixels[index + 2]) / 16
                var bucket = buckets[key, default: Bucket()]
                bucket.red += Int(pixels[index])
                bucket.green += Int(pixels[index + 1])
                bucket.blue += Int(pixels[index + 2])
                bucket.count += 1
                buckets[key] = bucket
            }
        }
        let palette = buckets.values
            .sorted { $0.count > $1.count }
            .prefix(32)
            .map { bucket in
                (
                    red: Double(bucket.red) / Double(bucket.count * 255),
                    green: Double(bucket.green) / Double(bucket.count * 255),
                    blue: Double(bucket.blue) / Double(bucket.count * 255)
                )
            }
        guard !palette.isEmpty else { return nil }

        let clearDistance = 0.010
        let solidDistance = 0.040
        for y in 0..<height {
            for x in 0..<width {
                let index = y * bytesPerRow + x * 4
                let color = (
                    red: Double(pixels[index]) / 255,
                    green: Double(pixels[index + 1]) / 255,
                    blue: Double(pixels[index + 2]) / 255
                )
                let distance = palette.reduce(Double.infinity) {
                    min($0, squaredDistance(color, $1))
                }
                let alpha: Double
                if distance <= clearDistance {
                    alpha = 0
                } else if distance >= solidDistance {
                    alpha = 1
                } else {
                    alpha = (distance - clearDistance) / (solidDistance - clearDistance)
                }

                // The buffer is premultiplied-alpha, so scale color channels too.
                pixels[index] = UInt8((Double(pixels[index]) * alpha).rounded())
                pixels[index + 1] = UInt8((Double(pixels[index + 1]) * alpha).rounded())
                pixels[index + 2] = UInt8((Double(pixels[index + 2]) * alpha).rounded())
                pixels[index + 3] = UInt8((255 * alpha).rounded())
            }
        }

        // Any surviving region connected to the image edge is much more likely to
        // be floor or wall texture than the centered garment. Remove it, including
        // its antialiased fringe, before deciding whether the fallback is credible.
        var connectedToBorder = [Bool](repeating: false, count: width * height)
        var queue: [Int] = []
        func enqueue(_ x: Int, _ y: Int) {
            let pixel = y * width + x
            guard !connectedToBorder[pixel], pixels[y * bytesPerRow + x * 4 + 3] > 20 else { return }
            connectedToBorder[pixel] = true
            queue.append(pixel)
        }
        for x in 0..<width {
            enqueue(x, 0)
            enqueue(x, height - 1)
        }
        for y in 0..<height {
            enqueue(0, y)
            enqueue(width - 1, y)
        }
        var cursor = 0
        while cursor < queue.count {
            let pixel = queue[cursor]
            cursor += 1
            let x = pixel % width
            let y = pixel / width
            if x > 0 { enqueue(x - 1, y) }
            if x + 1 < width { enqueue(x + 1, y) }
            if y > 0 { enqueue(x, y - 1) }
            if y + 1 < height { enqueue(x, y + 1) }
        }

        var visibleCount = 0
        var centralVisibleCount = 0
        let centerX = (width * 3 / 10)..<(width * 7 / 10)
        let centerY = (height * 3 / 10)..<(height * 7 / 10)
        for y in 0..<height {
            for x in 0..<width {
                let pixel = y * width + x
                let index = y * bytesPerRow + x * 4
                if connectedToBorder[pixel] {
                    pixels[index] = 0
                    pixels[index + 1] = 0
                    pixels[index + 2] = 0
                    pixels[index + 3] = 0
                } else if pixels[index + 3] > 115 {
                    visibleCount += 1
                    if centerX.contains(x), centerY.contains(y) {
                        centralVisibleCount += 1
                    }
                }
            }
        }

        let visibleRatio = Double(visibleCount) / Double(width * height)
        let centerArea = max(1, centerX.count * centerY.count)
        let centralVisibleRatio = Double(centralVisibleCount) / Double(centerArea)
        var minimumX = width
        var minimumY = height
        var maximumX = -1
        var maximumY = -1
        for y in 0..<height {
            for x in 0..<width where pixels[y * bytesPerRow + x * 4 + 3] > 115 {
                minimumX = min(minimumX, x)
                minimumY = min(minimumY, y)
                maximumX = max(maximumX, x)
                maximumY = max(maximumY, y)
            }
        }
        let boundingArea = max(1, (maximumX - minimumX + 1) * (maximumY - minimumY + 1))
        let boundingFillRatio = Double(visibleCount) / Double(boundingArea)
        guard (0.025...0.72).contains(visibleRatio),
              centralVisibleRatio >= 0.16,
              boundingFillRatio >= 0.22,
              let masked = context.makeImage(),
              let cropped = croppedToVisibleAlpha(masked) else {
            return nil
        }
        return transparentImageData(from: UIImage(cgImage: cropped))
    }

    private static func transparentImageData(from image: UIImage) -> Data? {
        let maximumDimension: CGFloat = 1_200
        let scale = min(1, maximumDimension / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }.pngData()
    }

    static func croppedToVisibleAlpha(_ image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
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
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var minimumX = width
        var minimumY = height
        var maximumX = -1
        var maximumY = -1
        for y in 0..<height {
            for x in 0..<width where pixels[y * bytesPerRow + x * 4 + 3] > 20 {
                minimumX = min(minimumX, x)
                minimumY = min(minimumY, y)
                maximumX = max(maximumX, x)
                maximumY = max(maximumY, y)
            }
        }
        guard maximumX >= minimumX, maximumY >= minimumY else { return nil }

        let padding = max(4, Int(Double(max(width, height)) * 0.015))
        let crop = CGRect(
            x: max(0, minimumX - padding),
            y: max(0, minimumY - padding),
            width: min(width - max(0, minimumX - padding), maximumX - minimumX + 1 + padding * 2),
            height: min(height - max(0, minimumY - padding), maximumY - minimumY + 1 + padding * 2)
        )
        return image.cropping(to: crop)
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
        // A saved cutout already carries the most reliable foreground boundary in
        // its alpha channel. Avoid rerunning Vision and sample only opaque pixels.
        let hasTransparency = hasTransparentPixels(
            pixels,
            bytesPerRow: bytesPerRow,
            width: width,
            height: height
        )
        let foregroundMask = hasTransparency
            ? nil
            : foregroundMask(for: cgImage, width: width, height: height)
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

        guard let ranked = rankedColors(from: samples) else { return nil }
        let hasReliableForeground = hasTransparency || foregroundSamples.count >= 120
        return (
            dominant: ranked.dominant,
            accent: hasReliableForeground ? ranked.accent : nil
        )
    }

    private static func hasTransparentPixels(
        _ pixels: [UInt8],
        bytesPerRow: Int,
        width: Int,
        height: Int
    ) -> Bool {
        for y in 0..<height {
            for x in 0..<width where pixels[y * bytesPerRow + x * 4 + 3] < 50 {
                return true
            }
        }
        return false
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
              let instance = bestForegroundInstance(
                in: observation,
                width: width,
                height: height
              ),
              let bestMask = sampledMask(
                from: observation.instanceMask,
                instance: instance,
                width: width,
                height: height
              ) else {
            return nil
        }

        let inset = eroded(bestMask, width: width, height: height)
        return inset.filter { $0 }.count >= 120 ? inset : bestMask
    }

    private static func bestForegroundInstance(
        in observation: VNInstanceMaskObservation,
        width: Int,
        height: Int
    ) -> Int? {
        var bestInstance: Int?
        var bestScore = -Double.infinity
        for instance in observation.allInstances {
            guard let candidate = sampledMask(
                from: observation.instanceMask,
                instance: instance,
                width: width,
                height: height
            ) else {
                continue
            }

            let score = foregroundScore(candidate, width: width, height: height)
            if score > bestScore {
                bestScore = score
                bestInstance = instance
            }
        }
        return bestInstance
    }

    private static func sampledMask(
        from buffer: CVPixelBuffer,
        instance: Int,
        width: Int,
        height: Int
    ) -> [Bool]? {
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
                mask[y * width + x] = reader.instanceIdentifier(x: maskX, y: maskY) == instance
            }
        }
        return mask
    }

    private static func binaryMaskImage(from buffer: CVPixelBuffer, instance: Int) -> CGImage? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        guard let reader = ForegroundMaskReader(buffer: buffer) else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width where reader.instanceIdentifier(x: x, y: y) == instance {
                pixels[y * width + x] = 255
            }
        }
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }
        return context.makeImage()
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

    static func maskHasCredibleGarmentCoverage(_ mask: [Bool], width: Int, height: Int) -> Bool {
        guard width > 0, height > 0, mask.count == width * height else { return false }
        var count = 0
        var minimumX = width
        var minimumY = height
        var maximumX = -1
        var maximumY = -1

        for y in 0..<height {
            for x in 0..<width where mask[y * width + x] {
                count += 1
                minimumX = min(minimumX, x)
                minimumY = min(minimumY, y)
                maximumX = max(maximumX, x)
                maximumY = max(maximumY, y)
            }
        }

        guard maximumX >= minimumX, maximumY >= minimumY else { return false }
        let areaRatio = Double(count) / Double(width * height)
        let widthRatio = Double(maximumX - minimumX + 1) / Double(width)
        let heightRatio = Double(maximumY - minimumY + 1) / Double(height)
        let boundingArea = max(1, (maximumX - minimumX + 1) * (maximumY - minimumY + 1))
        let boundingFillRatio = Double(count) / Double(boundingArea)
        return (0.045...0.76).contains(areaRatio) &&
            widthRatio >= 0.18 &&
            heightRatio >= 0.18 &&
            boundingFillRatio >= 0.22
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
