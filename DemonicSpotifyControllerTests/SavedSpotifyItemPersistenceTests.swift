//
//  SavedSpotifyItemPersistenceTests.swift
//  DemonicSpotifyControllerTests
//

import Testing
import SwiftData
import Foundation
@testable import DemonicSpotifyController

@MainActor
struct SavedSpotifyItemPersistenceTests {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([SavedSpotifyItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    @Test func savesAndFetchesItem() throws {
        let context = try makeInMemoryContext()
        let item = SavedSpotifyItem(
            spotifyID: "abc", spotifyURI: "spotify:playlist:abc", contentType: .playlist,
            spotifyName: "Inferno Workout"
        )
        context.insert(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedSpotifyItem>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.displayName == "Inferno Workout")
    }

    @Test func localDisplayNameOverridesSpotifyName() {
        let item = SavedSpotifyItem(
            spotifyID: "abc", spotifyURI: "spotify:playlist:abc", contentType: .playlist,
            spotifyName: "Inferno Workout", localDisplayName: "Mein Workout"
        )
        #expect(item.displayName == "Mein Workout")
    }

    @Test func sortPositionOrdersItems() throws {
        let context = try makeInMemoryContext()
        let first = SavedSpotifyItem(spotifyID: "a", spotifyURI: "spotify:album:a", contentType: .album, spotifyName: "A", sortPosition: 1)
        let second = SavedSpotifyItem(spotifyID: "b", spotifyURI: "spotify:album:b", contentType: .album, spotifyName: "B", sortPosition: 0)
        context.insert(first)
        context.insert(second)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedSpotifyItem>(sortBy: [SortDescriptor(\.sortPosition)]))
        #expect(fetched.map(\.spotifyName) == ["B", "A"])
    }

    @Test func removingItemDeletesFromStore() throws {
        let context = try makeInMemoryContext()
        let item = SavedSpotifyItem(spotifyID: "abc", spotifyURI: "spotify:album:abc", contentType: .album, spotifyName: "Hollow Throne")
        context.insert(item)
        try context.save()

        context.delete(item)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedSpotifyItem>())
        #expect(fetched.isEmpty)
    }

    @Test func toggleFavoritePersists() throws {
        let context = try makeInMemoryContext()
        let item = SavedSpotifyItem(spotifyID: "abc", spotifyURI: "spotify:album:abc", contentType: .album, spotifyName: "Ember Choir")
        context.insert(item)
        try context.save()

        item.isFavorite = true
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<SavedSpotifyItem>())
        #expect(fetched.first?.isFavorite == true)
    }
}
