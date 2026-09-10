import SwiftUI
import UIKit

struct GarmentOutlineResult {
    let sourceImageData: Data
    let isolatedImageData: Data
}

enum GarmentLassoGeometry {
    static let minimumNormalizedArea = 0.01

    static func isValid(_ points: [CGPoint]) -> Bool {
        polygonArea(points) >= minimumNormalizedArea
    }

    static func polygonArea(_ points: [CGPoint]) -> Double {
        guard points.count >= 3 else { return 0 }
        var twiceArea = 0.0
        for index in points.indices {
            let nextIndex = points.index(after: index) == points.endIndex
                ? points.startIndex
                : points.index(after: index)
            twiceArea += Double(
                points[index].x * points[nextIndex].y
                    - points[nextIndex].x * points[index].y
            )
        }
        return abs(twiceArea) / 2
    }
}

private struct GarmentLassoSelection: Identifiable {
    let id = UUID()
    var points: [CGPoint]
}

struct GarmentOutlineEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var workingImageData: Data
    @State private var selections: [GarmentLassoSelection] = []
    @State private var activeSelectionID: UUID?
    @State private var isTracing = true
    @State private var refinement: GarmentEdgeRefinement?
    @State private var isRefining = false
    @State private var refinementAttempted = false
    @State private var useRefinedEdges = true
    @State private var refinementTask: Task<Void, Never>?
    @State private var refinementID = UUID()

    let imageData: Data
    let onApply: (GarmentOutlineResult) -> Void

    init(
        imageData: Data,
        onApply: @escaping (GarmentOutlineResult) -> Void
    ) {
        self.imageData = imageData
        self.onApply = onApply
        _workingImageData = State(initialValue: imageData)
    }

    private var showingRefinement: Bool { useRefinedEdges && refinement != nil && !isTracing }
    private var image: UIImage? {
        if showingRefinement, let refinement { return UIImage(data: refinement.previewImageData) }
        return UIImage(data: workingImageData)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                instructionCard

                GeometryReader { _ in
                    ZStack {
                        if showingRefinement {
                            TransparencyGrid()
                        } else {
                            Color.black.opacity(0.92)
                        }
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .overlay {
                                    GeometryReader { imageProxy in
                                        if !showingRefinement {
                                            GarmentLassoOverlay(selections: selections)
                                        }

                                        if isTracing {
                                            Color.clear
                                                .contentShape(Rectangle())
                                                .gesture(
                                                    DragGesture(minimumDistance: 0)
                                                        .onChanged { value in
                                                            recordPoint(value.location, in: imageProxy.size)
                                                        }
                                                        .onEnded { _ in
                                                            activeSelectionID = nil
                                                            isTracing = false
                                                            startRefinement()
                                                        }
                                                )
                                                .accessibilityLabel("Trace around the outside edge of the item")
                                                .accessibilityIdentifier("outline-canvas")
                                                .accessibilityElement()
                                        }
                                    }
                                }
                                .padding(12)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(ClosetTheme.ink.opacity(0.14))
                    }
                }

                refinementControls
                controls
            }
            .padding(16)
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Button {
                    applyOutline()
                } label: {
                    Label(showingRefinement ? "Use refined cutout" : "Use this outline", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .tint(ClosetTheme.accent)
                .disabled(!hasValidSelection || isTracing || isRefining)
                .accessibilityHint(showingRefinement ? "Keeps the cutout shown on the checkerboard" : "Keeps the shaded area and removes everything outside it")
                .accessibilityIdentifier("apply-item-outline")
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
            .navigationTitle("Outline item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("outline-editor")
        .onDisappear { cancelRefinement() }
#if DEBUG
        .onAppear {
            // Repeatable comparison/recovery UI coverage without synthesizing a
            // multi-segment finger gesture. Normal imports always start empty.
            if ProcessInfo.processInfo.arguments.contains("-previewPrototypeRefinedOutline"), selections.isEmpty {
                selections = [.init(points: [
                    CGPoint(x: 0.17, y: 0.11), CGPoint(x: 0.83, y: 0.11),
                    CGPoint(x: 0.83, y: 0.89), CGPoint(x: 0.17, y: 0.89)
                ])]
                isTracing = false
                startRefinement()
            }
        }
#endif
    }

    private var instructionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: hasValidSelection ? "checkmark.circle.fill" : "hand.draw.fill")
                .font(.title2)
                .foregroundStyle(hasValidSelection ? ClosetTheme.accent : Color.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(showingRefinement ? "Check the refined edges" : hasValidSelection ? "Outline ready" : "Trace the item once")
                    .font(.headline)
                Text(instructionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("For a pair of shoes, outline one shoe, tap Add another area, then outline the other. Keep the space between them outside both outlines.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("outline-shoe-pair-guidance")
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var refinedInstruction: String {
        "Compare both versions and check sleeves, hems and shoes. Shading shows your outline; the checkerboard shows transparent areas."
    }

    private var instructionText: String {
        if isTracing {
            return "Trace close to the item's edge, then lift. It doesn't need to be perfect — we'll look for the nearby fabric edge."
        }
        // Both comparison modes use identical guidance so toggling cannot
        // resize or move the photo while the user compares its edges.
        if refinement != nil {
            return refinedInstruction
        }
        if hasValidSelection {
            return "The shaded area is what will remain. Everything outside it will be transparent."
        }
        return "That outline did not enclose an area. Clear it and trace around the item again."
    }

    @ViewBuilder
    private var refinementControls: some View {
        if hasValidSelection && !isTracing {
            if isRefining {
                HStack {
                    ProgressView("Finding the fabric edge…")
                        .font(.caption)
                        .accessibilityIdentifier("outline-refining")
                    Spacer()
                    Button("Keep my outline") { cancelRefinement() }
                        .font(.caption.weight(.semibold))
                        .accessibilityIdentifier("outline-cancel-refinement")
                }
            } else if refinement != nil {
                Picker("Cutout version", selection: $useRefinedEdges) {
                    Text("Refined").tag(true)
                    Text("My outline").tag(false)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("outline-version")
            } else if refinementAttempted {
                Text("Couldn't confidently refine these edges. Your outline is unchanged; you can use it or retrace.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("outline-refinement-unavailable")
            }
        }
    }

    private func startRefinement() {
        cancelRefinement()
        guard hasValidSelection else { return }
        isRefining = true
        let requestID = refinementID
        let data = workingImageData
        let outlines = selections.map(\.points)
        refinementTask = Task { @MainActor in
            let worker = Task.detached(priority: .userInitiated) {
                GarmentEdgeRefiner.refine(from: data, normalizedOutlines: outlines)
            }
            let result = await withTaskCancellationHandler {
                await worker.value
            } onCancel: {
                worker.cancel()
            }
            guard !Task.isCancelled, refinementID == requestID else { return }
            refinement = result
            refinementAttempted = true
            isRefining = false
        }
    }

    private func cancelRefinement() {
        refinementTask?.cancel()
        refinementTask = nil
        refinementID = UUID()
        refinement = nil
        refinementAttempted = false
        isRefining = false
        useRefinedEdges = true
    }

    private var controls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button("Rotate left", systemImage: "rotate.left") {
                    rotate(by: -1)
                }
                .accessibilityIdentifier("outline-rotate-left")

                Button("Rotate right", systemImage: "rotate.right") {
                    rotate(by: 1)
                }
                .accessibilityIdentifier("outline-rotate-right")

                Button("Reset", systemImage: "arrow.counterclockwise") {
                    workingImageData = imageData
                    clearAndRetrace()
                }
                .accessibilityIdentifier("outline-reset")
            }

            if !selections.isEmpty {
                HStack(spacing: 10) {
                    if hasValidSelection && !isTracing {
                        Button("Add another area", systemImage: "plus.circle") {
                            cancelRefinement()
                            isTracing = true
                            activeSelectionID = nil
                        }
                        .accessibilityIdentifier("outline-add-area")
                    }

                    Button("Clear and retrace", systemImage: "eraser") {
                        clearAndRetrace()
                    }
                    .accessibilityIdentifier("outline-clear")
                }
            }
        }
        .font(.caption.weight(.semibold))
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
    }

    private var hasValidSelection: Bool {
        selections.contains { GarmentLassoGeometry.isValid($0.points) }
    }

    private func recordPoint(_ location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let point = CGPoint(
            x: min(1, max(0, location.x / size.width)),
            y: min(1, max(0, location.y / size.height))
        )
        if let activeSelectionID,
           let index = selections.firstIndex(where: { $0.id == activeSelectionID }) {
            selections[index].points.append(point)
        } else {
            let selection = GarmentLassoSelection(points: [point])
            selections.append(selection)
            activeSelectionID = selection.id
        }
    }

    private func rotate(by quarterTurns: Int) {
        workingImageData = ImageUtilities.rotatedImageData(
            from: workingImageData,
            quarterTurns: quarterTurns
        ) ?? workingImageData
        clearAndRetrace()
    }

    private func clearAndRetrace() {
        cancelRefinement()
        selections = []
        activeSelectionID = nil
        isTracing = true
    }

    private func applyOutline() {
        guard hasValidSelection, !isTracing, !isRefining else { return }
        guard let isolated = showingRefinement ? refinement?.isolatedImageData : ImageUtilities.outlinedCutoutData(
            from: workingImageData,
            normalizedOutlines: selections.map(\.points)
        ) else { return }
        cancelRefinement()
        onApply(.init(sourceImageData: workingImageData, isolatedImageData: isolated))
        dismiss()
    }
}

private struct GarmentLassoOverlay: View {
    let selections: [GarmentLassoSelection]

    var body: some View {
        Canvas { context, size in
            for selection in selections where !selection.points.isEmpty {
                var path = Path()
                let first = selection.points[0]
                path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
                for point in selection.points.dropFirst() {
                    path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
                }
                if selection.points.count >= 3 {
                    path.closeSubpath()
                    context.fill(path, with: .color(ClosetTheme.accentSoft.opacity(0.28)))
                }
                context.stroke(
                    path,
                    with: .color(ClosetTheme.accentSoft),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct TransparencyGrid: View {
    var body: some View {
        Canvas { context, size in
            let side: CGFloat = 12
            for row in 0...Int(size.height / side) {
                for column in 0...Int(size.width / side) {
                    let rect = CGRect(x: CGFloat(column) * side, y: CGFloat(row) * side, width: side, height: side)
                    context.fill(Path(rect), with: .color((row + column).isMultiple(of: 2)
                        ? Color(white: 0.93) : Color(white: 0.83)))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
