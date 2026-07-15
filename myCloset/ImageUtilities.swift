import CoreGraphics
import UIKit

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
        let width = 40
        let height = 40
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

        var buckets: [ClothingColor: Int] = [:]
        for index in stride(from: 0, to: pixels.count, by: bytesPerPixel) {
            let alpha = pixels[index + 3]
            guard alpha > 50 else { continue }
            let red = Double(pixels[index]) / 255
            let green = Double(pixels[index + 1]) / 255
            let blue = Double(pixels[index + 2]) / 255
            let mapped = ClothingColor.nearest(red: red, green: green, blue: blue)
            buckets[mapped, default: 0] += 1
        }

        let ranked = buckets.sorted { $0.value > $1.value }.map(\.key)
        guard let dominant = ranked.first else { return nil }
        let accent = ranked.dropFirst().first { $0 != dominant }
        return (dominant, accent)
    }
}
