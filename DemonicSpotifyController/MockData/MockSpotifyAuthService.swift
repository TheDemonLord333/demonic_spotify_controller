//
//  MockSpotifyAuthService.swift
//  DemonicSpotifyController
//
//  Mock der Anmeldung für Previews, Simulator und Unit Tests – erlaubt
//  Entwicklung/UI-Erkundung ohne echtes Spotify-Konto.
//

import Foundation
import Observation

@MainActor
@Observable
final class MockSpotifyAuthService: SpotifyAuthServicing {
    var state: SpotifyAuthState = .signedIn
    var beginAuthorizationCallCount = 0

    func restoreSession() async {}

    func beginAuthorization() async throws {
        beginAuthorizationCallCount += 1
        state = .signedIn
    }

    func validAccessToken() async throws -> String {
        guard state == .signedIn else { throw DemonicError.spotifyAccountNotConnected }
        return "mock-access-token"
    }

    func logout() {
        state = .signedOut
    }
}
