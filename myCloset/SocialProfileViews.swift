import PhotosUI
import SwiftUI

struct FollowingView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer()

                Image(systemName: "person.2.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(ClosetTheme.accent)
                    .frame(width: 88, height: 88)
                    .background(ClosetTheme.accentSoft, in: Circle())

                VStack(spacing: 8) {
                    Text("Coming soon")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(ClosetTheme.ink)

                    Text("Profiles and outfit inspiration are planned for after launch.")
                        .font(.body)
                        .foregroundStyle(ClosetTheme.secondaryInk)
                        .multilineTextAlignment(.center)

                    Text("Your closet will always stay private.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ClosetTheme.ink)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 320)

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: ClosetStore
    @State private var segment: ProfileSegment = .worn
    @State private var showingEditProfile = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 20) {
                    profileHeader
                    stats
                    history
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 34)
            }
            .background(ClosetTheme.canvas.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Prototype settings")
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                ProfileEditor()
            }
            .sheet(isPresented: $showingSettings) {
                PrototypeSettingsView()
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ProfileImage(data: store.profile.photoData, size: 94)
            VStack(spacing: 3) {
                Text(store.profile.displayName)
                    .font(.title2.weight(.bold))
                Text("@\(store.profile.handle)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(store.profile.bio)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(ClosetTheme.secondaryInk)
                .frame(maxWidth: 320)
            Button("Edit profile") {
                showingEditProfile = true
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var stats: some View {
        HStack(spacing: 0) {
            ProfileStat(value: store.visibleItems.count, label: "Pieces")
            Divider().frame(height: 38)
            ProfileStat(value: store.savedOutfits.count, label: "Saved")
            Divider().frame(height: 38)
            ProfileStat(value: store.wornOutfits.count, label: "Worn")
        }
        .padding(.vertical, 15)
        .background(ClosetTheme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Outfit history", selection: $segment) {
                ForEach(ProfileSegment.allCases) { segment in
                    Text(segment.title).tag(segment)
                }
            }
            .pickerStyle(.segmented)

            if records.isEmpty {
                EmptyState(
                    icon: segment == .worn ? "checkmark.circle" : "bookmark",
                    title: segment == .worn ? "Nothing worn yet" : "Nothing saved yet",
                    message: "Generate an outfit, then \(segment == .worn ? "confirm you wore it" : "save it for later")."
                )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(records) { record in
                        OutfitRecordCard(record: record)
                            .contextMenu {
                                Button("Remove", systemImage: "trash", role: .destructive) {
                                    if segment == .worn {
                                        store.removeWorn(record.id)
                                    } else {
                                        store.removeSaved(record.id)
                                    }
                                }
                            }
                    }
                }
            }
        }
    }

    private var records: [OutfitRecord] {
        segment == .worn ? store.wornOutfits : store.savedOutfits
    }
}

private enum ProfileSegment: String, CaseIterable, Identifiable {
    case worn
    case saved
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

private struct ProfileStat: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text("\(value)").font(.title3.weight(.bold))
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileImage: View {
    let data: Data?
    let size: CGFloat

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(ClosetTheme.accent.opacity(0.72))
                    .background(ClosetTheme.accentSoft)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 4))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }
}

private struct ProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ClosetStore
    @State private var draft: UserProfile
    @State private var selectedPhoto: PhotosPickerItem?

    init() {
        _draft = State(initialValue: UserProfile())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        ProfileImage(data: draft.photoData, size: 96)
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Text(draft.photoData == nil ? "Choose profile photo" : "Replace profile photo")
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            guard let newValue else { return }
                            Task {
                                if let data = try? await newValue.loadTransferable(type: Data.self) {
                                    draft.photoData = ImageUtilities.preparedImageData(from: data)
                                }
                            }
                        }
                        if draft.photoData != nil {
                            Button("Remove photo", role: .destructive) { draft.photoData = nil }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("Profile") {
                    TextField("Display name", text: $draft.displayName)
                    TextField("Handle", text: $draft.handle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Bio", text: $draft.bio, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.handle = normalizedHandle
                        store.updateProfile(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(draft.displayName.trimmingCharacters(in: .whitespaces).isEmpty || normalizedHandle.isEmpty)
                }
            }
            .onAppear { draft = store.profile }
        }
    }

    private var normalizedHandle: String {
        draft.handle
            .lowercased()
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
            .prefix(24)
            .description
    }
}

private struct PrototypeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ClosetStore
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Prototype") {
                    LabeledContent("Storage", value: "On this device")
                    LabeledContent("Version", value: "0.1.0")
                    LabeledContent("Account", value: "Local preview")
                }

                Section {
                    Button("Clear all prototype data", role: .destructive) {
                        showingClearConfirmation = true
                    }
                } footer: {
                    Text("Cloud accounts, posting, and syncing are deliberately disabled in this slice. Your closet and photos stay in this app's local container.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .alert("Clear all prototype data?", isPresented: $showingClearConfirmation) {
                Button("Clear", role: .destructive) { store.clearPrototypeData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the local closet, photos, profile, and outfit history. This cannot be undone.")
            }
        }
    }
}
