//
//  PlaybackCoordinator.swift
//  DemonicSpotifyController
//
//  Koordiniert Wiedergabewünsche zwischen UI, SpotifyAppRemoteService und
//  SpotifyAuthService. Verhindert doppelte Wiedergabebefehle durch
//  schnelles Mehrfachtippen und entscheidet, ob ein Inhalt direkt über
//  App Remote abgespielt werden kann oder ob zunächst der offizielle
//  Spotify-Hand-off (`authorizeAndPlayURI`) nötig ist.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PlaybackCoordinator {

    private let appRemote: SpotifyAppRemoteServicing
    private let authService: SpotifyAuthServicing

    /// URI, die gerade einen Wiedergabebefehl verarbeitet (für Ladezustand in der UI).
    private(set) var currentlyLoadingURI: String?
    private(set) var lastError: DemonicError?
    private(set) var lastSuccessfulURI: String?

    /// Schützt vor Mehrfachbefehlen, wenn eine Kachel sehr schnell mehrfach getippt wird.
    private var inFlightURIs: Set<String> = []

    var connectionStatus: AppRemoteConnectionStatus { appRemote.connectionStatus }
    var playbackState: SpotifyPlaybackState { appRemote.playbackState }
    var nowPlayingArtwork: UIImage? { appRemote.nowPlayingArtwork }

    init(appRemote: SpotifyAppRemoteServicing, authService: SpotifyAuthServicing) {
        self.appRemote = appRemote
        self.authService = authService
    }

    /// Wird von einer Kachel beim Antippen aufgerufen. Spielt sofort über App
    /// Remote ab, wenn bereits verbunden; andernfalls wird der offizielle
    /// Spotify-Hand-off ausgelöst (kurzer, erklärter App-Wechsel).
    func requestPlayback(uri: String) async {
        guard !inFlightURIs.contains(uri) else { return }
        inFlightURIs.insert(uri)
        currentlyLoadingURI = uri
        lastError = nil
        defer {
            inFlightURIs.remove(uri)
            if currentlyLoadingURI == uri { currentlyLoadingURI = nil }
        }

        guard appRemote.isSpotifyInstalled else {
            lastError = .spotifyAppNotInstalled
            return
        }

        guard authService.state == .signedIn else {
            lastError = .spotifyAccountNotConnected
            return
        }

        if appRemote.connectionStatus.isConnected {
            do {
                try await appRemote.play(uri: uri)
                lastSuccessfulURI = uri
            } catch let error as DemonicError {
                lastError = error
            } catch {
                lastError = .playbackFailed(nil)
            }
            return
        }

        // App Remote ist (noch) nicht verbunden: offizieller, App-Store-konformer
        // Hand-off. `authorizeAndPlayURI` autorisiert App Remote bei Bedarf und
        // startet den gewählten Inhalt bereits Spotify-seitig, bevor automatisch
        // über die Redirect-URI zu dieser App zurückgeleitet wird. Aus diesem
        // Grund wird hier absichtlich KEIN zusätzlicher `play(uri:)`-Befehl mehr
        // abgesetzt – das würde einen doppelten Wiedergabebefehl bedeuten.
        lastError = .appSwitchRequired
        appRemote.authorizeAndPlay(uri: uri)
    }

    /// Deep-Link, der Spotify sichtbar öffnet. Ausschließlich für die
    /// ausdrücklich beschriftete Funktion "In Spotify öffnen" gedacht –
    /// niemals für den normalen Tippen-zum-Abspielen-Pfad.
    func openInSpotify(uri: String) {
        guard let url = URL(string: uri) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Lifecycle-Hooks

    /// Beim Aktivwerden der App: versucht, still (ohne Spotify zu öffnen)
    /// wieder mit App Remote zu verbinden, falls zuvor schon einmal autorisiert.
    func handleSceneBecameActive() {
        appRemote.reconnectSilently()
    }

    /// Callback aus `onOpenURL`. Reicht die URL an App Remote weiter.
    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        appRemote.handleOpenURL(url)
    }

    /// Erlaubt der UI, eine angezeigte Fehlermeldung zu quittieren.
    func clearError() {
        lastError = nil
    }

    // MARK: - Player-Steuerung

    func togglePlayPause() async {
        do {
            if playbackState.isPaused {
                try await appRemote.resume()
            } else {
                try await appRemote.pause()
            }
        } catch let error as DemonicError {
            lastError = error
        } catch {
            lastError = .playbackFailed(nil)
        }
    }

    func skipToNext() async {
        await runControl { try await appRemote.skipToNext() }
    }

    func skipToPrevious() async {
        await runControl { try await appRemote.skipToPrevious() }
    }

    func toggleShuffle() async {
        await runControl { try await appRemote.setShuffle(!playbackState.isShuffled) }
    }

    func cycleRepeatMode() async {
        let next = (playbackState.repeatMode + 1) % 3
        await runControl { try await appRemote.setRepeatMode(next) }
    }

    private func runControl(_ operation: () async throws -> Void) async {
        do {
            try await operation()
        } catch let error as DemonicError {
            lastError = error
        } catch {
            lastError = .playbackFailed(nil)
        }
    }
}
