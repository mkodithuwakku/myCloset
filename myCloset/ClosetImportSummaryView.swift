import SwiftUI

struct ClosetImportSummary: Identifiable {
    let id = UUID()
    let importedItems: [ClosetItem]
    let availableClosetItems: [ClosetItem]
    let skipped: Int
    let failures: Int

    var canGenerateOutfit: Bool {
        let categories = Set(availableClosetItems.map(\.category))
        return categories.contains(.onePiece) ||
            (categories.contains(.top) && categories.contains(.bottom))
    }

    var readinessMessage: String {
        guard !canGenerateOutfit else {
            return "Your closet has the pieces needed to generate an outfit."
        }

        let categories = Set(availableClosetItems.map(\.category))
        if categories.contains(.top) {
            return "Add an available bottom or one-piece to generate an outfit."
        }
        if categories.contains(.bottom) {
            return "Add an available top or one-piece to generate an outfit."
        }
        return "Add an available top and bottom, or one one-piece, to generate an outfit."
    }

    func count(in category: ClothingCategory) -> Int {
        importedItems.count { $0.category == category }
    }
}

struct ClosetImportSummaryView: View {
    let summary: ClosetImportSummary
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: summary.importedItems.isEmpty ? "photo.badge.minus" : "checkmark.circle.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(summary.importedItems.isEmpty ? Color.orange : ClosetTheme.accent)
                        Text(summary.importedItems.isEmpty
                             ? "No pieces added"
                             : "\(summary.importedItems.count) piece\(summary.importedItems.count == 1 ? "" : "s") added")
                            .font(.largeTitle.bold())
                        Text("Here’s what this import added to your closet.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        ForEach(ClothingCategory.allCases) { category in
                            HStack {
                                Label(category.title, systemImage: category.icon)
                                Spacer()
                                Text("\(summary.count(in: category))")
                                    .font(.title3.monospacedDigit().weight(.semibold))
                            }
                            .padding(.vertical, 12)
                            if category != ClothingCategory.allCases.last {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 16))

                    Label(
                        summary.readinessMessage,
                        systemImage: summary.canGenerateOutfit ? "sparkles" : "exclamationmark.triangle.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(summary.canGenerateOutfit ? ClosetTheme.accent : Color.orange)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityIdentifier("import-summary-readiness")

                    if summary.skipped > 0 || summary.failures > 0 {
                        Text(resultDetails)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .navigationTitle("Import complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("import-summary-done")
                }
            }
        }
        .accessibilityIdentifier("import-summary-screen")
    }

    private var resultDetails: String {
        var details: [String] = []
        if summary.skipped > 0 {
            details.append("\(summary.skipped) photo\(summary.skipped == 1 ? " was" : "s were") skipped.")
        }
        if summary.failures > 0 {
            details.append("\(summary.failures) image\(summary.failures == 1 ? "" : "s") could not be read.")
        }
        return details.joined(separator: " ")
    }
}
