import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ClosetStore
    @EnvironmentObject private var weather: WeatherService
    @State private var showingWeather = false
    @State private var confirmation: String?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 22) {
                    greeting
                    weatherCard
                    dailySection
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .navigationTitle("myCloset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingWeather = true
                    } label: {
                        Image(systemName: "cloud.sun.fill")
                    }
                    .accessibilityLabel("Weather settings")
                }
            }
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

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.caption.weight(.semibold))
                .foregroundStyle(ClosetTheme.accent)
                .textCase(.uppercase)
            Text("Good \(dayPart), \(firstName)")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(ClosetTheme.ink)
            Text("Let's make getting dressed feel easy.")
                .font(.subheadline)
                .foregroundStyle(ClosetTheme.secondaryInk)
        }
        .padding(.top, 8)
    }

    private var weatherCard: some View {
        Button {
            showingWeather = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: weather.context.source == .seasonOnly ? "leaf.fill" : "cloud.sun.fill")
                    .font(.title2)
                    .foregroundStyle(ClosetTheme.ink)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.58), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(weather.context.displayTemperature ?? weather.context.season.title)
                        .font(.headline)
                    Text(weatherSubtitle)
                        .font(.caption)
                        .foregroundStyle(ClosetTheme.secondaryInk)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(ClosetTheme.sage, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Outfit of the day")
                        .font(.title2.weight(.bold))
                    Text("A comfortable starting point for today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if store.dailyOutfit != nil {
                    Button {
                        store.refreshDaily(weather: weather.context, force: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .accessibilityLabel("Refresh daily outfit")
                }
            }

            if let outfit = store.dailyOutfit {
                CardSurface {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(store.resolve(outfit)) { item in
                            OutfitItemRow(item: item)
                            if item.id != store.resolve(outfit).last?.id { Divider() }
                        }
                        Text(outfit.explanation)
                            .font(.footnote)
                            .foregroundStyle(ClosetTheme.secondaryInk)
                            .padding(.top, 2)
                        HStack {
                            Button {
                                store.save(outfit)
                                showConfirmation("Saved for later")
                            } label: {
                                Label("Save", systemImage: "bookmark")
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                            Button {
                                store.markWorn(outfit)
                                showConfirmation("Added to worn outfits")
                            } label: {
                                Label("I wore this", systemImage: "checkmark")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            } else {
                EmptyState(
                    icon: "tshirt",
                    title: "Your outfit is waiting",
                    message: store.dailyError?.localizedDescription ?? "Add enough pieces for a top, bottom, and shoes.",
                    actionTitle: store.items.isEmpty ? "Load sample closet" : nil,
                    action: store.items.isEmpty ? { store.loadSamples(); store.refreshDaily(weather: weather.context, force: true) } : nil
                )
            }
        }
    }

    private var firstName: String {
        store.profile.displayName.split(separator: " ").first.map(String.init) ?? "there"
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
