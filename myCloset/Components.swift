import SwiftUI
import UIKit

enum ClosetTheme {
    static let accent = Color(hex: "B75D45")
    static let accentSoft = Color(hex: "F3DED6")
    static let ink = Color(hex: "25221F")
    static let secondaryInk = Color(hex: "706A64")
    static let canvas = Color(hex: "F8F5F0")
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let sage = Color(hex: "DDE5D8")
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
            .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
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
        .background(selected ? ClosetTheme.accent : Color.primary.opacity(0.07), in: Capsule())
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
                .font(.system(size: 38, weight: .medium))
                .foregroundStyle(ClosetTheme.accent)
                .frame(width: 74, height: 74)
                .background(ClosetTheme.accentSoft, in: Circle())
            Text(title)
                .font(.title3.weight(.bold))
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
