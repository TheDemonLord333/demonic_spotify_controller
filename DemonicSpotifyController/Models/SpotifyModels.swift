//
//  SpotifyModels.swift
//  DemonicSpotifyController
//
//  Leichte, transiente Datenstrukturen für Web-API-Ergebnisse und den
//  aktuellen Wiedergabezustand. Keine dieser Strukturen wird direkt
//  persistiert – dafür dient ausschließlich `SavedSpotifyItem`.
//

import Foundation

/// Ergebnis eines Metadaten-Abrufs für einen Spotify-Link/URI, bevor er als
/// Kachel gespeichert wird (Vorschau).
struct SpotifyContentMetadata: Identifiable, Equatable {
    var id: String { spotifyID }
    let spotifyID: String
    let uri: String
    let type: SpotifyContentType
    let name: String
    let coverImageURLString: String?
    /// Künstler bei Album, Besitzer bei Playlist.
    let artistOrOwner: String?
    let trackCount: Int?

    var coverImageURL: URL? { coverImageURLString.flatMap(URL.init(string:)) }
}

/// Ergebnis einer Playlist-/Album-Suche.
struct SpotifySearchResultItem: Identifiable, Equatable {
    var id: String { spotifyID }
    let spotifyID: String
    let uri: String
    let type: SpotifyContentType
    let name: String
    let coverImageURLString: String?
    let artistOrOwner: String?

    var coverImageURL: URL? { coverImageURLString.flatMap(URL.init(string:)) }
}

/// Aktuell wiedergegebener Titel, wie von App Remote gemeldet.
struct SpotifyTrack: Identifiable, Equatable {
    var id: String { uri }
    let uri: String
    let name: String
    let artistName: String
    let albumName: String
    let imageURL: URL?
    let duration: TimeInterval
}

/// Vollständiger Player-Zustand, wie ihn App Remote liefert.
struct SpotifyPlaybackState: Equatable {
    let track: SpotifyTrack?
    let isPaused: Bool
    let playbackPosition: TimeInterval
    let isShuffled: Bool
    /// 0 = aus, 1 = Kontext (Playlist/Album), 2 = einzelner Titel.
    let repeatMode: Int
    /// Die Spotify-URI der Playlist/des Albums, aus dem aktuell wiedergegeben wird, falls bekannt.
    let contextURI: String?

    static let idle = SpotifyPlaybackState(
        track: nil, isPaused: true, playbackPosition: 0, isShuffled: false, repeatMode: 0, contextURI: nil
    )
}
