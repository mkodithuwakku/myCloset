import CoreImage
import UIKit
import Vision

struct GarmentEdgeRefinement: Sendable {
    /// Same canvas as the prepared source, so comparing outlines never moves the item.
    let previewImageData: Data
    let isolatedImageData: Data
}

/// A lasso-guided, on-device suggestion. The hand-drawn cutout remains authoritative
/// until the user reviews this result. All analysis uses top-left image coordinates.
enum GarmentEdgeRefiner {
    static func refine(
        from data: Data, normalizedOutlines: [[CGPoint]], useVision: Bool = true
    ) -> GarmentEdgeRefinement? {
        autoreleasepool {
            guard !Task.isCancelled,
                  let source = normalizedImage(data), let cgImage = source.cgImage,
                  let guidance = OutlineGuidance(outlines: normalizedOutlines, size: source.size) else { return nil }

            guard !Task.isCancelled else { return nil }
            if useVision, let mask = visionMask(source: cgImage, guidance: guidance), !Task.isCancelled {
                return composite(source: source, mask: mask)
            }
            guard !Task.isCancelled,
                  let pixels = rgbaPixels(cgImage, width: guidance.width, height: guidance.height),
                  let alpha = colorMask(pixels: pixels, guidance: guidance),
                  let mask = grayImage(alpha, width: guidance.width, height: guidance.height) else { return nil }
            return composite(source: source, mask: mask)
        }
    }

    private static func normalizedImage(_ data: Data) -> UIImage? {
        guard let source = UIImage(data: data), source.size.width > 0, source.size.height > 0 else { return nil }
        let scale = min(1, 1_200 / max(source.size.width, source.size.height))
        let size = CGSize(width: max(1, (source.size.width * scale).rounded()),
                          height: max(1, (source.size.height * scale).rounded()))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            source.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func visionMask(source: CGImage, guidance: OutlineGuidance) -> CGImage? {
        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: source, options: [:])
        guard (try? handler.perform([request])) != nil, !Task.isCancelled,
              let observation = request.results?.first else { return nil }
        let buffer = observation.instanceMask
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        let instances: IndexSet
        if let reader = ForegroundMaskReader(buffer: buffer) {
            let width = CVPixelBufferGetWidth(buffer)
            let height = CVPixelBufferGetHeight(buffer)
            let labels = (0..<(guidance.width * guidance.height)).map { index in
                reader.instanceIdentifier(
                    x: min(width - 1, (index % guidance.width) * width / guidance.width),
                    y: min(height - 1, (index / guidance.width) * height / guidance.height)
                )
            }
            instances = selectedInstances(labels: labels, guidance: guidance)
        } else {
            instances = []
        }
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        guard !instances.isEmpty,
              let scaled = try? observation.generateScaledMaskForImage(forInstances: instances, from: handler) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: scaled)
        guard let mask = CIContext().createCGImage(ciImage, from: ciImage.extent),
              let pixels = rgbaPixels(mask, width: guidance.width, height: guidance.height) else { return nil }
        let alpha = stride(from: 0, to: pixels.count, by: 4).map { pixels[$0] }
        // Reject an unrelated object, missing shoe, lost hem, or large background
        // expansion. Never clip a failed model prediction and call it successful.
        guard guidance.accepts(alpha),
              let fullPixels = rgbaPixels(mask, width: source.width, height: source.height) else { return nil }
        let bounded = (0..<(source.width * source.height)).map { index -> UInt8 in
            let x = (index % source.width) * guidance.width / source.width
            let y = (index / source.width) * guidance.height / source.height
            let sample = y * guidance.width + x
            return guidance.inside[sample] || guidance.toInside[sample] < guidance.radius
                ? fullPixels[index * 4] : 0
        }
        return grayImage(bounded, width: source.width, height: source.height)
    }

    static func selectedInstances(labels: [Int], guidance: OutlineGuidance) -> IndexSet {
        guard labels.count == guidance.inside.count else { return [] }
        var selected = IndexSet()
        for region in guidance.regions {
            var overlaps: [Int: Int] = [:]
            for index in labels.indices where region[index] && labels[index] > 0 {
                overlaps[labels[index], default: 0] += 1
            }
            let area = region.filter { $0 }.count
            // Select by overlap with EACH outline, rather than the photo centre.
            for (instance, overlap) in overlaps where Double(overlap) >= Double(area) * 0.15 {
                selected.insert(instance)
            }
        }
        return selected
    }

    /// Conservative colour evidence in a narrow band around the lasso. Confident
    /// inner pixels and distant background are fixed; ambiguous pixels keep the
    /// user's choice. This also works when Vision is unavailable in Simulator.
    static func colorMask(pixels: [UInt8], guidance: OutlineGuidance) -> [UInt8]? {
        guard pixels.count == guidance.inside.count * 4 else { return nil }
        let foreground = palette(pixels: pixels, indices: guidance.inside.indices.filter {
            guidance.inside[$0] && guidance.toOutside[$0] >= guidance.radius
        })
        let background = palette(pixels: pixels, indices: guidance.inside.indices.filter {
            !guidance.inside[$0] && guidance.toInside[$0] >= guidance.radius &&
                guidance.toInside[$0] <= guidance.radius * 2
        })
        guard !foreground.isEmpty, !background.isEmpty else { return nil }
        var result = guidance.inside.map { UInt8($0 ? 255 : 0) }
        var changes = 0
        for index in result.indices {
            if index.isMultiple(of: guidance.width), Task.isCancelled { return nil }
            guard guidance.inside[index] ? guidance.toOutside[index] < guidance.radius :
                    guidance.toInside[index] < guidance.radius else { continue }
            let color = rgb(pixels, index)
            let fg = foreground.reduce(Double.infinity) { min($0, distance(color, $1)) }
            let bg = background.reduce(Double.infinity) { min($0, distance(color, $1)) }
            if fg < 0.035 && fg + 0.012 < bg {
                result[index] = 255
            } else if bg < 0.035 && bg + 0.012 < fg {
                result[index] = 0
            }
            if result[index] != (guidance.inside[index] ? 255 : 0) { changes += 1 }
        }
        // Discard floating background specks without dropping either shoe:
        // keep every connected component that reaches the trusted interior.
        var connected = [Bool](repeating: false, count: result.count)
        var queue = result.indices.filter { guidance.inside[$0] && guidance.toOutside[$0] >= guidance.radius }
        for index in queue { connected[index] = true }
        var cursor = 0
        while cursor < queue.count {
            let index = queue[cursor]
            cursor += 1
            let x = index % guidance.width, y = index / guidance.width
            let neighbours = [x > 0 ? index - 1 : -1, x + 1 < guidance.width ? index + 1 : -1,
                              y > 0 ? index - guidance.width : -1,
                              y + 1 < guidance.height ? index + guidance.width : -1]
            for next in neighbours where next >= 0 && !connected[next] && result[next] > 127 {
                connected[next] = true
                queue.append(next)
            }
        }
        for index in result.indices where !connected[index] { result[index] = 0 }
        guard changes >= max(4, guidance.inside.filter { $0 }.count / 500),
              guidance.accepts(result) else { return nil }
        return result
    }

    private static func palette(pixels: [UInt8], indices: [Int]) -> [SIMD3<Double>] {
        var buckets: [Int: (sum: SIMD3<Double>, count: Int)] = [:]
        for index in indices {
            let offset = index * 4
            guard pixels[offset + 3] > 240 else { continue }
            let key = (Int(pixels[offset]) / 24) * 121 + (Int(pixels[offset + 1]) / 24) * 11 + Int(pixels[offset + 2]) / 24
            let old = buckets[key, default: (.zero, 0)]
            buckets[key] = (old.sum + rgb(pixels, index), old.count + 1)
        }
        // A handful of floor pixels at a concave lasso corner must not become a
        // foreground colour prototype and prevent all background removal.
        let minimumCount = max(3, indices.count / 300)
        return buckets.values.filter { $0.count >= minimumCount }
            .sorted { $0.count > $1.count }.prefix(32).map { $0.sum / Double($0.count) }
    }

    private static func rgb(_ pixels: [UInt8], _ index: Int) -> SIMD3<Double> {
        SIMD3(Double(pixels[index * 4]), Double(pixels[index * 4 + 1]), Double(pixels[index * 4 + 2])) / 255
    }

    private static func distance(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        let difference = a - b
        return difference.x * difference.x + difference.y * difference.y + difference.z * difference.z
    }

    private static func composite(source: UIImage, mask: CGImage) -> GarmentEdgeRefinement? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        // Turn a luminance mask into alpha using Core Image, then draw with UIKit
        // for the same orientation convention as the manual lasso compositor.
        let maskImage = CIImage(cgImage: mask).applyingFilter("CIMaskToAlpha")
        guard let alphaImage = CIContext().createCGImage(maskImage, from: maskImage.extent) else { return nil }
        let image = UIGraphicsImageRenderer(size: source.size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: source.size)
            source.draw(in: rect)
            UIImage(cgImage: alphaImage).draw(in: rect, blendMode: .destinationIn, alpha: 1)
        }
        guard !Task.isCancelled, let cgImage = image.cgImage,
              let cropped = ImageUtilities.croppedToVisibleAlpha(cgImage),
              let preview = image.pngData(), let cutout = UIImage(cgImage: cropped).pngData() else { return nil }
        return GarmentEdgeRefinement(previewImageData: preview, isolatedImageData: cutout)
    }

    static func rgbaPixels(_ image: CGImage, width: Int, height: Int) -> [UInt8]? {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(data: &pixels, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    private static func grayImage(_ bytes: [UInt8], width: Int, height: Int) -> CGImage? {
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 8,
                       bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
    }
}

struct OutlineGuidance {
    let width: Int
    let height: Int
    let radius: Int
    let regions: [[Bool]]
    let inside: [Bool]
    let toInside: [Int]
    let toOutside: [Int]

    init?(outlines: [[CGPoint]], size: CGSize) {
        guard outlines.allSatisfy({ $0.allSatisfy { $0.x.isFinite && $0.y.isFinite } }),
              outlines.contains(where: GarmentLassoGeometry.isValid),
              size.width >= 1, size.height >= 1 else { return nil }
        // Include even small extra areas. Ignoring one here could silently
        // remove a strap or smaller shoe while the main outline still passes.
        let valid = outlines.filter { GarmentLassoGeometry.polygonArea($0) > 0 }
        let scale = min(1, 600 / max(size.width, size.height))
        width = max(1, Int((size.width * scale).rounded()))
        height = max(1, Int((size.height * scale).rounded()))
        radius = max(3, Int(Double(min(width, height)) * 0.05))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let canvas = CGSize(width: width, height: height)
        var masks: [[Bool]] = []
        for outline in valid {
            let mask = UIGraphicsImageRenderer(size: canvas, format: format).image { _ in
                let path = UIBezierPath()
                for (index, point) in outline.enumerated() {
                    let p = CGPoint(x: min(1, max(0, point.x)) * canvas.width,
                                    y: min(1, max(0, point.y)) * canvas.height)
                    if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.close()
                UIColor.white.setFill()
                path.fill()
            }
            guard let cgImage = mask.cgImage,
                  let pixels = GarmentEdgeRefiner.rgbaPixels(cgImage, width: width, height: height) else { return nil }
            masks.append(stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] > 127 })
        }
        regions = masks
        inside = (0..<(width * height)).map { index in masks.contains { $0[index] } }
        guard inside.contains(true), inside.contains(false) else { return nil }
        toInside = Self.distances(from: inside, width: width, height: height)
        toOutside = Self.distances(from: inside.map { !$0 }, width: width, height: height)
    }

    func accepts(_ alpha: [UInt8]) -> Bool {
        guard alpha.count == inside.count else { return false }
        var visible = 0
        var escaped = 0
        for index in alpha.indices where alpha[index] > 127 {
            visible += 1
            if !inside[index] && toInside[index] >= radius { escaped += 1 }
        }
        guard visible > 0, Double(escaped) / Double(visible) < 0.005 else { return false }
        // Every separate outline must survive, including the smaller shoe. A
        // global coverage score alone can hide the loss of an entire region.
        for region in regions {
            var area = 0, retained = 0, core = 0, retainedCore = 0
            for index in region.indices where region[index] {
                area += 1
                if alpha[index] > 127 { retained += 1 }
                if toOutside[index] >= radius {
                    core += 1
                    if alpha[index] > 127 { retainedCore += 1 }
                }
            }
            guard area > 0, Double(retained) / Double(area) >= 0.65,
                  core > 0, Double(retainedCore) / Double(core) >= 0.98 else { return false }
        }
        return Double(visible) <= Double(inside.filter { $0 }.count) * 1.4
    }

    /// Four-neighbour distance transform with bounded linear work and storage.
    private static func distances(from seeds: [Bool], width: Int, height: Int) -> [Int] {
        var distances = seeds.map { $0 ? 0 : width + height }
        var queue = seeds.indices.filter { seeds[$0] }
        var cursor = 0
        while cursor < queue.count {
            let index = queue[cursor]
            cursor += 1
            let x = index % width, y = index / width
            let neighbours = [x > 0 ? index - 1 : -1, x + 1 < width ? index + 1 : -1,
                              y > 0 ? index - width : -1, y + 1 < height ? index + width : -1]
            for next in neighbours where next >= 0 && distances[next] > distances[index] + 1 {
                distances[next] = distances[index] + 1
                queue.append(next)
            }
        }
        return distances
    }
}
