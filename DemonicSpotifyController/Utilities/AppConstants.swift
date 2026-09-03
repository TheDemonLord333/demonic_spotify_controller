//
//  AppConstants.swift
//  DemonicSpotifyController
//
//  Zentrale, unveränderliche Konstanten der App. Enthält bewusst keine
//  Geheimnisse – Client-ID/Redirect-URI kommen aus der geladenen
//  SpotifyConfiguration, nicht von hier.
//

import Foundation

enum AppConstants {

    /// Nur die tatsächlich benötigten Spotify-Scopes (Prinzip der geringsten Berechtigung).
    static let spotifyScopes: [String] = [
        "app-remote-control",
        "user-read-playback-state",
        "user-modify-playback-state",
        "playlist-read-private",
        "playlist-read-collaborative",
        "user-library-read"
    ]

    static let spotifyAccountsBaseURL = URL(string: "https://accounts.spotify.com")!
    static let spotifyAuthorizePath = "/authorize"
    static let spotifyTokenPath = "/api/token"
    static let spotifyWebAPIBaseURL = URL(string: "https://api.spotify.com/v1")!

    /// URL-Scheme, das Spotify öffnet, ohne die App tatsächlich in den Vordergrund zu holen,
    /// solange App Remote bereits verbunden ist. Wird nur für Diagnose/„In Spotify öffnen“ genutzt.
    static let spotifyAppScheme = "spotify"

    enum KeychainKeys {
        static let accessToken = "spotify.accessToken"
        static let refreshToken = "spotify.refreshToken"
        static let tokenExpiryDate = "spotify.tokenExpiryDate"
        static let scope = "spotify.scope"
    }

    enum UserDefaultsKeys {
        /// Nur unkritische UI-Präferenzen – niemals Tokens.
        static let hasCompletedOnboarding = "demonic.hasCompletedOnboarding"
    }
}
