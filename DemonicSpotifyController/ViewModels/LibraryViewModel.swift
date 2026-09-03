//
//  LibraryViewModel.swift
//  DemonicSpotifyController
//
//  Verwaltet Filter-/Suchzustand der Kachelübersicht sowie alle
//  Mutationen auf `SavedSpotifyItem` über SwiftData. Die eigentliche,
//  live aktualisierte Liste wird von der View per `@Query` geladen und
//  hier lediglich gefiltert/sortiert/mutiert.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class LibraryViewModel {
    private let modelContext: ModelContext
    let playbackCoordinator: PlaybackCoordinator

    var searchText: String = ""
    var filterType: SpotifyContentType?
    var showFavoritesOnly: Bool = false
    var selectedCategory: String?

    private(set) var actionErrorMessage: String?

    init(modelContext: ModelContext, playbackCoordinator: PlaybackCoordinator) {
        self.modelContext = modelContext
        self.playbackCoordinator = playbackCoordinator
    }

    func filteredAndSorted(_ items: [SavedSpotifyItem]) -> [SavedSpotifyItem] {
        items
            .filter { showFavoritesOnly ? $0.isFavorite : true }
            .filter { filterType == nil || $0.contentType == filterType }
            .filter { selectedCategory == nil || selectedCategory == "" || $0.category == selectedCategory }
            .filter { searchText.isEmpty || $0.displayName.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.sortPosition < $1.sortPosition }
    }

    func availableCategories(in items: [SavedSpotifyItem]) -> [String] {
        Array(Set(items.map(\.category).filter { !$0.isEmpty })).sorted()
    }

    func addItem(from metadata: SpotifyContentMetadata, localDisplayName: String?, category: String) {
        let existingPositions = (try? modelContext.fetch(FetchDescriptor<SavedSpotifyItem>()))?.map(\.sortPosition) ?? []
        let nextPosition = (existingPositions.max() ?? -1) + 1
        let trimmedName = localDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = SavedSpotifyItem(
            spotifyID: metadata.spotifyID,
            spotifyURI: metadata.uri,
            contentType: metadata.type,
            spotifyName: metadata.name,
            localDisplayName: (trimmedName?.isEmpty ?? true) ? nil : trimmedName,
            coverImageURLString: metadata.coverImageURLString,
            artistOrOwner: metadata.artistOrOwner,
            trackCount: metadata.trackCount,
            category: category,
            sortPosition: nextPosition
        )
        modelContext.insert(item)
        save()
    }

    func remove(_ item: SavedSpotifyItem) {
        modelContext.delete(item)
        save()
    }

    func toggleFavorite(_ item: SavedSpotifyItem) {
        item.isFavorite.toggle()
        save()
    }

    func updateDisplayName(_ item: SavedSpotifyItem, displayName: String, category: String) {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        item.localDisplayName = trimmed.isEmpty ? nil : trimmed
        item.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    /// Sortiert die übergebene (bereits gefilterte) Liste anhand einer
    /// Drag-and-drop-Verschiebung neu und schreibt die Positionen fort.
    func move(_ visibleItems: [SavedSpotifyItem], fromOffsets: IndexSet, toOffset: Int) {
        var reordered = visibleItems
        reordered.move(fromOffsets: fromOffsets, toOffset: toOffset)
        for (index, item) in reordered.enumerated() {
            item.sortPosition = index
        }
        save()
    }

    func play(_ item: SavedSpotifyItem) async {
        await playbackCoordinator.requestPlayback(uri: item.spotifyURI)
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            actionErrorMessage = DemonicError.unknown("Speichern fehlgeschlagen").localizedDescription
            AppLog.debugOnly(AppLog.persistence, "SwiftData-Speicherfehler: \(error)")
        }
    }
}
