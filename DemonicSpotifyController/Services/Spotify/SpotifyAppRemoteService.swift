//
//  SpotifyAppRemoteService.swift
//  DemonicSpotifyController
//
//  Steuert ausschließlich die lokal installierte Spotify-App über das
//  offizielle Spotify iOS SDK (App Remote). Lädt und streamt selbst
//  niemals Musik – die Wiedergabe findet immer in Spotify statt.
//
//  Die SpotifyiOS-Abhängigkeit wird per Swift Package Manager eingebunden
//  (siehe SETUP.md). Damit das Projekt auch dann kompiliert, wenn das
//  Paket in einer Build-Umgebung ohne Netzwerkzugriff auf GitHub noch
//  nicht aufgelöst werden konnte (z. B. reiner Simulator-/Mock-Betrieb),
//  ist die eigentliche SDK-Nutzung hinter `#if canImport(SpotifyiOS)`
//  gekapselt. Auf einem echten iPhone mit aufgelöstem Paket ist dieser
//  Zweig aktiv und verwendet die echten, dokumentierten SDK-Methoden.
//

import Foundation
import Observation
import UIKit

#if canImport(SpotifyiOS)
import SpotifyiOS
#endif

@MainActor
protocol SpotifyAppRemoteServicing: AnyObject {
    var connectionStatus: AppRemoteConnectionStatus { get }
    var playbackState: SpotifyPlaybackState { get }
    var nowPlayingArtwork: UIImage? { get }
    var isSpotifyInstalled: Bool { get }

    func connect(accessToken: String)
    /// Versucht, ohne Spotify sichtbar zu öffnen, erneut mit dem zuletzt
    /// bekannten App-Remote-Token zu verbinden (z. B. wenn die App wieder
    /// aktiv wird). Tut nichts, wenn kein Token bekannt ist oder bereits
    /// verbunden ist.
    func reconnectSilently()
    func disconnect()
    /// Öffnet Spotify offiziell, um App Remote zu autorisieren und optional
    /// direkt eine URI wiederzugeben. Nur zulässig, wenn App Remote noch
    /// nicht verbunden ist bzw. eine (Re-)Autorisierung nötig ist.
    func authorizeAndPlay(uri: String)
    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool

    func play(uri: String) async throws
    func pause() async throws
    func resume() async throws
    func skipToNext() async throws
    func skipToPrevious() async throws
    func setShuffle(_ enabled: Bool) async throws
    func setRepeatMode(_ mode: Int) async throws
}

@MainActor
@Observable
final class SpotifyAppRemoteService: NSObject, SpotifyAppRemoteServicing {

    private(set) var connectionStatus: AppRemoteConnectionStatus = .disconnected
    private(set) var playbackState: SpotifyPlaybackState = .idle
    private(set) var nowPlayingArtwork: UIImage?

    private let configuration: SpotifyConfiguration
    private var lastKnownAccessToken: String?

    #if canImport(SpotifyiOS)
    // `@Observable` synthesizes init accessors for stored properties, die
    // sich für `lazy var` nicht generieren lassen. Diese beiden Properties
    // sind reine Implementierungsdetails (keine UI-Zustände) und werden
    // daher bewusst von der Beobachtung ausgenommen.
    @ObservationIgnored
    private lazy var sptConfiguration: SPTConfiguration = SPTConfiguration(
        clientID: configuration.clientId,
        redirectURL: configuration.redirectURL ?? URL(string: "https://invalid.example")!
    )
    @ObservationIgnored
    private lazy var appRemote: SPTAppRemote = {
        let remote = SPTAppRemote(configuration: sptConfiguration, logLevel: .info)
        remote.delegate = self
        return remote
    }()
    #endif

    init(configuration: SpotifyConfiguration) {
        self.configuration = configuration
        super.init()
    }

    var isSpotifyInstalled: Bool {
        guard let url = URL(string: "\(AppConstants.spotifyAppScheme):") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func connect(accessToken: String) {
        guard isSpotifyInstalled else {
            connectionStatus = .failed(.spotifyAppNotInstalled)
            return
        }
        lastKnownAccessToken = accessToken
        #if canImport(SpotifyiOS)
        connectionStatus = .connecting
        appRemote.connectionParameters.accessToken = accessToken
        appRemote.connect()
        #else
        connectionStatus = .failed(.unknown("Spotify iOS SDK ist in dieser Build-Umgebung nicht aufgelöst."))
        #endif
    }

    func reconnectSilently() {
        guard !connectionStatus.isConnected, let token = lastKnownAccessToken, isSpotifyInstalled else { return }
        connect(accessToken: token)
    }

    func disconnect() {
        #if canImport(SpotifyiOS)
        appRemote.disconnect()
        #endif
        connectionStatus = .disconnected
        playbackState = .idle
    }

    func authorizeAndPlay(uri: String) {
        guard isSpotifyInstalled else {
            connectionStatus = .failed(.spotifyAppNotInstalled)
            return
        }
        #if canImport(SpotifyiOS)
        connectionStatus = .connecting
        appRemote.authorizeAndPlayURI(uri, completionHandler: { [weak self] success in
            guard let self, !success else { return }
            // `success` ist lediglich, ob Spotify installiert ist und die Anfrage
            // entgegennehmen konnte – nicht, ob die Autorisierung selbst gelang.
            self.connectionStatus = .failed(.spotifyAppNotInstalled)
        })
        #else
        connectionStatus = .failed(.unknown("Spotify iOS SDK ist in dieser Build-Umgebung nicht aufgelöst."))
        #endif
    }

    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool {
        #if canImport(SpotifyiOS)
        guard let parameters = appRemote.authorizationParameters(from: url) else { return false }
        if let accessToken = parameters[SPTAppRemoteAccessTokenKey] {
            lastKnownAccessToken = accessToken
            appRemote.connectionParameters.accessToken = accessToken
            connectionStatus = .connecting
            appRemote.connect()
            return true
        }
        if let errorDescription = parameters[SPTAppRemoteErrorDescriptionKey] {
            AppLog.debugOnly(AppLog.appRemote, "App-Remote-Autorisierung fehlgeschlagen: \(errorDescription)")
            connectionStatus = .failed(.authorizationDenied)
            return true
        }
        return false
        #else
        return false
        #endif
    }

    // MARK: - Player-Steuerung

    func play(uri: String) async throws {
        #if canImport(SpotifyiOS)
        try await runPlayerCall { api, callback in api.play(uri, callback: callback) }
        #else
        throw DemonicError.appRemoteNotConnected
        #endif
    }

    func pause() async throws {
        #if canImport(SpotifyiOS)
        try await runPlayerCall { api, callback in api.pause(callback) }
        #else
        throw DemonicError.appRemoteNotConnected
        #endif
    }

    func resume() async throws {
        #if canImport(SpotifyiOS)
        try await runPlayerCall { api, callback in api.resume(callback) }
        #else
        throw DemonicError.appRemoteNotConnected
        #endif
    }

    func skipToNext() async throws {
        #if canImport(SpotifyiOS)
        try await runPlayerCall { api, callback in api.skip(toNext: callback) }
        #else
        throw DemonicError.appRemoteNotConnected
        #endif
    }

    func skipToPrevious() async throws {
        #if canImport(SpotifyiOS)
        try await runPlayerCall { api, callback in api.skip(toPrevious: callback) }
        #else
        throw DemonicError.appRemoteNotConnected
        #endif
    }

    func setShuffle(_ enabled: Bool) async throws {
        #if canImport(SpotifyiOS)
        try await runPlayerCall { api, callback in api.setShuffle(enabled, callback: callback) }
        #else
        throw DemonicError.appRemoteNotConnected
        #endif
    }

    func setRepeatMode(_ mode: Int) async throws {
        #if canImport(SpotifyiOS)
        guard let repeatMode = SPTAppRemotePlaybackOptionsRepeatMode(rawValue: UInt(mode)) else { return }
        try await runPlayerCall { api, callback in api.setRepeatMode(repeatMode, callback: callback) }
        #else
        throw DemonicError.appRemoteNotConnected
        #endif
    }

    #if canImport(SpotifyiOS)
    private func runPlayerCall(
        _ operation: @escaping (SPTAppRemotePlayerAPI, @escaping SPTAppRemoteCallback) -> Void
    ) async throws {
        guard connectionStatus.isConnected, let playerAPI = appRemote.playerAPI else {
            throw DemonicError.appRemoteNotConnected
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation(playerAPI) { _, error in
                if let error {
                    continuation.resume(throwing: DemonicError.playbackFailed(String(describing: error)))
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    #endif
}

#if canImport(SpotifyiOS)
extension SpotifyAppRemoteService: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        connectionStatus = .connected
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { [weak self] _, error in
            if let error {
                AppLog.debugOnly(AppLog.appRemote, "Player-State-Abonnement fehlgeschlagen: \(error)")
                self?.connectionStatus = .failed(.appRemoteNotConnected)
            }
        })
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        AppLog.debugOnly(AppLog.appRemote, "Verbindung fehlgeschlagen: \(String(describing: error))")
        connectionStatus = .failed(.appRemoteNotConnected)
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        connectionStatus = .disconnected
        playbackState = .idle
    }
}

extension SpotifyAppRemoteService: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        let track = SpotifyTrack(
            uri: playerState.track.uri,
            name: playerState.track.name,
            artistName: playerState.track.artist.name,
            albumName: playerState.track.album.name,
            imageURL: nil,
            duration: TimeInterval(playerState.track.duration) / 1000
        )
        playbackState = SpotifyPlaybackState(
            track: track,
            isPaused: playerState.isPaused,
            playbackPosition: TimeInterval(playerState.playbackPosition) / 1000,
            isShuffled: playerState.playbackOptions.isShuffling,
            repeatMode: Int(playerState.playbackOptions.repeatMode.rawValue),
            contextURI: playerState.contextURI.absoluteString
        )
        fetchCoverImage(for: playerState.track)
    }

    private func fetchCoverImage(for track: SPTAppRemoteTrack) {
        appRemote.imageAPI?.fetchImage(forItem: track, with: CGSize(width: 300, height: 300)) { [weak self] image, _ in
            guard let self, let uiImage = image as? UIImage, self.playbackState.track?.uri == track.uri else { return }
            self.nowPlayingArtwork = uiImage
        }
    }
}
#endif
