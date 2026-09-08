import SwiftUI
import UIKit

enum ClosetTheme {
    static let accent = Color(hex: "385B45")
    static let accentSoft = Color(hex: "DCE5DB")
    static let ink = Color(hex: "181A17")
    static let secondaryInk = Color(hex: "666861")
    static let canvas = Color(hex: "F2F0E9")
    static let card = Color(hex: "FBFAF5")
    static let board = Color(hex: "E7E4DA")
    static let signal = Color(hex: "D9F56F")
    static let sage = Color(hex: "CBD8C8")
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix: 16) ?? 0
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

struct CardSurface<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(ClosetTheme.ink.opacity(0.14), lineWidth: 1)
            }
    }
}

struct ItemArtwork: View {
    let photoData: Data?
    let color: ClothingColor
    let category: ClothingCategory
    var height: CGFloat = 150

    var body: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: color.hex).opacity(0.9), Color(hex: color.hex).opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: category.icon)
                        .font(.system(size: min(44, height * 0.3), weight: .medium))
                        .foregroundStyle(contrastingColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .background(Color.secondary.opacity(0.1))
    }

    private var contrastingColor: Color {
        let rgb = color.rgb
        let luminance = 0.2126 * rgb.red + 0.7152 * rgb.green + 0.0722 * rgb.blue
        return luminance > 0.62 ? .black.opacity(0.68) : .white.opacity(0.9)
    }
}

/// A body-aligned outfit board. Isolated garment renditions overlap at the waist
/// and stack from outerwear through footwear like a flat-lay of a worn outfit.
struct OutfitCanvas: View {
    let items: [ClosetItem]
    var height: CGFloat = 430
    var accessibilityIdentifier = "outfit-composition"

    private var onePiece: ClosetItem? { item(in: .onePiece) }
    private var top: ClosetItem? { item(in: .top) }
    private var bottom: ClosetItem? { item(in: .bottom) }
    private var footwear: ClosetItem? { item(in: .footwear) }
    private var outerwear: ClosetItem? { item(in: .outerwear) }
    private var accessory: ClosetItem? { item(in: .accessory) }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .topLeading) {
                ClosetTheme.card

                Path { path in
                    path.move(to: CGPoint(x: 18, y: 46))
                    path.addLine(to: CGPoint(x: width - 18, y: 46))
                }
                .stroke(ClosetTheme.ink.opacity(0.09), lineWidth: 1)

                Text("GET DRESSED")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1.8)
                    .foregroundStyle(ClosetTheme.secondaryInk)
                    .padding(.leading, 18)
                    .padding(.top, 18)

                Text(String(format: "%02d", items.count))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(ClosetTheme.secondaryInk)
                    .position(x: width - 31, y: 23)

                if let onePiece {
                    LayeredGarment(item: onePiece)
                        .frame(width: width * 0.60, height: height * 0.63)
                        .position(x: width * 0.50, y: height * 0.47)
                        .zIndex(2)
                } else {
                    if let bottom {
                        LayeredGarment(item: bottom)
                            .frame(width: width * 0.50, height: height * 0.46)
                            .position(x: width * 0.50, y: height * 0.61)
                            .zIndex(1)
                    }
                    if let top {
                        LayeredGarment(item: top)
                            .frame(width: width * 0.62, height: height * 0.35)
                            .position(x: width * 0.50, y: height * 0.30)
                            .zIndex(2)
                    }
                }

                if let outerwear {
                    LayeredGarment(item: outerwear)
                        .frame(width: width * 0.70, height: height * 0.39)
                        .position(x: width * 0.50, y: height * 0.30)
                        .zIndex(3)
                }

                if let footwear {
                    LayeredGarment(item: footwear)
                        .frame(width: width * 0.43, height: height * 0.18)
                        .position(x: width * 0.50, y: height * 0.87)
                        .zIndex(4)
                }

                if let accessory {
                    LayeredGarment(item: accessory)
                        .frame(width: width * 0.24, height: height * 0.18)
                        .rotationEffect(.degrees(-4))
                        .position(x: width * 0.80, y: height * 0.62)
                        .zIndex(5)
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(ClosetTheme.ink.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Recommended outfit with \(items.count) pieces")
        .accessibilityIdentifier(accessibilityIdentifier)
    }

    private func item(in category: ClothingCategory) -> ClosetItem? {
        items.first { $0.category == category }
    }
}

private struct LayeredGarment: View {
    let item: ClosetItem

    var body: some View {
        GarmentVisual(item: item)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .shadow(color: ClosetTheme.ink.opacity(0.15), radius: 5, x: 0, y: 3)
    }
}

private struct GarmentVisual: View {
    let item: ClosetItem

    var body: some View {
        Group {
            if let photoData = item.outfitPhotoData,
               let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                GarmentPlaceholder(category: item.category)
                    .foregroundStyle(Color(hex: item.dominantColor.hex))
                    .padding(8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(item.category.title), \(item.dominantColor.name)")
    }
}

private struct GarmentPlaceholder: View {
    let category: ClothingCategory

    @ViewBuilder
    var body: some View {
        switch category {
        case .bottom:
            PantsSilhouette()
        case .onePiece:
            DressSilhouette()
        default:
            Image(systemName: category.icon)
                .resizable()
                .symbolRenderingMode(.monochrome)
                .scaledToFit()
        }
    }
}

private struct PantsSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.23, y: rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.width * 0.77, y: rect.height * 0.04))
        path.addLine(to: CGPoint(x: rect.width * 0.72, y: rect.height * 0.43))
        path.addLine(to: CGPoint(x: rect.width * 0.88, y: rect.height * 0.96))
        path.addLine(to: CGPoint(x: rect.width * 0.57, y: rect.height * 0.96))
        path.addLine(to: CGPoint(x: rect.width * 0.50, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.width * 0.43, y: rect.height * 0.96))
        path.addLine(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.96))
        path.addLine(to: CGPoint(x: rect.width * 0.28, y: rect.height * 0.43))
        path.closeSubpath()
        return path
    }
}

private struct DressSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.40, y: rect.height * 0.05))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.60, y: rect.height * 0.05),
            control: CGPoint(x: rect.width * 0.50, y: rect.height * 0.15)
        )
        path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.height * 0.18))
        path.addLine(to: CGPoint(x: rect.width * 0.68, y: rect.height * 0.35))
        path.addLine(to: CGPoint(x: rect.width * 0.88, y: rect.height * 0.95))
        path.addLine(to: CGPoint(x: rect.width * 0.12, y: rect.height * 0.95))
        path.addLine(to: CGPoint(x: rect.width * 0.32, y: rect.height * 0.35))
        path.addLine(to: CGPoint(x: rect.width * 0.22, y: rect.height * 0.18))
        path.closeSubpath()
        return path
    }
}

struct TagPill: View {
    let text: String
    var icon: String?
    var selected = false

    var body: some View {
        HStack(spacing: 5) {
            if let icon { Image(systemName: icon) }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .foregroundStyle(selected ? Color.white : ClosetTheme.ink)
        .background(
            selected ? ClosetTheme.accent : Color.primary.opacity(0.055),
            in: RoundedRectangle(cornerRadius: 3)
        )
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(ClosetTheme.ink)
                .frame(width: 70, height: 70)
                .background(ClosetTheme.signal, in: RoundedRectangle(cornerRadius: 3))
            Text(title)
                .font(.system(.title3, design: .serif, weight: .semibold))
                .foregroundStyle(ClosetTheme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ClosetTheme.secondaryInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

struct OutfitItemRow: View {
    let item: ClosetItem
    var isLocked = false
    var onLock: (() -> Void)?
    var onReroll: (() -> Void)?

    var body: some View {
        HStack(spacing: 13) {
            ItemArtwork(photoData: item.photoData, color: item.dominantColor, category: item.category, height: 68)
                .frame(width: 68)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("\(item.category.title) · \(item.dominantColor.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 6)
            if let onReroll {
                Button(action: onReroll) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reroll \(item.name)")
            }
            if let onLock {
                Button(action: onLock) {
                    Image(systemName: isLocked ? "lock.fill" : "lock.open")
                        .foregroundStyle(isLocked ? ClosetTheme.accent : .secondary)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isLocked ? "Unlock \(item.name)" : "Lock \(item.name)")
            }
        }
    }
}

struct OutfitRecordCard: View {
    let record: OutfitRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(record.occasion.title, systemImage: record.occasion.icon)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text((record.wornAt ?? record.createdAt).formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(record.items) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            ItemArtwork(photoData: item.photoData, color: item.dominantColor, category: item.category, height: 76)
                                .frame(width: 76)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            Text(item.name)
                                .font(.caption2.weight(.medium))
                                .lineLimit(1)
                                .frame(width: 76, alignment: .leading)
                        }
                    }
                }
            }
            Text(record.weatherSummary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(15)
        .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
