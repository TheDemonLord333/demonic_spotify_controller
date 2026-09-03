//
//  SampleData.swift
//  DemonicSpotifyController
//
//  Realistische Beispieldaten für SwiftUI-Previews, den Simulator und die
//  Entwicklung ohne Spotify-Anmeldung. Enthält keine echten Zugangsdaten.
//

import Foundation

enum SampleData {
    static let infernoWorkout = SpotifyContentMetadata(
        spotifyID: "37i9dQZF1DXcBWIGoYBM5M", uri: "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M",
        type: .playlist, name: "Inferno Workout",
        coverImageURLString: "https://i.scdn.co/image/ab67706f00000002b0e5e212f5b9d3b1f5f1a0a1",
        artistOrOwner: "Demonic Spotify Controller", trackCount: 42
    )

    static let hollowThrone = SpotifyContentMetadata(
        spotifyID: "4LH4d3cOWNNsVw41Gqt2kv", uri: "spotify:album:4LH4d3cOWNNsVw41Gqt2kv",
        type: .album, name: "Hollow Throne",
        coverImageURLString: "https://i.scdn.co/image/ab67616d0000b273b1b2c3d4e5f60718293a4b5c",
        artistOrOwner: "Ashen Requiem", trackCount: 11
    )

    static let midnightRitual = SpotifyContentMetadata(
        spotifyID: "3z8h0TU7ReDPLIbEnYhWZb", uri: "spotify:playlist:3z8h0TU7ReDPLIbEnYhWZb",
        type: .playlist, name: "Midnight Ritual",
        coverImageURLString: "https://i.scdn.co/image/ab67706f000000029b0c1d2e3f405162738495a",
        artistOrOwner: "David", trackCount: 28
    )

    static let emberChoir = SpotifyContentMetadata(
        spotifyID: "0sNOF9WDwhWunNAHPD3Baj", uri: "spotify:album:0sNOF9WDwhWunNAHPD3Baj",
        type: .album, name: "Ember Choir",
        coverImageURLString: "https://i.scdn.co/image/ab67616d0000b2739c1d2e3f405162738495b6c",
        artistOrOwner: "Wraithsong", trackCount: 9
    )

    static let allMetadata: [SpotifyContentMetadata] = [infernoWorkout, hollowThrone, midnightRitual, emberChoir]

    static func makeSavedItems() -> [SavedSpotifyItem] {
        allMetadata.enumerated().map { index, metadata in
            SavedSpotifyItem(
                spotifyID: metadata.spotifyID,
                spotifyURI: metadata.uri,
                contentType: metadata.type,
                spotifyName: metadata.name,
                coverImageURLString: metadata.coverImageURLString,
                artistOrOwner: metadata.artistOrOwner,
                trackCount: metadata.trackCount,
                isFavorite: index == 0,
                category: index % 2 == 0 ? "Favoriten" : "",
                sortPosition: index
            )
        }
    }

    static let sampleTrack = SpotifyTrack(
        uri: "spotify:track:2takcwOaAZWiXQijPHIx7B",
        name: "Descent Into Embers",
        artistName: "Wraithsong",
        albumName: "Ember Choir",
        imageURL: URL(string: emberChoir.coverImageURLString ?? ""),
        duration: 245
    )

    static let samplePlaybackState = SpotifyPlaybackState(
        track: sampleTrack, isPaused: false, playbackPosition: 68, isShuffled: false, repeatMode: 0,
        contextURI: emberChoir.uri
    )
}
