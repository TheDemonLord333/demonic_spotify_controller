//
//  SpotifyConfiguration.swift
//  DemonicSpotifyController
//
//  Codable-Modell der öffentlichen Spotify-Konfiguration. Enthält bewusst
//  KEIN Client Secret – die App verwendet Authorization Code mit PKCE,
//  wofür kein Secret benötigt wird (siehe SETUP.md).
//

import Foundation

struct SpotifyConfiguration: Codable, Equatable {
    let clientId: String
    let redirectUri: String

    /// Werte, die auf eine nicht ausgefüllte Beispieldatei hindeuten.
    static let placeholderValues: Set<String> = [
        "DEINE_SPOTIFY_CLIENT_ID",
        "YOUR_SPOTIFY_CLIENT_ID",
        ""
    ]

    var redirectURL: URL? { URL(string: redirectUri) }

    var containsPlaceholderValues: Bool {
        Self.placeholderValues.contains(clientId) || clientId.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
