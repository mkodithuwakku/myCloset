import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: ClosetStore
    @EnvironmentObject private var weather: WeatherService
    @State private var showingWeather = false
    @State private var confirmation: String?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 34) {
                    header
                    dailySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingWeather) {
                WeatherSettingsView()
                    .presentationDetents([.medium, .large])
            }
            .task {
                store.refreshDaily(weather: weather.context)
            }
            .onChange(of: weather.context) { _, newContext in
                store.refreshDaily(weather: newContext, force: true)
            }
            .onChange(of: store.items) { _, _ in
                store.refreshDaily(weather: weather.context, force: true)
            }
            .overlay(alignment: .bottom) {
                if let confirmation {
                    Text(confirmation)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .foregroundStyle(.white)
                        .background(ClosetTheme.ink, in: Capsule())
                        .padding(.bottom, 14)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack {
                Text("myCloset")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(ClosetTheme.ink)
                Spacer()
                Button {
                    showingWeather = true
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: weather.context.source == .seasonOnly ? "leaf" : "cloud.sun")
                        Text(weather.context.displayTemperature ?? weather.context.season.title)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ClosetTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.055), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Weather settings, \(weatherSubtitle)")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ClosetTheme.accent)
                    .textCase(.uppercase)
                Text("Good \(dayPart), \(firstName).")
                    .font(.system(size: 40, weight: .medium, design: .serif))
                    .tracking(-1.2)
                    .foregroundStyle(ClosetTheme.ink)
            }
        }
    }

    @ViewBuilder
    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Outfit of the day")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(ClosetTheme.ink)
                Spacer()
                if store.dailyOutfit != nil {
                    Button {
                        store.refreshDaily(weather: weather.context, force: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.medium))
                            .frame(width: 34, height: 34)
                            .background(Color.primary.opacity(0.055), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Refresh daily outfit")
                }
            }

            if let outfit = store.dailyOutfit {
                let items = store.resolve(outfit)
                OutfitCanvas(
                    items: items,
                    height: 390,
                    accessibilityIdentifier: "daily-outfit-composition"
                )

                Text(outfit.explanation)
                    .font(.subheadline)
                    .foregroundStyle(ClosetTheme.secondaryInk)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button {
                        store.markWorn(outfit)
                        showConfirmation("Added to worn outfits")
                    } label: {
                        Text("I wore this")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)

                    Button {
                        store.save(outfit)
                        showConfirmation("Saved for later")
                    } label: {
                        Image(systemName: "bookmark")
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Save outfit for later")
                }
                .tint(ClosetTheme.ink)
            } else {
                minimalEmptyState
            }
        }
    }

    private var minimalEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "tshirt")
                .font(.title2)
                .foregroundStyle(ClosetTheme.accent)
            Text("Your outfit is waiting")
                .font(.headline)
                .foregroundStyle(ClosetTheme.ink)
            Text(store.dailyError?.localizedDescription ?? "Add enough pieces for a top, bottom, and shoes.")
                .font(.subheadline)
                .foregroundStyle(ClosetTheme.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
            if store.items.isEmpty {
                Text("Import your own images from Closet to begin.")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ClosetTheme.accent)
                    .padding(.top, 2)
            }
        }
        .padding(.top, 4)
    }

    private var firstName: String {
        let displayName = store.profile.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !displayName.isEmpty,
              displayName.localizedCaseInsensitiveCompare("Your name") != .orderedSame else {
            return "there"
        }
        return displayName.split(separator: " ").first.map(String.init) ?? "there"
    }

    private var dayPart: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: "morning"
        case 12..<17: "afternoon"
        default: "evening"
        }
    }

    private var weatherSubtitle: String {
        if weather.isLoading { return "Refreshing weather…" }
        if let location = weather.context.locationName {
            return "\(weather.context.summary) · \(location)"
        }
        return "Season-aware recommendation · tap to add weather"
    }

    private func showConfirmation(_ message: String) {
        withAnimation { confirmation = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { confirmation = nil }
        }
    }
}

private struct WeatherSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var weather: WeatherService

    var body: some View {
        NavigationStack {
            Form {
                Section("Current context") {
                    LabeledContent("Source", value: sourceTitle)
                    LabeledContent("Season", value: weather.context.season.title)
                    if let temperature = weather.context.displayTemperature {
                        LabeledContent("Temperature", value: temperature)
                    }
                    if let error = weather.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }

                Section("Use current location") {
                    Button {
                        weather.requestCurrentWeather()
                    } label: {
                        Label(weather.isLoading ? "Refreshing…" : "Use my location", systemImage: "location.fill")
                    }
                    .disabled(weather.isLoading)
                }

                Section("Or choose a city") {
                    TextField("City, province, or country", text: $weather.cityQuery)
                        .textContentType(.addressCity)
                        .submitLabel(.search)
                        .onSubmit { weather.useCity() }
                    Button("Use this city") { weather.useCity() }
                        .disabled(weather.isLoading || weather.cityQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Section {
                    Button("Use season only") { weather.useSeasonOnly() }
                } footer: {
                    Text("Location is optional. Season-only recommendations use today's date and do not contact the weather service.")
                }
            }
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var sourceTitle: String {
        switch weather.context.source {
        case .currentLocation: "Current location"
        case .city: "Selected city"
        case .seasonOnly: "Season only"
        }
    }
}
