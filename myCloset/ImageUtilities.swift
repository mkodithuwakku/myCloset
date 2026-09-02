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

        let foregroundMask = foregroundMask(for: cgImage, width: width, height: height)
        let foregroundSamples = foregroundMask.map {
            colorSamples(in: pixels, width: width, height: height, bytesPerRow: bytesPerRow, including: $0, excluding: nil)
        } ?? []
        let background = estimatedBackground(in: pixels, width: width, height: height, bytesPerRow: bytesPerRow)
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

        var buckets: [ClothingColor: Int] = [:]
        for sample in samples {
            let mapped = ClothingColor.nearest(red: sample.red, green: sample.green, blue: sample.blue)
            buckets[mapped, default: 0] += sample.weight
        }

        let ranked = buckets.sorted { $0.value > $1.value }.map(\.key)
        guard let dominant = ranked.first else { return nil }
        let accent = ranked.dropFirst().first { $0 != dominant }
        return (dominant, accent)
    }

    private struct ColorSample {
        let red: Double
        let green: Double
        let blue: Double
        let weight: Int
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
                let isCentral = abs(Double(x) - centerX) < Double(width) * 0.32 &&
                    abs(Double(y) - centerY) < Double(height) * 0.32
                samples.append(.init(red: color.red, green: color.green, blue: color.blue, weight: isCentral ? 2 : 1))
            }
        }
        return samples
    }

    private static func foregroundMask(for cgImage: CGImage, width: Int, height: Int) -> [Bool]? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observation = request.results?.first,
              !observation.allInstances.isEmpty,
              let buffer = try? observation.generateScaledMaskForImage(
                forInstances: observation.allInstances,
                from: handler
              ) else {
            return nil
        }

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

    private static func squaredDistance(
        _ lhs: (red: Double, green: Double, blue: Double),
        _ rhs: (red: Double, green: Double, blue: Double)
    ) -> Double {
        pow(lhs.red - rhs.red, 2) + pow(lhs.green - rhs.green, 2) + pow(lhs.blue - rhs.blue, 2)
    }
}
