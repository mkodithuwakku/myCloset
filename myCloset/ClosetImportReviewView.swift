import SwiftUI
import UIKit

private enum ImportReviewSection: Hashable {
    case top, photo, name, category, dominantColor, accentColor, seasons, formality
}

private struct ImportReviewScrollRequest {
    let id = UUID()
    let section: ImportReviewSection
}

struct ClosetImportReviewBatch: Identifiable {
    enum Mode {
        case newImport
        case reanalysis
    }

    let id = UUID()
    let items: [ClosetItem]
    let uncertainItemIDs: Set<UUID>
    let assessments: [UUID: ImportReviewAssessment]
    let initiallyOutlinedItemIDs: Set<UUID>
    let failures: Int
    let mode: Mode

    init(
        items: [ClosetItem],
        uncertainItemIDs: Set<UUID>,
        assessments: [UUID: ImportReviewAssessment] = [:],
        initiallyOutlinedItemIDs: Set<UUID> = [],
        failures: Int,
        mode: Mode
    ) {
        self.items = items
        self.uncertainItemIDs = uncertainItemIDs
        self.assessments = assessments
        self.initiallyOutlinedItemIDs = initiallyOutlinedItemIDs
        self.failures = failures
        self.mode = mode
    }

#if DEBUG
    static var debugPreview: ClosetImportReviewBatch {
        makeDebugPreview(itemsAlreadyOutlined: true)
    }

    static var debugOutlinePreview: ClosetImportReviewBatch {
        makeDebugPreview(itemsAlreadyOutlined: false)
    }

    private static func makeDebugPreview(itemsAlreadyOutlined: Bool) -> ClosetImportReviewBatch {
        let navy = ClothingColor.palette.first { $0.name == "Navy" } ?? ClothingColor.palette[0]
        let beige = ClothingColor.palette.first { $0.name == "Beige" }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let debugPhoto = UIGraphicsImageRenderer(
            size: CGSize(width: 240, height: 320),
            format: format
        ).image { context in
            UIColor.systemGray5.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 240, height: 320))
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 45, y: 40, width: 150, height: 240))
        }.jpegData(compressionQuality: 0.9)
        let first = ClosetItem(
            name: "Navy Top 1",
            category: .top,
            photoData: debugPhoto,
            dominantColor: navy,
            accentColor: beige,
            seasons: Set(WardrobeSeason.allCases),
            formalities: [.casual]
        )
        let second = ClosetItem(
            name: "Beige Footwear",
            category: .footwear,
            photoData: debugPhoto,
            dominantColor: beige ?? navy,
            seasons: Set(WardrobeSeason.allCases),
            formalities: [.casual]
        )
        return ClosetImportReviewBatch(
            items: [first, second],
            uncertainItemIDs: [first.id],
            assessments: [
                first.id: .init(type: .needsCheck, color: .needsCheck, cutout: .needsCheck),
                second.id: .init(type: .strong, color: .strong, cutout: .strong)
            ],
            initiallyOutlinedItemIDs: itemsAlreadyOutlined ? [first.id, second.id] : [],
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
    @State private var automaticallyNamedItemIDs: Set<UUID>
    @State private var automaticallySeasonedItemIDs: Set<UUID>
    @State private var assessments: [UUID: ImportReviewAssessment]
    @State private var manuallyOutlinedItemIDs: Set<UUID>
    @State private var showingDiscardConfirmation = false
    @State private var showingSkipConfirmation = false
    @State private var showingOutlineEditor = false
    @State private var isProcessingOutline = false
    @State private var scrollRequest: ImportReviewScrollRequest?
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
        _automaticallyNamedItemIDs = State(
            initialValue: batch.mode == .newImport ? Set(batch.items.map(\.id)) : []
        )
        _automaticallySeasonedItemIDs = State(
            initialValue: batch.mode == .newImport ? Set(batch.items.map(\.id)) : []
        )
        _assessments = State(initialValue: batch.assessments)
        _manuallyOutlinedItemIDs = State(initialValue: batch.initiallyOutlinedItemIDs)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        reviewHeader.id(ImportReviewSection.top)
                        photoPreview.id(ImportReviewSection.photo)
                        if !currentItemRequiresOutline {
                            nameEditor.id(ImportReviewSection.name)
                            categoryEditor.id(ImportReviewSection.category)
                            dominantColorEditor.id(ImportReviewSection.dominantColor)
                            accentColorEditor.id(ImportReviewSection.accentColor)
                            seasonEditor.id(ImportReviewSection.seasons)
                            formalityEditor.id(ImportReviewSection.formality)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 92)
                }
                .onChange(of: currentIndex) { _, _ in
                    proxy.scrollTo(ImportReviewSection.top, anchor: .top)
                }
                .onChange(of: scrollRequest?.id) { _, _ in
                    guard let scrollRequest else { return }
                    withAnimation(.smooth) {
                        proxy.scrollTo(
                            scrollRequest.section,
                            anchor: scrollRequest.section == .top ? .top : .center
                        )
                    }
                }
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
            .confirmationDialog(
                batch.mode == .newImport ? "Skip this photo?" : "Skip this update?",
                isPresented: $showingSkipConfirmation,
                titleVisibility: .visible
            ) {
                Button(batch.mode == .newImport ? "Skip photo" : "Skip update", role: .destructive) {
                    skipCurrentItem()
                }
                Button("Keep reviewing", role: .cancel) {}
            } message: {
                Text(batch.mode == .newImport
                     ? "This photo will not be added. The rest of the import will continue."
                     : "This piece will keep its existing details. The rest of the review will continue.")
            }
            .sheet(isPresented: $showingOutlineEditor) {
                if let photoData = items[currentIndex].photoData {
                    GarmentOutlineEditor(imageData: photoData) { result in
                        applyOutline(result)
                    }
                }
            }
        }
        .accessibilityIdentifier("import-review-screen")
    }

    private var currentItem: Binding<ClosetItem> {
        $items[currentIndex]
    }

    private var currentName: Binding<String> {
        Binding(
            get: { items[currentIndex].name },
            set: { updatedName in
                items[currentIndex].name = updatedName
                automaticallyNamedItemIDs.remove(items[currentIndex].id)
            }
        )
    }

    private var currentItemRequiresOutline: Bool {
        batch.mode == .newImport && !manuallyOutlinedItemIDs.contains(items[currentIndex].id)
    }

    private var currentPreviewImageData: Data? {
        if manuallyOutlinedItemIDs.contains(items[currentIndex].id) {
            return items[currentIndex].isolatedPhotoData
        }
        return items[currentIndex].photoData
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

            if currentItemRequiresOutline {
                Label(
                    "Step 1 of 2 · Outline the item",
                    systemImage: "hand.draw.fill"
                )
                .foregroundStyle(.orange)
                .accessibilityIdentifier("import-review-outline-required")
            } else if let assessment = currentAssessment {
                confidenceSummary(assessment)
            } else if batch.uncertainItemIDs.contains(items[currentIndex].id) {
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
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                ClosetTheme.card
                if let data = currentPreviewImageData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .padding(12)
                }
                if isProcessingOutline {
                    ProgressView("Preparing outline…")
                        .padding(14)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(ClosetTheme.ink.opacity(0.12))
            }

            VStack(alignment: .leading, spacing: 10) {
                Label(
                    currentItemRequiresOutline
                        ? "Trace once around the item, then lift to close"
                        : "Outline complete — background removed",
                    systemImage: currentItemRequiresOutline
                        ? "exclamationmark.triangle.fill"
                        : "checkmark.circle.fill"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(currentItemRequiresOutline ? Color.orange : ClosetTheme.accent)

                if items[currentIndex].photoData != nil {
                    Button(currentItemRequiresOutline ? "Outline item" : "Redo outline", systemImage: "lasso") {
                        showingOutlineEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .frame(maxWidth: .infinity)
                    .disabled(isProcessingOutline)
                    .accessibilityIdentifier("import-review-outline-item")
                }
            }
        }
    }

    private var nameEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.headline)
            TextField("Piece name", text: currentName)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .onSubmit {
                    nameFieldIsFocused = false
                    requestScroll(to: .category)
                }
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
                        selectType(.category(category))
                    }
                    .accessibilityIdentifier("import-review-category-\(category.rawValue)")
                }
            }
            Text("Specific type")
                .font(.subheadline.weight(.semibold))
            LazyVGrid(columns: categoryColumns, spacing: 8) {
                ForEach(GarmentKind.allCases.filter { $0.category == items[currentIndex].category }) { kind in
                    selectionButton(
                        title: kind.title,
                        icon: kind.category.icon,
                        selected: items[currentIndex].garmentType.kind == kind
                    ) {
                        selectType(.kind(kind))
                    }
                    .accessibilityIdentifier("import-review-kind-\(kind.rawValue)")
                }
            }
            Button("Continue to colours", systemImage: "arrow.down") {
                requestScroll(to: .dominantColor)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .accessibilityIdentifier("import-review-type-continue")
        }
    }

    private func selectType(_ type: GarmentType) {
        let id = items[currentIndex].id
        items[currentIndex].applyType(type, updateName: automaticallyNamedItemIDs.contains(id))
        automaticallySeasonedItemIDs.insert(id)
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
                        refreshAutomaticName()
                        requestScroll(to: .accentColor)
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
                    requestScroll(to: .seasons)
                }
                .accessibilityIdentifier("import-review-accent-none")

                ForEach(ClothingColor.palette) { color in
                    colorButton(color: color, selected: items[currentIndex].accentColor == color) {
                        items[currentIndex].accentColor = color
                        requestScroll(to: .seasons)
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
                        automaticallySeasonedItemIDs.remove(items[currentIndex].id)
                        if items[currentIndex].seasons.contains(season) {
                            items[currentIndex].seasons.remove(season)
                        } else {
                            items[currentIndex].seasons.insert(season)
                        }
                    }
                    .accessibilityIdentifier("import-review-season-\(season.rawValue)")
                }
            }

            Button("Continue to formality", systemImage: "arrow.down") {
                requestScroll(to: .formality)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .disabled(items[currentIndex].seasons.isEmpty)
            .accessibilityIdentifier("import-review-seasons-continue")
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

            Button {
                showingSkipConfirmation = true
            } label: {
                Label("Skip", systemImage: "forward.end")
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .tint(.red)
            .accessibilityIdentifier("import-review-skip")

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
        !currentItemRequiresOutline &&
            !isProcessingOutline &&
            !items[currentIndex].name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !items[currentIndex].seasons.isEmpty &&
            !items[currentIndex].formalities.isEmpty
    }

    private func confirmCurrentItem() {
        nameFieldIsFocused = false
        items[currentIndex].name = items[currentIndex].name.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmedItemIDs.insert(items[currentIndex].id)

        if currentIndex < items.count - 1 {
            currentIndex += 1
        } else {
            onCommit(items)
            dismiss()
        }
    }

    private var currentAssessment: ImportReviewAssessment? {
        assessments[items[currentIndex].id]
    }

    @ViewBuilder
    private func confidenceSummary(_ assessment: ImportReviewAssessment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if assessment.needsAttention {
                Label(
                    "Please check \(assessment.componentsNeedingAttention.joined(separator: ", ")).",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.orange)
                .accessibilityIdentifier("import-review-confidence-warning")
            } else {
                Label("Suggestions look reliable. You still control every detail.", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)

                Button("Looks good — confirm piece", systemImage: "checkmark") {
                    confirmCurrentItem()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(!currentItemIsValid)
                .accessibilityIdentifier("import-review-fast-confirm")
            }

            HStack(spacing: 8) {
                confidencePill("Type", assessment.type)
                confidencePill("Colour", assessment.color)
                confidencePill("Cutout", assessment.cutout)
            }
        }
    }

    private func confidencePill(_ title: String, _ confidence: ImportSuggestionConfidence) -> some View {
        Label("\(title): \(confidence.title)", systemImage: confidence.icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(confidence == .needsCheck ? Color.orange : ClosetTheme.secondaryInk)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(ClosetTheme.card, in: Capsule())
    }

    private func skipCurrentItem() {
        guard items.count > 1 else {
            onCommit([])
            dismiss()
            return
        }

        let removedID = items[currentIndex].id
        items.remove(at: currentIndex)
        confirmedItemIDs.remove(removedID)
        automaticallyNamedItemIDs.remove(removedID)
        automaticallySeasonedItemIDs.remove(removedID)
        manuallyOutlinedItemIDs.remove(removedID)
        assessments[removedID] = nil

        if currentIndex >= items.count {
            currentIndex = items.count - 1
        } else {
            requestScroll(to: .top)
        }
    }

    private func refreshAutomaticName() {
        let id = items[currentIndex].id
        guard automaticallyNamedItemIDs.contains(id) else { return }
        items[currentIndex].name = ClothingTypeDetector.metadataName(
            category: items[currentIndex].category,
            dominantColor: items[currentIndex].dominantColor,
            kind: items[currentIndex].garmentType.kind
        )
    }

    private func refreshAutomaticSeasons() {
        let id = items[currentIndex].id
        guard automaticallySeasonedItemIDs.contains(id) else { return }
        items[currentIndex].seasons = items[currentIndex].garmentType.kind?.suggestedSeasons
            ?? items[currentIndex].category.suggestedSeasons
    }

    private func requestScroll(to section: ImportReviewSection) {
        scrollRequest = ImportReviewScrollRequest(section: section)
    }

    private func applyOutline(_ result: GarmentOutlineResult) {
        let itemID = items[currentIndex].id
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return }

        items[index].photoData = result.sourceImageData
        items[index].isolatedPhotoData = result.isolatedImageData
        manuallyOutlinedItemIDs.insert(itemID)
        if index == currentIndex {
            refreshAutomaticSeasons()
            refreshAutomaticName()
        }
        isProcessingOutline = true

        Task {
            let processed = await Task.detached(priority: .userInitiated) {
                ImageUtilities.suggestedColors(from: result.isolatedImageData)
            }.value
            guard let index = items.firstIndex(where: { $0.id == itemID }) else {
                isProcessingOutline = false
                return
            }
            if let colors = processed {
                items[index].dominantColor = colors.dominant
                items[index].accentColor = colors.accent
            }
            if assessments[itemID] != nil {
                let previousType = assessments[itemID]?.type ?? .needsCheck
                assessments[itemID] = ImportReviewAssessment(
                    type: previousType,
                    color: processed == nil ? .needsCheck : .strong,
                    cutout: .strong
                )
            }
            if index == currentIndex {
                refreshAutomaticName()
            }
            isProcessingOutline = false
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
