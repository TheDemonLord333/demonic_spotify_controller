//
//  MockSpotifyWebAPIService.swift
//  DemonicSpotifyController
//
//  Mock der Web-API für Previews, Simulator und Entwicklung ohne
//  Spotify-Anmeldung.
//

import Foundation

final class MockSpotifyWebAPIService: SpotifyWebAPIServicing {
    var shouldFail = false

    func fetchMetadata(for reference: ParsedSpotifyReference) async throws -> SpotifyContentMetadata {
        try await Task.sleep(nanoseconds: 300_000_000)
        if shouldFail { throw DemonicError.contentNotFound }
        if let match = SampleData.allMetadata.first(where: { $0.spotifyID == reference.id }) {
            return match
        }
        return SpotifyContentMetadata(
            spotifyID: reference.id, uri: reference.uri, type: reference.type,
            name: reference.type == .playlist ? "Vorschau-Playlist" : "Vorschau-Album",
            coverImageURLString: SampleData.infernoWorkout.coverImageURLString,
            artistOrOwner: "Unbekannt", trackCount: 12
        )
    }

    func searchPlaylists(query: String) async throws -> [SpotifySearchResultItem] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return SampleData.allMetadata.filter { $0.type == .playlist }.map(Self.asSearchResult)
    }

    func searchAlbums(query: String) async throws -> [SpotifySearchResultItem] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return SampleData.allMetadata.filter { $0.type == .album }.map(Self.asSearchResult)
    }

    func fetchCurrentUserPlaylists() async throws -> [SpotifySearchResultItem] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return SampleData.allMetadata.filter { $0.type == .playlist }.map(Self.asSearchResult)
    }

    private static func asSearchResult(_ metadata: SpotifyContentMetadata) -> SpotifySearchResultItem {
        SpotifySearchResultItem(
            spotifyID: metadata.spotifyID, uri: metadata.uri, type: metadata.type, name: metadata.name,
            coverImageURLString: metadata.coverImageURLString, artistOrOwner: metadata.artistOrOwner
        )
    }
}
