import SwiftUI

struct GeneratorView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var store: ClosetStore
    @EnvironmentObject private var weather: WeatherService
    @State private var occasion: Occasion = .errands
    @State private var formality: FormalityLevel = .casual
    @State private var lockedIDs: Set<UUID> = []
    @State private var outfit: GeneratedOutfit?
    @State private var generationError: OutfitGenerationError?
    @State private var showingBrief = false
    @State private var shouldScrollToResult = false
    @State private var confirmation: String?
    @State private var generationRevision = 0

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        masthead
                        Divider().overlay(ClosetTheme.ink.opacity(0.24))
                        resultSection
                            .id("outfit-result")
                        generatorControls
                        if outfit != nil {
                            pieceControls
                            outfitActions
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 44)
                }
                .onChange(of: generationRevision) { _, _ in
                    guard shouldScrollToResult else { return }
                    shouldScrollToResult = false
                    withAnimation(.smooth) {
                        proxy.scrollTo("outfit-result", anchor: .top)
                    }
                }
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingBrief) {
                OutfitBriefSheet(
                    occasion: $occasion,
                    formality: $formality
                ) {
                    shouldScrollToResult = true
                    generate(userInitiated: true)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .overlay(alignment: .bottom) {
                if let confirmation {
                    Text(confirmation)
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                        .foregroundStyle(ClosetTheme.canvas)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(ClosetTheme.ink, in: RoundedRectangle(cornerRadius: 3))
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .task {
                generateIfNeeded()
            }
            .onChange(of: store.items) { _, _ in
                discardMissingLocks()
                generateIfNeeded()
            }
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("THE FITTING ROOM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2.2)
                Spacer()
                Text(Date.now.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(ClosetTheme.secondaryInk)

            Text("What should\nI wear?")
                .font(.system(size: 45, weight: .medium, design: .serif))
                .tracking(-1.8)
                .foregroundStyle(ClosetTheme.ink)
                .lineSpacing(-5)

            HStack(spacing: 7) {
                Image(systemName: weather.context.source == .seasonOnly ? "leaf" : "cloud.sun")
                Text(contextDescription)
                    .lineLimit(1)
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(ClosetTheme.secondaryInk)
            .padding(.bottom, 14)
        }
    }

    @ViewBuilder
    private var resultSection: some View {
        if let outfit {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("CURRENT LOOK")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.8)
                        .accessibilityIdentifier("generated-outfit-title")
                    Spacer()
                    Text("\(outfit.itemIDs.count) PIECES")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(ClosetTheme.secondaryInk)
                }
                .padding(.top, 16)

                OutfitCanvas(
                    items: store.resolve(outfit),
                    height: 448,
                    accessibilityIdentifier: "generated-outfit-composition"
                )
                .id(outfit.itemIDs)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

                Text(outfit.explanation)
                    .font(.system(.subheadline, design: .serif))
                    .italic()
                    .foregroundStyle(ClosetTheme.secondaryInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)
            }
        } else {
            generatorEmptyState
                .padding(.vertical, 18)
        }
    }

    private var generatorEmptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                ClosetTheme.board
                VStack(spacing: 12) {
                    Text("NO LOOK / YET")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(2)
                    Image(systemName: "hanger")
                        .font(.system(size: 54, weight: .ultraLight))
                    Text(emptyMessage)
                        .font(.system(.subheadline, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(ClosetTheme.secondaryInk)
                        .frame(maxWidth: 250)
                }
            }
            .frame(height: 360)
            .overlay { Rectangle().stroke(ClosetTheme.ink.opacity(0.16), lineWidth: 1) }

            if generationError != nil, !store.items.isEmpty {
                closetReadiness
            }
        }
    }

    private var closetReadiness: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("CLOSET CHECK")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .tracking(1.6)

            HStack(spacing: 0) {
                readinessMetric("TOPS", count: availableCount(in: .top))
                readinessMetric("BOTTOMS", count: availableCount(in: .bottom))
                readinessMetric("ONE-PIECE", count: availableCount(in: .onePiece))
            }

            Text("A look needs a top and bottom, or one one-piece. In Closet, use the + menu’s Re-analyze photo details action to repair older automatic labels in one pass.")
                .font(.caption)
                .foregroundStyle(ClosetTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                selectedTab = 1
            } label: {
                HStack {
                    Text("Fix photo details in Closet")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ClosetTheme.ink)
                .frame(height: 44)
            }
            .buttonStyle(.plain)
            .overlay(alignment: .bottom) { Divider() }
        }
        .padding(14)
        .background(ClosetTheme.card)
        .overlay { Rectangle().stroke(ClosetTheme.ink.opacity(0.15), lineWidth: 1) }
    }

    private func readinessMetric(_ title: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)")
                .font(.system(size: 24, weight: .medium, design: .serif))
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .tracking(0.7)
                .foregroundStyle(ClosetTheme.secondaryInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var generatorControls: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button {
                    shouldScrollToResult = true
                    generate(userInitiated: true)
                } label: {
                    HStack {
                        Text(outfit == nil ? "Make a look" : "Another look")
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                    }
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(ClosetTheme.canvas)
                    .padding(.horizontal, 17)
                    .frame(height: 54)
                    .background(ClosetTheme.ink, in: RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)
                .disabled(store.availableItems.isEmpty)
                .opacity(store.availableItems.isEmpty ? 0.45 : 1)
                .accessibilityIdentifier("generate-outfit-button")

                Button {
                    showingBrief = true
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "wand.and.stars")
                            .font(.subheadline.weight(.semibold))
                        Text("Brief")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(ClosetTheme.ink)
                    .frame(width: 66, height: 54)
                    .background(ClosetTheme.signal, in: RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change outfit brief")
            }
            .padding(.top, 18)

            HStack(spacing: 6) {
                Text(occasion.title)
                Text("/")
                Text(formality.title)
                if !lockedIDs.isEmpty {
                    Text("/")
                    Text("\(lockedIDs.count) locked")
                }
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(ClosetTheme.secondaryInk)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 9)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private var pieceControls: some View {
        if let outfit {
            VStack(alignment: .leading, spacing: 0) {
                Text("PIECES / TAP TO REFINE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .padding(.bottom, 8)

                ForEach(store.resolve(outfit)) { item in
                    HStack(spacing: 12) {
                        ItemArtwork(
                            photoData: item.photoData,
                            color: item.dominantColor,
                            category: item.category,
                            height: 54
                        )
                        .frame(width: 54)
                        .clipped()

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                            Text("\(item.category.title.uppercased()) / \(item.dominantColor.name.uppercased())")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .tracking(0.8)
                                .foregroundStyle(ClosetTheme.secondaryInk)
                        }
                        Spacer(minLength: 4)

                        if !lockedIDs.contains(item.id) {
                            Button { reroll(item) } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .frame(width: 38, height: 38)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Reroll \(item.name)")
                        }

                        Button { toggleLock(item.id) } label: {
                            Image(systemName: lockedIDs.contains(item.id) ? "lock.fill" : "lock.open")
                                .foregroundStyle(lockedIDs.contains(item.id) ? ClosetTheme.accent : ClosetTheme.secondaryInk)
                                .frame(width: 38, height: 38)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(lockedIDs.contains(item.id) ? "Unlock \(item.name)" : "Lock \(item.name)")
                    }
                    .padding(.vertical, 9)

                    if item.id != store.resolve(outfit).last?.id {
                        Divider()
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
    }

    @ViewBuilder
    private var outfitActions: some View {
        if let outfit {
            HStack(spacing: 0) {
                Button {
                    store.save(outfit)
                    notify("Saved for later")
                } label: {
                    Label("Save", systemImage: "bookmark")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }

                Divider().frame(height: 50)

                Button {
                    store.markWorn(outfit)
                    notify("Added to worn outfits")
                } label: {
                    Label("I wore this", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(ClosetTheme.ink)
            .buttonStyle(.plain)
            .overlay { Rectangle().stroke(ClosetTheme.ink.opacity(0.22), lineWidth: 1) }
        }
    }

    private var contextDescription: String {
        if let temperature = weather.context.displayTemperature {
            return "\(temperature) / \(weather.context.summary.uppercased()) / \(weather.context.locationName ?? "LOCAL")"
        }
        return "\(weather.context.season.title.uppercased()) / SEASON-AWARE"
    }

    private var emptyMessage: String {
        if let generationError {
            return generationError.localizedDescription
        }
        return store.items.isEmpty
            ? "Import your own images in Closet, then this space becomes your outfit board."
            : "Your closet is ready. Make a look to begin."
    }

    private func generateIfNeeded() {
        guard outfit == nil, !store.availableItems.isEmpty else { return }
        generate()
    }

    private func generate(userInitiated: Bool = false) {
        let result: Result<GeneratedOutfit, OutfitGenerationError>
        if let outfit {
            result = store.engine.generateAlternative(
                to: outfit,
                from: store.items,
                occasion: occasion,
                formality: formality,
                weather: weather.context,
                lockedIDs: lockedIDs
            )
        } else {
            result = store.engine.generate(
                from: store.items,
                occasion: occasion,
                formality: formality,
                weather: weather.context,
                lockedIDs: lockedIDs
            )
        }
        apply(
            result,
            preservingCurrentLook: outfit != nil,
            announceFailure: userInitiated
        )
        if userInitiated {
            generationRevision += 1
        }
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

    private func discardMissingLocks() {
        lockedIDs.formIntersection(Set(store.items.map(\.id)))
        if let outfit,
           store.resolve(outfit).count != outfit.itemIDs.count {
            self.outfit = nil
        }
    }

    private func apply(
        _ result: Result<GeneratedOutfit, OutfitGenerationError>,
        preservingCurrentLook: Bool = false,
        announceFailure: Bool = false
    ) {
        switch result {
        case .success(let generated):
            let repeatedCurrentLook = outfit?.itemIDs == generated.itemIDs
            withAnimation(.snappy) {
                outfit = generated
                generationError = nil
            }
            if repeatedCurrentLook {
                notify("That is the only valid combination with this closet and brief")
            }
        case .failure(let error):
            withAnimation(.snappy) {
                if !preservingCurrentLook {
                    outfit = nil
                }
                generationError = error
            }
            if preservingCurrentLook || announceFailure {
                notify(error.localizedDescription)
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

    private func availableCount(in category: ClothingCategory) -> Int {
        store.availableItems.filter { $0.category == category }.count
    }
}

private struct OutfitBriefSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var occasion: Occasion
    @Binding var formality: FormalityLevel
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    header
                    scenePicker
                    formalityPicker
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 110)
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                Button {
                    dismiss()
                    onApply()
                } label: {
                    HStack {
                        Text("Style this brief")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(ClosetTheme.canvas)
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(ClosetTheme.ink, in: RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .accessibilityIdentifier("apply-outfit-brief")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text("THE BRIEF")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(2)
                Spacer()
                Button("Done") { dismiss() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ClosetTheme.ink)
            }
            Text("Set the scene.")
                .font(.system(size: 40, weight: .medium, design: .serif))
                .tracking(-1.2)
            Text("A nudge, not a questionnaire. Pick a place and a level; the closet does the rest.")
                .font(.subheadline)
                .foregroundStyle(ClosetTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var scenePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("01 / WHERE TO?")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Occasion.allCases) { option in
                        Button {
                            occasion = option
                            formality = option.suggestedFormality
                        } label: {
                            VStack(alignment: .leading, spacing: 14) {
                                Image(systemName: option.icon)
                                    .font(.title3)
                                Text(option.briefTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .foregroundStyle(ClosetTheme.ink)
                            .padding(13)
                            .frame(width: 112, height: 92, alignment: .leading)
                            .background(occasion == option ? ClosetTheme.signal : ClosetTheme.board)
                            .overlay {
                                Rectangle().stroke(
                                    ClosetTheme.ink.opacity(occasion == option ? 0.65 : 0.14),
                                    lineWidth: occasion == option ? 1.5 : 1
                                )
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(occasion == option ? .isSelected : [])
                    }
                }
            }
            .contentMargins(.horizontal, 1, for: .scrollContent)
        }
    }

    private var formalityPicker: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("02 / HOW DRESSED UP?")
            Text(formality.title)
                .font(.system(size: 29, weight: .medium, design: .serif))

            ZStack {
                Rectangle()
                    .fill(ClosetTheme.ink.opacity(0.18))
                    .frame(height: 1)
                    .padding(.horizontal, 19)

                HStack(spacing: 0) {
                    ForEach(FormalityLevel.allCases) { level in
                        Button {
                            formality = level
                        } label: {
                            Circle()
                                .fill(formality == level ? ClosetTheme.ink : ClosetTheme.canvas)
                                .frame(width: formality == level ? 22 : 13, height: formality == level ? 22 : 13)
                                .overlay {
                                    Circle().stroke(ClosetTheme.ink, lineWidth: 1.5)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(level.title)
                        .accessibilityAddTraits(formality == level ? .isSelected : [])
                    }
                }
            }

            HStack {
                Text("RELAXED")
                Spacer()
                Text("DRESSED UP")
            }
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .tracking(1.1)
            .foregroundStyle(ClosetTheme.secondaryInk)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .tracking(1.5)
            .foregroundStyle(ClosetTheme.secondaryInk)
    }
}

private extension Occasion {
    var briefTitle: String {
        switch self {
        case .bar: "Night out"
        case .sport: "Workout"
        case .home: "At home"
        case .wedding: "Wedding"
        default: title
        }
    }
}
