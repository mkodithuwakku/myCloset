import SwiftUI

struct ClosetImportReviewBatch: Identifiable {
    enum Mode {
        case newImport
        case reanalysis
    }

    let id = UUID()
    let items: [ClosetItem]
    let uncertainItemIDs: Set<UUID>
    let failures: Int
    let mode: Mode

#if DEBUG
    static var debugPreview: ClosetImportReviewBatch {
        let navy = ClothingColor.palette.first { $0.name == "Navy" } ?? ClothingColor.palette[0]
        let beige = ClothingColor.palette.first { $0.name == "Beige" }
        return ClosetImportReviewBatch(
            items: [
                ClosetItem(
                    name: "Navy Top 1",
                    category: .top,
                    dominantColor: navy,
                    accentColor: beige,
                    seasons: Set(WardrobeSeason.allCases),
                    formalities: [.casual]
                )
            ],
            uncertainItemIDs: [],
            failures: 0,
            mode: .newImport
        )
    }
#endif
}

struct ClosetImportReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var items: [ClosetItem]
    @State private var currentIndex = 0
    @State private var confirmedItemIDs = Set<UUID>()
    @State private var showingDiscardConfirmation = false
    @FocusState private var nameFieldIsFocused: Bool

    private let batch: ClosetImportReviewBatch
    let onCommit: ([ClosetItem]) -> Void
    let onCancel: () -> Void

    private let categoryColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    private let colorColumns = [GridItem(.adaptive(minimum: 92), spacing: 8)]

    init(
        batch: ClosetImportReviewBatch,
        onCommit: @escaping ([ClosetItem]) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.batch = batch
        self.onCommit = onCommit
        self.onCancel = onCancel
        _items = State(initialValue: batch.items)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    reviewHeader
                    photoPreview
                    nameEditor
                    categoryEditor
                    dominantColorEditor
                    accentColorEditor
                    seasonEditor
                    formalityEditor
                }
                .padding(16)
                .padding(.bottom, 92)
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Confirm every piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingDiscardConfirmation = true }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { nameFieldIsFocused = false }
                }
            }
            .safeAreaInset(edge: .bottom) {
                navigationControls
            }
            .confirmationDialog(
                batch.mode == .newImport ? "Discard this import?" : "Discard these suggestions?",
                isPresented: $showingDiscardConfirmation,
                titleVisibility: .visible
            ) {
                Button("Discard", role: .destructive) {
                    onCancel()
                    dismiss()
                }
                Button("Keep reviewing", role: .cancel) {}
            } message: {
                Text(batch.mode == .newImport
                     ? "None of these pieces have been saved yet."
                     : "Your existing closet will stay unchanged.")
            }
        }
        .accessibilityIdentifier("import-review-screen")
    }

    private var currentItem: Binding<ClosetItem> {
        $items[currentIndex]
    }

    private var reviewHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Piece \(currentIndex + 1) of \(items.count)")
                    .font(.headline)
                Spacer()
                Text("\(confirmedItemIDs.count) confirmed")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ClosetTheme.accent)
            }
            ProgressView(value: Double(currentIndex + 1), total: Double(items.count))
                .tint(ClosetTheme.accent)

            if batch.uncertainItemIDs.contains(items[currentIndex].id) {
                Label(
                    "The app could not identify this type reliably. Choose the correct details below.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.orange)
            } else {
                Label(
                    "These are on-device suggestions. Check the name, type, and colours before confirming.",
                    systemImage: "checkmark.circle"
                )
                .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }

    private var photoPreview: some View {
        ItemArtwork(
            photoData: items[currentIndex].photoData,
            color: items[currentIndex].dominantColor,
            category: items[currentIndex].category,
            height: 260
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(ClosetTheme.ink.opacity(0.12))
        }
    }

    private var nameEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.headline)
            TextField("Piece name", text: currentItem.name)
                .textInputAutocapitalization(.words)
                .focused($nameFieldIsFocused)
                .padding(12)
                .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ClosetTheme.ink.opacity(0.15))
                }
                .accessibilityIdentifier("import-review-name")
        }
    }

    private var categoryEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type of piece")
                .font(.headline)
            LazyVGrid(columns: categoryColumns, spacing: 8) {
                ForEach(ClothingCategory.allCases) { category in
                    selectionButton(
                        title: category.title,
                        icon: category.icon,
                        selected: items[currentIndex].category == category
                    ) {
                        items[currentIndex].category = category
                    }
                    .accessibilityIdentifier("import-review-category-\(category.rawValue)")
                }
            }
        }
    }

    private var dominantColorEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Main colour")
                .font(.headline)
            LazyVGrid(columns: colorColumns, alignment: .leading, spacing: 8) {
                ForEach(ClothingColor.palette) { color in
                    colorButton(
                        color: color,
                        selected: items[currentIndex].dominantColor == color
                    ) {
                        items[currentIndex].dominantColor = color
                    }
                    .accessibilityIdentifier("import-review-dominant-\(color.name.lowercased())")
                }
            }
        }
    }

    private var accentColorEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accent colour (optional)")
                .font(.headline)
            LazyVGrid(columns: colorColumns, alignment: .leading, spacing: 8) {
                selectionButton(
                    title: "None",
                    icon: "circle.slash",
                    selected: items[currentIndex].accentColor == nil
                ) {
                    items[currentIndex].accentColor = nil
                }
                .accessibilityIdentifier("import-review-accent-none")

                ForEach(ClothingColor.palette) { color in
                    colorButton(color: color, selected: items[currentIndex].accentColor == color) {
                        items[currentIndex].accentColor = color
                    }
                    .accessibilityIdentifier("import-review-accent-\(color.name.lowercased())")
                }
            }
        }
    }

    private var seasonEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Seasons")
                .font(.headline)
            Text("Choose every season when you would wear this piece.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: categoryColumns, spacing: 8) {
                ForEach(WardrobeSeason.allCases) { season in
                    selectionButton(
                        title: season.title,
                        icon: items[currentIndex].seasons.contains(season) ? "checkmark.circle.fill" : "circle",
                        selected: items[currentIndex].seasons.contains(season)
                    ) {
                        if items[currentIndex].seasons.contains(season) {
                            items[currentIndex].seasons.remove(season)
                        } else {
                            items[currentIndex].seasons.insert(season)
                        }
                    }
                }
            }
        }
    }

    private var formalityEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Formality")
                .font(.headline)
            Text("Choose every level where this piece fits.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: categoryColumns, spacing: 8) {
                ForEach(FormalityLevel.allCases) { level in
                    selectionButton(
                        title: level.title,
                        icon: items[currentIndex].formalities.contains(level) ? "checkmark.circle.fill" : "circle",
                        selected: items[currentIndex].formalities.contains(level)
                    ) {
                        if items[currentIndex].formalities.contains(level) {
                            items[currentIndex].formalities.remove(level)
                        } else {
                            items[currentIndex].formalities.insert(level)
                        }
                    }
                }
            }
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 12) {
            Button("Back") {
                currentIndex -= 1
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .disabled(currentIndex == 0)

            Button(currentIndex == items.count - 1 ? finalButtonTitle : "Confirm & next") {
                confirmCurrentItem()
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .frame(maxWidth: .infinity)
            .disabled(!currentItemIsValid)
            .accessibilityIdentifier(currentIndex == items.count - 1 ? "import-review-save" : "import-review-next")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var finalButtonTitle: String {
        switch batch.mode {
        case .newImport: "Confirm & add \(items.count)"
        case .reanalysis: "Confirm & update \(items.count)"
        }
    }

    private var currentItemIsValid: Bool {
        !items[currentIndex].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !items[currentIndex].seasons.isEmpty &&
            !items[currentIndex].formalities.isEmpty
    }

    private func confirmCurrentItem() {
        items[currentIndex].name = items[currentIndex].name.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmedItemIDs.insert(items[currentIndex].id)

        if currentIndex < items.count - 1 {
            currentIndex += 1
        } else {
            onCommit(items)
            dismiss()
        }
    }

    private func selectionButton(
        title: String,
        icon: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? Color.white : ClosetTheme.ink)
            .padding(.horizontal, 11)
            .frame(minHeight: 44)
            .background(
                selected ? ClosetTheme.accent : ClosetTheme.card,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityValue(selected ? "Selected" : "Not selected")
    }

    private func colorButton(
        color: ClothingColor,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Circle()
                    .fill(Color(hex: color.hex))
                    .frame(width: 18, height: 18)
                    .overlay { Circle().stroke(ClosetTheme.ink.opacity(0.18)) }
                Text(color.name)
                    .lineLimit(1)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(ClosetTheme.ink)
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .background(
                selected ? ClosetTheme.accentSoft : ClosetTheme.card,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? ClosetTheme.accent : ClosetTheme.ink.opacity(0.1))
            }
        }
        .buttonStyle(.plain)
        .accessibilityValue(selected ? "Selected" : "Not selected")
    }
}
