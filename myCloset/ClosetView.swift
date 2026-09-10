import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

private struct ClosetEditorPresentation: Identifiable {
    let id = UUID()
    let item: ClosetItem?
}

struct ClosetView: View {
    @EnvironmentObject private var store: ClosetStore
    @State private var searchText = ""
    @State private var selectedCategory: ClothingCategory?
    @State private var selectedKind: GarmentKind?
    @State private var editorPresentation: ClosetEditorPresentation?
    @State private var selectedImportPhotos: [PhotosPickerItem] = []
    @State private var showingFileImporter = false
    @State private var isImporting = false
    @State private var importProgress = 0
    @State private var importTotal = 0
    @State private var importMessage = ""
    @State private var showingImportResult = false
    @State private var showingReanalysisConfirmation = false
    @State private var pendingImportReview: ClosetImportReviewBatch?
    @State private var pendingImportSummary: ClosetImportSummary?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    HStack {
                        Text("\(store.visibleItems.count) pieces")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("closet-piece-count")
                        Spacer()
                        if isImporting {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Analyzing \(min(importProgress + 1, importTotal)) of \(importTotal)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(ClosetTheme.secondaryInk)
                                    .accessibilityIdentifier("closet-import-progress-label")
                                ProgressView(value: Double(importProgress), total: Double(max(importTotal, 1)))
                                    .frame(width: 112)
                                    .accessibilityLabel("Analyzing closet photos")
                                    .accessibilityValue("\(importProgress) of \(importTotal) complete")
                            }
                        } else {
                            PhotosPicker(
                                selection: $selectedImportPhotos,
                                maxSelectionCount: 50,
                                matching: .images
                            ) {
                                Label("Import", systemImage: "photo.stack")
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .accessibilityIdentifier("bulk-photo-import")

                            Menu {
                                Button {
                                    editorPresentation = ClosetEditorPresentation(item: nil)
                                } label: {
                                    Label("Add one manually", systemImage: "plus")
                                }
                                Button {
                                    showingFileImporter = true
                                } label: {
                                    Label("Import image files", systemImage: "folder")
                                }
                                Button {
                                    showingReanalysisConfirmation = true
                                } label: {
                                    Label("Re-analyze photo details", systemImage: "viewfinder")
                                }
                                .disabled(store.items.allSatisfy { $0.photoData == nil })
                            } label: {
                                Image(systemName: "plus")
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.circle)
                            .accessibilityLabel("Add closet pieces")
                        }
                    }
                    .padding(.horizontal, 16)
                    categoryFilters
                    if filteredItems.isEmpty {
                        if store.items.isEmpty && searchText.isEmpty {
                            EmptyState(
                                icon: "hanger",
                                title: "Start your closet",
                                message: "Tap Import above to choose your own clothing photos. We’ll suggest the details and you can edit everything."
                            )
                            .padding(.horizontal, 20)
                        } else {
                            EmptyState(
                                icon: "magnifyingglass",
                                title: "No matching pieces",
                                message: "Try a different search or category."
                            )
                            .padding(.horizontal, 20)
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredItems) { item in
                                ClosetItemCard(item: item) {
                                    editorPresentation = ClosetEditorPresentation(item: item)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 28)
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .navigationTitle("Your closet")
            .searchable(text: $searchText, prompt: "Search pieces")
            .sheet(item: $editorPresentation) { presentation in
                ClosetItemEditor(existingItem: presentation.item)
            }
            .sheet(item: $pendingImportReview) { batch in
                ClosetImportReviewView(batch: batch) { confirmedItems in
                    completeImportReview(confirmedItems, batch: batch)
                } onCancel: {
                    pendingImportReview = nil
                }
                .interactiveDismissDisabled()
            }
            .sheet(item: $pendingImportSummary) { summary in
                ClosetImportSummaryView(summary: summary) {
                    pendingImportSummary = nil
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                guard case .success(let urls) = result else { return }
                Task { await importFiles(urls) }
            }
            .onChange(of: selectedImportPhotos) { _, photos in
                guard !photos.isEmpty else { return }
                Task { await importPhotos(photos) }
            }
            .alert("Closet import", isPresented: $showingImportResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importMessage)
            }
            .confirmationDialog(
                "Re-analyze photo details?",
                isPresented: $showingReanalysisConfirmation,
                titleVisibility: .visible
            ) {
                Button("Re-analyze photos") {
                    Task { await reanalyzePhotos() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This reruns on-device type and color detection for photographed pieces. Your names, seasons, formality, favorites, and availability stay unchanged.")
            }
            .task {
#if DEBUG
                if pendingImportReview == nil {
                    if ProcessInfo.processInfo.arguments.contains("-openPrototypeImportOutline") {
                        pendingImportReview = .debugOutlinePreview
                    } else if ProcessInfo.processInfo.arguments.contains("-openPrototypeImportReview") {
                        pendingImportReview = .debugPreview
                    }
                }
#endif
            }
        }
    }

    private var filteredItems: [ClosetItem] {
        store.visibleItems.filter { item in
            let searchableMetadata = [
                item.name,
                item.category.title,
                item.typeTitle,
                item.dominantColor.name,
                item.accentColor?.name,
                item.seasons.map(\.title).joined(separator: " "),
                item.formalities.map(\.title).joined(separator: " ")
            ]
                .compactMap { $0 }
                .joined(separator: " ")
            let matchesSearch = searchText.isEmpty || searchableMetadata.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesKind = selectedKind == nil || item.garmentType.kind == selectedKind
            return matchesSearch && matchesCategory && matchesKind
        }
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation { selectedCategory = nil; selectedKind = nil }
                } label: {
                    TagPill(text: "All", selected: selectedCategory == nil && selectedKind == nil)
                }
                .buttonStyle(.plain)
                Menu {
                    ForEach(ClothingCategory.allCases) { category in
                        Section(category.title) {
                            ForEach(GarmentKind.allCases.filter { $0.category == category }) { kind in
                                Button(kind.title) {
                                    selectedCategory = category
                                    selectedKind = kind
                                }
                                .accessibilityIdentifier("closet-filter-kind-\(kind.rawValue)")
                            }
                        }
                    }
                } label: {
                    TagPill(text: selectedKind?.title ?? "Specific type", icon: "line.3.horizontal.decrease", selected: selectedKind != nil)
                }
                .accessibilityIdentifier("closet-type-filter")
                ForEach(ClothingCategory.allCases) { category in
                    Button {
                        withAnimation { selectedCategory = category; selectedKind = nil }
                    } label: {
                        TagPill(text: category.title, icon: category.icon, selected: selectedCategory == category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    @MainActor
    private func importPhotos(_ photos: [PhotosPickerItem]) async {
        beginImport(total: photos.count)
        var imported: [ImportedClosetPiece] = []
        var failures = 0

        for (offset, photo) in photos.enumerated() {
            defer { importProgress = offset + 1 }
            guard let data = try? await photo.loadTransferable(type: Data.self),
                  let piece = await ClosetImageImporter.makePiece(
                    from: data,
                    index: store.items.count + offset + 1
                  ) else {
                failures += 1
                continue
            }
            imported.append(piece)
        }

        finishImport(imported, failures: failures)
        selectedImportPhotos = []
    }

    @MainActor
    private func importFiles(_ urls: [URL]) async {
        beginImport(total: urls.count)
        var imported: [ImportedClosetPiece] = []
        var failures = 0

        for (offset, url) in urls.enumerated() {
            defer { importProgress = offset + 1 }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess { url.stopAccessingSecurityScopedResource() }
            }
            guard let data = try? Data(contentsOf: url),
                  let piece = await ClosetImageImporter.makePiece(
                    from: data,
                    filename: url.lastPathComponent,
                    index: store.items.count + offset + 1
                  ) else {
                failures += 1
                continue
            }
            imported.append(piece)
        }

        finishImport(imported, failures: failures)
    }

    @MainActor
    private func beginImport(total: Int) {
        isImporting = true
        importProgress = 0
        importTotal = total
    }

    @MainActor
    private func finishImport(_ pieces: [ImportedClosetPiece], failures: Int) {
        let uniqueItems = uniqueNames(for: pieces.map(\.item))
        isImporting = false

        guard !uniqueItems.isEmpty else {
            importMessage = failures > 0
                ? "None of the selected images could be read. Nothing was added to your closet."
                : "No clothing images were selected. Nothing was added to your closet."
            showingImportResult = true
            return
        }

        pendingImportReview = ClosetImportReviewBatch(
            items: uniqueItems,
            uncertainItemIDs: Set(zip(uniqueItems, pieces).compactMap { item, piece in
                piece.detection.needsReview ? item.id : nil
            }),
            assessments: Dictionary(uniqueKeysWithValues: zip(uniqueItems, pieces).map { item, piece in
                (item.id, piece.assessment)
            }),
            failures: failures,
            mode: .newImport
        )
    }

    @MainActor
    private func completeImportReview(_ confirmedItems: [ClosetItem], batch: ClosetImportReviewBatch) {
        store.upsert(confirmedItems)
        pendingImportReview = nil

        if batch.mode == .newImport {
            pendingImportSummary = ClosetImportSummary(
                importedItems: confirmedItems,
                availableClosetItems: store.visibleItems.filter(\.isAvailable),
                skipped: max(0, batch.items.count - confirmedItems.count),
                failures: batch.failures
            )
            return
        }

        let action = batch.mode == .newImport ? "Added" : "Updated"
        var details = ["\(action) \(confirmedItems.count) confirmed piece\(confirmedItems.count == 1 ? "" : "s") in your closet."]
        if batch.failures > 0 {
            details.append("\(batch.failures) image\(batch.failures == 1 ? "" : "s") could not be read.")
        }
        importMessage = details.joined(separator: " ")
        showingImportResult = true
    }

    private func uniqueNames(for importedItems: [ClosetItem]) -> [ClosetItem] {
        var used = Set(store.items.map { $0.name.lowercased() })
        return importedItems.map { original in
            var item = original
            var candidate = item.name
            var suffix = 2
            while used.contains(candidate.lowercased()) {
                candidate = "\(item.name) \(suffix)"
                suffix += 1
            }
            item.name = candidate
            used.insert(candidate.lowercased())
            return item
        }
    }

    @MainActor
    private func reanalyzePhotos() async {
        let photographedItems = store.items.filter { $0.photoData != nil }
        beginImport(total: photographedItems.count)
        var updatedItems: [ClosetItem] = []
        var uncertainItemIDs = Set<UUID>()
        var assessments: [UUID: ImportReviewAssessment] = [:]
        var failures = 0

        for (offset, existing) in photographedItems.enumerated() {
            defer { importProgress = offset + 1 }
            guard let data = existing.photoData,
                  let suggestion = await ClosetImageImporter.makePiece(
                    from: data,
                    index: offset + 1,
                    confirmedOutlineData: existing.isolatedPhotoData
                  ) else {
                failures += 1
                continue
            }

            var updated = existing
            if existing.kind == nil, suggestion.detection.source != .fallback {
                updated.category = suggestion.item.category
                updated.kind = suggestion.item.kind
            }
            if suggestion.detection.needsReview {
                uncertainItemIDs.insert(existing.id)
            }
            updated.dominantColor = suggestion.item.dominantColor
            updated.accentColor = suggestion.item.accentColor
            updatedItems.append(updated)
            assessments[existing.id] = suggestion.assessment
        }

        isImporting = false
        guard !updatedItems.isEmpty else {
            importMessage = "No photographed pieces could be re-analyzed. Your closet was not changed."
            showingImportResult = true
            return
        }

        pendingImportReview = ClosetImportReviewBatch(
            items: updatedItems,
            uncertainItemIDs: uncertainItemIDs,
            assessments: assessments,
            failures: failures,
            mode: .reanalysis
        )
    }
}

private struct ClosetItemCard: View {
    @EnvironmentObject private var store: ClosetStore
    @State private var showingDeleteConfirmation = false
    let item: ClosetItem
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    ItemArtwork(photoData: item.photoData, color: item.dominantColor, category: item.category, height: 164)
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.black.opacity(0.3), in: Circle())
                            .padding(8)
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ClosetTheme.ink)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: item.dominantColor.hex))
                            .frame(width: 10, height: 10)
                        Text("\(item.typeTitle) · \(item.dominantColor.name)")
                            .font(.caption)
                            .foregroundStyle(ClosetTheme.secondaryInk)
                        if item.availability != .available {
                            Image(systemName: item.availability.icon)
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding(12)
            }
            .background(ClosetTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(ClosetTheme.ink.opacity(0.14))
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                store.toggleFavorite(item.id)
            } label: {
                Label(item.isFavorite ? "Remove favorite" : "Favorite", systemImage: item.isFavorite ? "heart.slash" : "heart")
            }
            Menu("Availability") {
                ForEach(ItemAvailability.allCases) { availability in
                    Button(availability.title) { store.setAvailability(availability, for: item.id) }
                }
            }
            Button("Edit", systemImage: "pencil", action: onEdit)
            Button("Delete", systemImage: "trash", role: .destructive) {
                showingDeleteConfirmation = true
            }
            .accessibilityIdentifier("closet-delete-item")
        }
        .alert("Delete “\(item.name)” from your closet?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) { store.delete(item.id) }
                .accessibilityIdentifier("closet-confirm-delete")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Past saved and worn outfit snapshots will remain intact.")
        }
    }
}

private struct ClosetItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ClosetStore
    @State private var item: ClosetItem
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var pendingPhotoSuggestion: ImportedClosetPiece?
    @State private var showingPhotoOutline = false
    @State private var showingDeleteConfirmation = false
    @State private var photoSuggestionMessage: String?
    @State private var automaticallyNamed: Bool
    private let isNewItem: Bool

    init(existingItem: ClosetItem?) {
        isNewItem = existingItem == nil
        _automaticallyNamed = State(initialValue: existingItem == nil || existingItem?.name == existingItem?.suggestedName)
        let fallback = ClothingColor.palette.first { $0.name == "Navy" } ?? ClothingColor.palette[0]
        _item = State(initialValue: existingItem ?? ClosetItem(
            name: "",
            category: .top,
            dominantColor: fallback,
            seasons: Set(WardrobeSeason.allCases),
            formalities: [.casual]
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                detailsSection
                colorSection
                seasonSection
                formalitySection
                availabilitySection

                if let duplicate = store.duplicateName(for: item.name, excluding: item.id), !item.name.isEmpty {
                    Section {
                        Label("A piece named “\(duplicate.name)” already exists. You can still save this as a separate item.", systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                if store.items.contains(where: { $0.id == item.id }) {
                    Section {
                        Button("Delete piece", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(store.items.contains(where: { $0.id == item.id }) ? "Edit piece" : "Add a piece")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.upsert(item)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .alert("Delete this piece?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    store.delete(item.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Past saved and worn outfit snapshots will remain intact.")
            }
            .sheet(isPresented: $showingPhotoOutline) {
                if let photoData = pendingPhotoSuggestion?.item.photoData {
                    GarmentOutlineEditor(imageData: photoData) { result in
                        applyOutlinedPhoto(result)
                    }
                }
            }
        }
    }

    private var photoSection: some View {
        Section {
            VStack(spacing: 12) {
                ZStack {
                    ItemArtwork(photoData: item.photoData, color: item.dominantColor, category: item.category, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    if item.photoData == nil {
                        Label("Choose a photo, then outline the item", systemImage: "lasso")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.45), in: Capsule())
                    }
                    if isProcessingPhoto {
                        ProgressView()
                            .padding(18)
                            .background(.regularMaterial, in: Circle())
                    }
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label(item.photoData == nil ? "Choose garment photo" : "Replace photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .onChange(of: selectedPhoto) { _, newValue in
                    guard let newValue else { return }
                    Task { await process(newValue) }
                }

                if item.photoData != nil {
                    Button {
                        Task { await reanalyzeCurrentPhoto() }
                    } label: {
                        Label("Re-analyze this photo", systemImage: "viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                    .disabled(isProcessingPhoto)
                    .accessibilityIdentifier("reanalyze-current-photo")
                }

                Text("Every new or replacement photo must be outlined before it can be saved. Trace the real item edge once; the background will be removed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if let photoSuggestionMessage {
                    Label(photoSuggestionMessage, systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var detailsSection: some View {
        Section("Piece details") {
            TextField("Name", text: Binding(get: { item.name }, set: {
                item.name = $0
                automaticallyNamed = false
            }))
                .textInputAutocapitalization(.words)
            Picker("Type", selection: Binding(get: { item.garmentType }, set: {
                item.applyType($0, updateName: automaticallyNamed)
            })) {
                ForEach(ClothingCategory.allCases) { category in
                    Section(category.title) {
                        Text("General \(category.title.lowercased())").tag(GarmentType.category(category))
                        ForEach(GarmentKind.allCases.filter { $0.category == category }) { kind in
                            Text(kind.title).tag(GarmentType.kind(kind))
                        }
                    }
                }
            }
            .accessibilityIdentifier("piece-editor-category")
        }
    }

    private var colorSection: some View {
        Section {
            Picker("Dominant color", selection: $item.dominantColor) {
                ForEach(ClothingColor.palette) { color in
                    Text(color.name).tag(color)
                }
            }
            .accessibilityIdentifier("piece-editor-dominant-color")
            .onChange(of: item.dominantColor) { _, _ in
                if automaticallyNamed { item.name = item.suggestedName }
            }
            Picker("Accent color", selection: $item.accentColor) {
                Text("None").tag(nil as ClothingColor?)
                ForEach(ClothingColor.palette) { color in
                    Text(color.name).tag(color as ClothingColor?)
                }
            }
        } header: {
            Text("Confirmed colors")
        } footer: {
            HStack(spacing: 8) {
                ColorSwatch(color: item.dominantColor)
                if let accent = item.accentColor { ColorSwatch(color: accent) }
                Text("Photo suggestions are editable before saving.")
            }
        }
    }

    private var seasonSection: some View {
        Section {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], alignment: .leading, spacing: 9) {
                ForEach(WardrobeSeason.allCases) { season in
                    Button {
                        toggle(season, in: &item.seasons)
                    } label: {
                        TagPill(text: season.title, selected: item.seasons.contains(season))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("piece-editor-season-\(season.rawValue)")
                    .accessibilityValue(item.seasons.contains(season) ? "Selected" : "Not selected")
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Seasons")
        } footer: {
            Text("Choose every season when you would realistically wear this piece.")
        }
    }

    private var formalitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 9) {
                ForEach(FormalityLevel.allCases) { level in
                    Button {
                        toggle(level, in: &item.formalities)
                    } label: {
                        HStack {
                            Image(systemName: item.formalities.contains(level) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.formalities.contains(level) ? ClosetTheme.accent : .secondary)
                            Text(level.title)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(level.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Formality")
        } footer: {
            Text("A piece can fit more than one level.")
        }
    }

    private var availabilitySection: some View {
        Section("Availability") {
            Picker("Status", selection: $item.availability) {
                ForEach(ItemAvailability.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            Toggle("Favorite", isOn: $item.isFavorite)
        }
    }

    private var isValid: Bool {
        !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !item.seasons.isEmpty &&
            !item.formalities.isEmpty
    }

    private func process(_ selected: PhotosPickerItem) async {
        isProcessingPhoto = true
        defer { isProcessingPhoto = false }
        guard let rawData = try? await selected.loadTransferable(type: Data.self),
              let suggestion = await ClosetImageImporter.makePiece(
                from: rawData,
                index: store.items.count + 1
              ) else { return }

        pendingPhotoSuggestion = suggestion
        selectedPhoto = nil
        showingPhotoOutline = true
    }

    private func applyOutlinedPhoto(_ result: GarmentOutlineResult) {
        guard let suggestion = pendingPhotoSuggestion else { return }
        let colors = ImageUtilities.suggestedColors(from: result.isolatedImageData)

        item.photoData = result.sourceImageData
        item.isolatedPhotoData = result.isolatedImageData
        item.dominantColor = colors?.dominant ?? suggestion.item.dominantColor
        item.accentColor = colors?.accent

        if isNewItem {
            item.category = suggestion.item.category
            item.kind = suggestion.item.kind
            if automaticallyNamed { item.name = item.suggestedName }
            item.seasons = suggestion.item.seasons
            item.formalities = suggestion.item.formalities
            photoSuggestionMessage = suggestion.detection.needsReview
                ? "Outline saved. We filled in a best guess; please review the type and other details."
                : "Outline saved. Name, type, colors, seasons, and formality were suggested from the isolated item."
        } else {
            photoSuggestionMessage = "Outline saved. Colors were refreshed from the isolated item; your existing details were preserved."
        }
        pendingPhotoSuggestion = nil
    }

    @MainActor
    private func reanalyzeCurrentPhoto() async {
        guard let photoData = item.photoData else { return }
        isProcessingPhoto = true
        defer { isProcessingPhoto = false }
        guard let suggestion = await ClosetImageImporter.makePiece(
            from: photoData,
            index: store.items.firstIndex(where: { $0.id == item.id }).map { $0 + 1 } ?? 1,
            confirmedOutlineData: item.isolatedPhotoData
        ) else {
            photoSuggestionMessage = "This photo could not be analyzed. Your current details were left unchanged."
            return
        }

        if item.kind == nil, suggestion.detection.source != .fallback {
            item.category = suggestion.item.category
            item.kind = suggestion.item.kind
        }
        item.dominantColor = suggestion.item.dominantColor
        item.accentColor = suggestion.item.accentColor

        if suggestion.assessment.needsAttention {
            let fields = suggestion.assessment.componentsNeedingAttention.joined(separator: ", ")
            photoSuggestionMessage = "Re-analysis finished. Please check \(fields) before saving. Your name, seasons, and formality were preserved."
        } else {
            photoSuggestionMessage = "Type, colours, and cutout were refreshed. Your name, seasons, and formality were preserved until you save."
        }
    }

    private func toggle<Value: Hashable>(_ value: Value, in set: inout Set<Value>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}

private struct ColorSwatch: View {
    let color: ClothingColor

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(Color(hex: color.hex)).frame(width: 13, height: 13)
            Text(color.name)
        }
        .font(.caption2)
    }
}
