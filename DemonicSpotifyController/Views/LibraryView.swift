//
//  LibraryView.swift
//  DemonicSpotifyController
//
//  Hauptbildschirm mit der Kachelübersicht. Adaptives Layout: im breiten
//  Querformat teilen sich Kacheln und ein großer Now-Playing-Bereich die
//  Fläche, sonst erscheint ein kompakter Player am unteren Rand.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    let viewModel: LibraryViewModel
    let environment: AppEnvironment

    @Query(sort: \SavedSpotifyItem.sortPosition) private var items: [SavedSpotifyItem]

    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var editingItem: SavedSpotifyItem?
    @State private var itemPendingRemoval: SavedSpotifyItem?

    var body: some View {
        GeometryReader { proxy in
            let isWideLandscape = proxy.size.width > proxy.size.height && proxy.size.width > 700

            Group {
                if isWideLandscape {
                    HStack(spacing: 0) {
                        mainColumn
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(DemonicPalette.glowingScarlet.opacity(0.15))
                            .frame(width: 1)
                        ScrollView {
                            NowPlayingBar(coordinator: environment.playbackCoordinator, isExpanded: true)
                        }
                        .frame(width: min(380, proxy.size.width * 0.36))
                    }
                } else {
                    VStack(spacing: 0) {
                        mainColumn
                        NowPlayingBar(coordinator: environment.playbackCoordinator, isExpanded: false)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddSpotifyItemView(viewModel: AddSpotifyItemViewModel(webAPI: environment.webAPIService)) { metadata, name, category in
                viewModel.addItem(from: metadata, localDisplayName: name, category: category)
            }
        }
        .sheet(item: $editingItem) { item in
            TileEditView(item: item) { newName, category in
                viewModel.updateDisplayName(item, displayName: newName, category: category)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(environment: environment)
        }
        .confirmationDialog(
            "Diesen Inhalt entfernen?",
            isPresented: Binding(get: { itemPendingRemoval != nil }, set: { if !$0 { itemPendingRemoval = nil } }),
            titleVisibility: .visible
        ) {
            Button("Entfernen", role: .destructive) {
                if let item = itemPendingRemoval { viewModel.remove(item) }
                itemPendingRemoval = nil
            }
            Button("Abbrechen", role: .cancel) { itemPendingRemoval = nil }
        }
        .alert(item: errorBinding) { error in
            Alert(title: Text("Fehler"), message: Text(error.errorDescription ?? ""), dismissButton: .default(Text("OK")))
        }
    }

    private var errorBinding: Binding<DemonicError?> {
        Binding(
            get: { environment.playbackCoordinator.lastError },
            set: { newValue in if newValue == nil { environment.playbackCoordinator.clearError() } }
        )
    }

    private var visibleItems: [SavedSpotifyItem] {
        viewModel.filteredAndSorted(items)
    }

    private var mainColumn: some View {
        VStack(spacing: 0) {
            header
            filterBar
            if visibleItems.isEmpty {
                emptyState
            } else {
                AdaptiveTileGrid(items: visibleItems) { item in
                    SpotifyItemTile(
                        item: item,
                        isPlaying: environment.playbackCoordinator.playbackState.contextURI == item.spotifyURI,
                        isLoading: environment.playbackCoordinator.currentlyLoadingURI == item.spotifyURI,
                        onTap: { Task { await viewModel.play(item) } },
                        onOpenInSpotify: { environment.playbackCoordinator.openInSpotify(uri: item.spotifyURI) },
                        onToggleFavorite: { viewModel.toggleFavorite(item) },
                        onEdit: { editingItem = item },
                        onRemove: { itemPendingRemoval = item }
                    )
                }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Demonic Spotify Controller")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DemonicPalette.textPrimary)
                if environment.isDemoMode {
                    Text("Demo-Modus – Beispieldaten")
                        .font(.caption2)
                        .foregroundStyle(DemonicPalette.emberOrange)
                }
            }
            Spacer()
            ConnectionStatusView(status: environment.playbackCoordinator.connectionStatus)
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
            }
            .buttonStyle(DemonicIconButtonStyle(size: 40))
            DemonicPlusButton { showingAdd = true }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(DemonicPalette.textTertiary)
                TextField("Kacheln durchsuchen", text: Binding(get: { viewModel.searchText }, set: { viewModel.searchText = $0 }))
                    .foregroundStyle(DemonicPalette.textPrimary)
                    .textInputAutocapitalization(.never)
                if !viewModel.searchText.isEmpty {
                    Button { viewModel.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(DemonicPalette.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(DemonicPalette.smokeGlass, in: Capsule())

            HStack(spacing: 10) {
                filterChip(title: "Alle", isSelected: viewModel.filterType == nil) { viewModel.filterType = nil }
                filterChip(title: "Playlists", isSelected: viewModel.filterType == .playlist) { viewModel.filterType = .playlist }
                filterChip(title: "Alben", isSelected: viewModel.filterType == .album) { viewModel.filterType = .album }
                filterChip(title: "Favoriten", isSelected: viewModel.showFavoritesOnly, icon: "flame.fill") {
                    viewModel.showFavoritesOnly.toggle()
                }
                Spacer()
            }
            .scrollableIfNeeded()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private func filterChip(title: String, isSelected: Bool, icon: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption2) }
                Text(title).font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? DemonicPalette.glowGradient : LinearGradient(colors: [DemonicPalette.smokeGlass], startPoint: .top, endPoint: .bottom))
            .foregroundStyle(DemonicPalette.textPrimary)
            .clipShape(Capsule())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundStyle(DemonicPalette.textTertiary)
            Text(items.isEmpty ? "Noch keine Inhalte gespeichert" : "Keine Treffer")
                .font(.headline)
                .foregroundStyle(DemonicPalette.textSecondary)
            if items.isEmpty {
                Text("Tippe auf das Plus, um deine erste Playlist oder dein erstes Album hinzuzufügen.")
                    .font(.caption)
                    .foregroundStyle(DemonicPalette.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
    }
}

private extension View {
    @ViewBuilder
    func scrollableIfNeeded() -> some View {
        ScrollView(.horizontal, showsIndicators: false) { self }
    }
}
