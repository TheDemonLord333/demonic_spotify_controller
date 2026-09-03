//
//  SavedSpotifyItem.swift
//  DemonicSpotifyController
//
//  SwiftData-Modell für dauerhaft gespeicherte Spotify-Kacheln. Es werden
//  ausschließlich Metadaten gespeichert – niemals Musikdateien.
//

import Foundation
import SwiftData

@Model
final class SavedSpotifyItem {
    /// Lokale, stabile Identität für SwiftUI-Listen/Grids.
    var localID: UUID = UUID()

    /// Spotify-ID des Inhalts (z. B. "37i9dQZF1DXcBWIGoYBM5M").
    var spotifyID: String = ""

    /// Vollständige Spotify-URI (z. B. "spotify:playlist:...").
    var spotifyURI: String = ""

    /// "playlist" oder "album" – als String gespeichert für SwiftData-Kompatibilität,
    /// über `contentType` typsicher zugreifbar.
    var contentTypeRawValue: String = SpotifyContentType.playlist.rawValue

    /// Name, wie von Spotify geliefert.
    var spotifyName: String = ""

    /// Optionaler, lokal vergebener Anzeigename, der `spotifyName` überschreibt.
    var localDisplayName: String?

    /// URL des Spotify-Covers (kann sich ändern, wird beim Laden ggf. aufgefrischt).
    var coverImageURLString: String?

    /// Künstler (Album) bzw. Besitzer (Playlist), rein informativ.
    var artistOrOwner: String?

    /// Anzahl enthaltener Titel, sofern von der Web API geliefert.
    var trackCount: Int?

    var isFavorite: Bool = false

    /// Frei benennbare Kategorie, z. B. "Workout", "Chill". Leer = keine Kategorie.
    var category: String = ""

    /// Position für manuelle Drag-and-drop-Sortierung. Niedrigere Werte zuerst.
    var sortPosition: Int = 0

    var createdAt: Date = Date()

    init(
        spotifyID: String,
        spotifyURI: String,
        contentType: SpotifyContentType,
        spotifyName: String,
        localDisplayName: String? = nil,
        coverImageURLString: String? = nil,
        artistOrOwner: String? = nil,
        trackCount: Int? = nil,
        isFavorite: Bool = false,
        category: String = "",
        sortPosition: Int = 0,
        createdAt: Date = Date()
    ) {
        self.localID = UUID()
        self.spotifyID = spotifyID
        self.spotifyURI = spotifyURI
        self.contentTypeRawValue = contentType.rawValue
        self.spotifyName = spotifyName
        self.localDisplayName = localDisplayName
        self.coverImageURLString = coverImageURLString
        self.artistOrOwner = artistOrOwner
        self.trackCount = trackCount
        self.isFavorite = isFavorite
        self.category = category
        self.sortPosition = sortPosition
        self.createdAt = createdAt
    }

    var contentType: SpotifyContentType {
        get { SpotifyContentType(rawValue: contentTypeRawValue) ?? .playlist }
        set { contentTypeRawValue = newValue.rawValue }
    }

    /// Der Name, der in der UI angezeigt werden soll.
    var displayName: String {
        let trimmed = localDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? spotifyName : trimmed
    }

    var coverImageURL: URL? {
        coverImageURLString.flatMap(URL.init(string:))
    }
}
