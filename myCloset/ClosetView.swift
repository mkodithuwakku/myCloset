import PhotosUI
import SwiftUI

struct ClosetView: View {
    @EnvironmentObject private var store: ClosetStore
    @State private var searchText = ""
    @State private var selectedCategory: ClothingCategory?
    @State private var showingEditor = false
    @State private var editingItem: ClosetItem?

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
                        Button {
                            editingItem = nil
                            showingEditor = true
                        } label: {
                            Label("Add piece", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                    }
                    .padding(.horizontal, 16)
                    categoryFilters
                    if filteredItems.isEmpty {
                        if store.items.isEmpty && searchText.isEmpty {
                            EmptyState(
                                icon: "hanger",
                                title: "Start your closet",
                                message: "Add your own clothing or load a sample closet to try the generator immediately.",
                                actionTitle: "Load sample closet",
                                action: { store.loadSamples() }
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
                                    editingItem = item
                                    showingEditor = true
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
            .sheet(isPresented: $showingEditor) {
                ClosetItemEditor(existingItem: editingItem)
            }
        }
    }

    private var filteredItems: [ClosetItem] {
        store.visibleItems.filter { item in
            let matchesSearch = searchText.isEmpty || item.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button {
                    withAnimation { selectedCategory = nil }
                } label: {
                    TagPill(text: "All", selected: selectedCategory == nil)
                }
                .buttonStyle(.plain)
                ForEach(ClothingCategory.allCases) { category in
                    Button {
                        withAnimation { selectedCategory = category }
                    } label: {
                        TagPill(text: category.title, icon: category.icon, selected: selectedCategory == category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

private struct ClosetItemCard: View {
    @EnvironmentObject private var store: ClosetStore
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
                        Text(item.category.title)
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
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.05))
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
        }
    }
}

private struct ClosetItemEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ClosetStore
    @State private var item: ClosetItem
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isProcessingPhoto = false
    @State private var showingDeleteConfirmation = false

    init(existingItem: ClosetItem?) {
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
        }
    }

    private var photoSection: some View {
        Section {
            VStack(spacing: 12) {
                ZStack {
                    ItemArtwork(photoData: item.photoData, color: item.dominantColor, category: item.category, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    if item.photoData == nil {
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(.white.opacity(0.75), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                            .frame(width: 160, height: 182)
                            .overlay(alignment: .bottom) {
                                Text("Centre the \(item.category.title.lowercased())")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.bottom, 12)
                            }
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

                Text("For the cleanest color result, use even light and a plain background that contrasts with the item.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 6)
        }
    }

    private var detailsSection: some View {
        Section("Piece details") {
            TextField("Name", text: $item.name)
                .textInputAutocapitalization(.words)
            Picker("Category", selection: $item.category) {
                ForEach(ClothingCategory.allCases) { category in
                    Label(category.title, systemImage: category.icon).tag(category)
                }
            }
        }
    }

    private var colorSection: some View {
        Section {
            Picker("Dominant color", selection: $item.dominantColor) {
                ForEach(ClothingColor.palette) { color in
                    Text(color.name).tag(color)
                }
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
              let prepared = ImageUtilities.preparedImageData(from: rawData) else { return }
        item.photoData = prepared
        if let colors = ImageUtilities.suggestedColors(from: prepared) {
            item.dominantColor = colors.dominant
            item.accentColor = colors.accent
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
