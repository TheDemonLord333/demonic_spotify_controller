//
//  AddSpotifyItemView.swift
//  DemonicSpotifyController
//
//  Dialog zum Hinzufügen einer Playlist/eines Albums: Link/URI einfügen,
//  nach Inhalten suchen oder aus den eigenen Playlists wählen. Zeigt vor
//  dem Speichern stets eine Vorschau der Kachel.
//

import SwiftUI

struct AddSpotifyItemView: View {
    @State private var viewModel: AddSpotifyItemViewModel
    let onSave: (SpotifyContentMetadata, String?, String) -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Mode: String, CaseIterable, Identifiable {
        case link = "Link/URI"
        case search = "Suchen"
        case ownPlaylists = "Meine Playlists"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .link
    @State private var localDisplayName: String = ""
    @State private var category: String = ""

    init(viewModel: AddSpotifyItemViewModel, onSave: @escaping (SpotifyContentMetadata, String?, String) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        Picker("Modus", selection: $mode) {
                            ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        switch mode {
                        case .link: linkSection
                        case .search: searchSection
                        case .ownPlaylists: ownPlaylistsSection
                        }

                        if let metadata = viewModel.previewMetadata {
                            previewCard(metadata: metadata)
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Inhalt hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .disabled(viewModel.previewMetadata == nil)
                }
            }
        }
        .task(id: mode) {
            if mode == .ownPlaylists { await viewModel.loadOwnPlaylists() }
        }
    }

    // MARK: - Link/URI

    private var linkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Spotify-Link oder -URI")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DemonicPalette.textSecondary)
            TextField("https://open.spotify.com/playlist/... oder spotify:album:...", text: $viewModel.linkInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(10)
                .background(DemonicPalette.smokeGlass, in: RoundedRectangle(cornerRadius: DemonicTheme.controlCornerRadius))
                .foregroundStyle(DemonicPalette.textPrimary)

            Button {
                Task { await viewModel.fetchPreview() }
            } label: {
                if viewModel.isLoadingPreview {
                    ProgressView().tint(.white)
                } else {
                    Text("Vorschau laden")
                }
            }
            .buttonStyle(DemonicPrimaryButtonStyle())
            .disabled(viewModel.linkInput.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoadingPreview)

            if let error = viewModel.previewErrorMessage {
                Text(error).font(.caption).foregroundStyle(DemonicPalette.glowingScarlet)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Suche

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Typ", selection: $viewModel.searchType) {
                Text("Playlists").tag(SpotifyContentType.playlist)
                Text("Alben").tag(SpotifyContentType.album)
            }
            .pickerStyle(.segmented)

            HStack {
                TextField("Suchbegriff", text: $viewModel.searchQuery)
                    .textInputAutocapitalization(.never)
                    .padding(10)
                    .background(DemonicPalette.smokeGlass, in: RoundedRectangle(cornerRadius: DemonicTheme.controlCornerRadius))
                    .foregroundStyle(DemonicPalette.textPrimary)
                    .onSubmit { Task { await viewModel.search() } }

                Button {
                    Task { await viewModel.search() }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .buttonStyle(DemonicIconButtonStyle())
            }

            if viewModel.isSearching {
                ProgressView().tint(DemonicPalette.glowingScarlet)
            } else if let error = viewModel.searchErrorMessage {
                Text(error).font(.caption).foregroundStyle(DemonicPalette.glowingScarlet)
            } else {
                searchResultsList(viewModel.searchResults)
            }
        }
        .padding(.horizontal)
    }

    private var ownPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.isLoadingOwnPlaylists {
                ProgressView().tint(DemonicPalette.glowingScarlet)
            } else if let error = viewModel.ownPlaylistsErrorMessage {
                Text(error).font(.caption).foregroundStyle(DemonicPalette.glowingScarlet)
            } else {
                searchResultsList(viewModel.ownPlaylists)
            }
        }
        .padding(.horizontal)
    }

    private func searchResultsList(_ results: [SpotifySearchResultItem]) -> some View {
        VStack(spacing: 8) {
            ForEach(results) { result in
                Button {
                    viewModel.selectSearchResult(result)
                } label: {
                    HStack(spacing: 10) {
                        CoverImageView(url: result.coverImageURL, cornerRadius: 6)
                            .frame(width: 44, height: 44)
                        VStack(alignment: .leading) {
                            Text(result.name).font(.subheadline.weight(.medium)).lineLimit(1)
                            if let subtitle = result.artistOrOwner {
                                Text(subtitle).font(.caption).foregroundStyle(DemonicPalette.textSecondary).lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .foregroundStyle(DemonicPalette.textPrimary)
                    .padding(8)
                    .background(DemonicPalette.smokeGlass, in: RoundedRectangle(cornerRadius: DemonicTheme.controlCornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Vorschau + Speichern

    private func previewCard(metadata: SpotifyContentMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CoverImageView(url: metadata.coverImageURL, cornerRadius: 10)
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 3) {
                    Text(metadata.name).font(.headline).foregroundStyle(DemonicPalette.textPrimary)
                    Text(metadata.type.displayName).font(.caption).foregroundStyle(DemonicPalette.textSecondary)
                    if let subtitle = metadata.artistOrOwner {
                        Text(subtitle).font(.caption).foregroundStyle(DemonicPalette.textTertiary)
                    }
                    if let count = metadata.trackCount {
                        Text("\(count) Titel").font(.caption2).foregroundStyle(DemonicPalette.textTertiary)
                    }
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Lokaler Anzeigename (optional)").font(.caption).foregroundStyle(DemonicPalette.textSecondary)
                TextField(metadata.name, text: $localDisplayName)
                    .padding(8)
                    .background(DemonicPalette.smokeGlass, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(DemonicPalette.textPrimary)

                Text("Kategorie (optional)").font(.caption).foregroundStyle(DemonicPalette.textSecondary)
                TextField("z. B. Workout", text: $category)
                    .padding(8)
                    .background(DemonicPalette.smokeGlass, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(DemonicPalette.textPrimary)
            }
        }
        .padding(16)
        .demonicCardBackground()
        .padding(.horizontal)
    }

    private func save() {
        guard let metadata = viewModel.previewMetadata else { return }
        onSave(metadata, localDisplayName, category)
        dismiss()
    }
}
