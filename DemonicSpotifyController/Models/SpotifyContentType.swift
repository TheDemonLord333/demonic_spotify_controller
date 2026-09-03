//
//  SpotifyContentType.swift
//  DemonicSpotifyController
//

import Foundation

/// Von der App unterstützte Spotify-Inhaltstypen. Bewusst auf Playlist und
/// Album beschränkt, wie in den Produktanforderungen festgelegt.
enum SpotifyContentType: String, Codable, CaseIterable, Identifiable {
    case playlist
    case album

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .playlist: return "Playlist"
        case .album: return "Album"
        }
    }

    var sfSymbol: String {
        switch self {
        case .playlist: return "music.note.list"
        case .album: return "square.stack"
        }
    }
}
