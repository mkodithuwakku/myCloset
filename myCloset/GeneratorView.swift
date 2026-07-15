import SwiftUI

struct GeneratorView: View {
    @EnvironmentObject private var store: ClosetStore
    @EnvironmentObject private var weather: WeatherService
    @State private var occasion: Occasion = .errands
    @State private var formality: FormalityLevel = .casual
    @State private var lockedIDs: Set<UUID> = []
    @State private var outfit: GeneratedOutfit?
    @State private var generationError: OutfitGenerationError?
    @State private var showingLockPicker = false
    @State private var confirmation: String?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 22) {
                    intro
                    occasionSection
                    formalitySection
                    lockedSection
                    generateButton
                    resultSection
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 34)
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .navigationTitle("Generate")
            .sheet(isPresented: $showingLockPicker) {
                LockPickerView(lockedIDs: $lockedIDs)
            }
            .overlay(alignment: .bottom) {
                if let confirmation {
                    Text(confirmation)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(ClosetTheme.ink, in: Capsule())
                        .padding(.bottom, 14)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
            }
            .task {
#if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-generatePrototypeOutfit"), outfit == nil {
                    generate()
                }
#endif
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Dress for what comes next")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(ClosetTheme.ink)
            HStack(spacing: 6) {
                Image(systemName: weather.context.source == .seasonOnly ? "leaf.fill" : "cloud.sun.fill")
                Text(contextDescription)
            }
            .font(.subheadline)
            .foregroundStyle(ClosetTheme.secondaryInk)
        }
        .padding(.top, 4)
    }

    private var occasionSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("What's the occasion?")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(Occasion.allCases) { option in
                        Button {
                            occasion = option
                            formality = option.suggestedFormality
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: option.icon)
                                    .font(.title3)
                                Text(option.title)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(occasion == option ? .white : ClosetTheme.ink)
                            .frame(width: 105, height: 76)
                            .background(occasion == option ? ClosetTheme.accent : ClosetTheme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var formalitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Formality")
                    .font(.headline)
                Spacer()
                Text(formality.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ClosetTheme.accent)
            }
            Slider(value: formalityBinding, in: 1...6, step: 1)
                .accessibilityValue(formality.title)
            HStack {
                Text("Active")
                Spacer()
                Text("Formal")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Locked pieces")
                        .font(.headline)
                    Text("Build the outfit around something you want to wear")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    showingLockPicker = true
                } label: {
                    Label(lockedIDs.isEmpty ? "Choose" : "Edit", systemImage: "lock")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }

            if !lockedItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(lockedItems) { item in
                            Button {
                                lockedIDs.remove(item.id)
                            } label: {
                                HStack(spacing: 7) {
                                    Circle().fill(Color(hex: item.dominantColor.hex)).frame(width: 14, height: 14)
                                    Text(item.name).lineLimit(1)
                                    Image(systemName: "xmark")
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(ClosetTheme.ink)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 9)
                                .background(ClosetTheme.accentSoft, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var generateButton: some View {
        Button {
            generate()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text(outfit == nil ? "Create my outfit" : "Reroll unlocked pieces")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .disabled(store.availableItems.isEmpty)
        .accessibilityIdentifier("generate-outfit-button")
    }

    @ViewBuilder
    private var resultSection: some View {
        if let outfit {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Your outfit")
                        .font(.title2.weight(.bold))
                        .accessibilityIdentifier("generated-outfit-title")
                    Spacer()
                    Text("\(outfit.itemIDs.count) pieces")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                CardSurface {
                    VStack(alignment: .leading, spacing: 13) {
                        ForEach(store.resolve(outfit)) { item in
                            if lockedIDs.contains(item.id) {
                                OutfitItemRow(
                                    item: item,
                                    isLocked: true,
                                    onLock: { toggleLock(item.id) }
                                )
                            } else {
                                OutfitItemRow(
                                    item: item,
                                    isLocked: false,
                                    onLock: { toggleLock(item.id) },
                                    onReroll: { reroll(item) }
                                )
                            }
                            if item.id != store.resolve(outfit).last?.id { Divider() }
                        }
                        Text(outfit.explanation)
                            .font(.footnote)
                            .foregroundStyle(ClosetTheme.secondaryInk)
                            .padding(.top, 3)

                        HStack(spacing: 10) {
                            Button {
                                store.save(outfit)
                                notify("Saved for later")
                            } label: {
                                Label("Save", systemImage: "bookmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                store.markWorn(outfit)
                                notify("Added to worn outfits")
                            } label: {
                                Label("Wore it", systemImage: "checkmark")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        } else if let generationError {
            if store.items.isEmpty {
                EmptyState(
                    icon: "exclamationmark.magnifyingglass",
                    title: "No outfit yet",
                    message: generationError.localizedDescription,
                    actionTitle: "Load sample closet",
                    action: store.loadSamples
                )
            } else {
                EmptyState(
                    icon: "exclamationmark.magnifyingglass",
                    title: "No outfit yet",
                    message: generationError.localizedDescription
                )
            }
        } else if store.items.isEmpty {
            EmptyState(
                icon: "tshirt",
                title: "Fill your closet first",
                message: "Load the sample pieces or add your own to try the generator.",
                actionTitle: "Load sample closet",
                action: store.loadSamples
            )
        }
    }

    private var lockedItems: [ClosetItem] {
        store.items.filter { lockedIDs.contains($0.id) }
    }

    private var formalityBinding: Binding<Double> {
        .init(
            get: { Double(formality.rawValue) },
            set: { formality = FormalityLevel(rawValue: Int($0.rounded())) ?? .casual }
        )
    }

    private var contextDescription: String {
        if let temperature = weather.context.displayTemperature {
            return "\(temperature), \(weather.context.summary.lowercased()) · \(weather.context.locationName ?? "local weather")"
        }
        return "Using \(weather.context.season.title.lowercased()) until you add weather"
    }

    private func generate() {
        let excluded = Set((outfit?.itemIDs ?? []).filter { !lockedIDs.contains($0) })
        var result = store.engine.generate(
            from: store.items,
            occasion: occasion,
            formality: formality,
            weather: weather.context,
            lockedIDs: lockedIDs,
            excluding: excluded
        )
        if case .failure = result {
            result = store.engine.generate(
                from: store.items,
                occasion: occasion,
                formality: formality,
                weather: weather.context,
                lockedIDs: lockedIDs
            )
        }
        apply(result)
    }

    private func reroll(_ item: ClosetItem) {
        guard let outfit else { return }
        let preserved = Set(outfit.itemIDs.filter { $0 != item.id }).union(lockedIDs)
        let result = store.engine.generate(
            from: store.items,
            occasion: occasion,
            formality: formality,
            weather: weather.context,
            lockedIDs: preserved,
            excluding: [item.id]
        )

        if case .success(let updated) = result,
           store.resolve(updated).contains(where: { $0.category == item.category }) {
            apply(result)
        } else {
            generationError = .noMatch
            notify("No alternate \(item.category.title.lowercased()) is available")
        }
    }

    private func toggleLock(_ id: UUID) {
        if lockedIDs.contains(id) {
            lockedIDs.remove(id)
        } else {
            lockedIDs.insert(id)
        }
    }

    private func apply(_ result: Result<GeneratedOutfit, OutfitGenerationError>) {
        switch result {
        case .success(let generated):
            withAnimation {
                outfit = generated
                generationError = nil
            }
        case .failure(let error):
            withAnimation {
                outfit = nil
                generationError = error
            }
        }
    }

    private func notify(_ text: String) {
        withAnimation { confirmation = text }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { confirmation = nil }
        }
    }
}

private struct LockPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ClosetStore
    @Binding var lockedIDs: Set<UUID>

    var body: some View {
        NavigationStack {
            List {
                if store.availableItems.isEmpty {
                    EmptyState(icon: "lock", title: "Nothing to lock", message: "Add an available closet item first.")
                } else {
                    ForEach(ClothingCategory.allCases) { category in
                        let pieces = store.availableItems.filter { $0.category == category }
                        if !pieces.isEmpty {
                            Section(category.title) {
                                ForEach(pieces) { item in
                                    Button {
                                        if lockedIDs.contains(item.id) {
                                            lockedIDs.remove(item.id)
                                        } else {
                                            lockedIDs.insert(item.id)
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            ItemArtwork(photoData: item.photoData, color: item.dominantColor, category: item.category, height: 48)
                                                .frame(width: 48)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            Text(item.name)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Image(systemName: lockedIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundStyle(lockedIDs.contains(item.id) ? ClosetTheme.accent : .secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Lock pieces")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
