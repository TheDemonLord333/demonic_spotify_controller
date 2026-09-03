//
//  AppEnvironment.swift
//  DemonicSpotifyController
//
//  Kompositionswurzel der App: lädt die Spotify-Konfiguration genau
//  einmal beim Start und reicht sie per Dependency Injection an alle
//  Spotify-Dienste weiter. Kann die Konfiguration nicht geladen werden
//  (fehlend/Platzhalter), fällt die App automatisch in einen Demo-Modus
//  mit Mock-Diensten zurück, damit sie im Simulator trotzdem nutzbar ist.
//

import Foundation

@MainActor
final class AppEnvironment {
    let configuration: SpotifyConfiguration?
    let configurationError: SpotifyConfigurationError?
    let isDemoMode: Bool

    let authService: any SpotifyAuthServicing
    let appRemoteService: any SpotifyAppRemoteServicing
    let webAPIService: any SpotifyWebAPIServicing
    let playbackCoordinator: PlaybackCoordinator

    static func bootstrap(configLoader: SpotifyConfigurationLoading = SpotifyConfigurationLoader()) -> AppEnvironment {
        switch configLoader.loadConfiguration() {
        case .success(let configuration):
            return AppEnvironment(configuration: configuration)
        case .failure(let error):
            AppLog.debugOnly(AppLog.config, "Fallback in den Demo-Modus: \(error.localizedDescription)")
            return AppEnvironment(configurationError: error)
        }
    }

    private init(configuration: SpotifyConfiguration) {
        self.configuration = configuration
        self.configurationError = nil
        self.isDemoMode = false

        let auth = SpotifyAuthService(configuration: configuration)
        let remote = SpotifyAppRemoteService(configuration: configuration)
        self.authService = auth
        self.appRemoteService = remote
        self.webAPIService = SpotifyWebAPIService(accessTokenProvider: { [weak auth] in
            guard let auth else { throw DemonicError.spotifyAccountNotConnected }
            return try await auth.validAccessToken()
        })
        self.playbackCoordinator = PlaybackCoordinator(appRemote: remote, authService: auth)
    }

    private init(configurationError: SpotifyConfigurationError) {
        self.configuration = nil
        self.configurationError = configurationError
        self.isDemoMode = true

        let auth = MockSpotifyAuthService()
        let remote = MockSpotifyAppRemoteService()
        self.authService = auth
        self.appRemoteService = remote
        self.webAPIService = MockSpotifyWebAPIService()
        self.playbackCoordinator = PlaybackCoordinator(appRemote: remote, authService: auth)
    }
}
