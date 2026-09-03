//
//  MockSpotifyAppRemoteService.swift
//  DemonicSpotifyController
//
//  Mock von App Remote für Previews, Simulator (kein Spotify-App-Remote
//  verfügbar) und Unit Tests.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class MockSpotifyAppRemoteService: SpotifyAppRemoteServicing {
    var connectionStatus: AppRemoteConnectionStatus = .disconnected
    var playbackState: SpotifyPlaybackState = .idle
    var nowPlayingArtwork: UIImage?
    var isSpotifyInstalled: Bool = true

    private(set) var playCallCount = 0
    private(set) var lastPlayedURI: String?
    /// Erlaubt Tests, eine künstliche Verzögerung zu simulieren, um zu prüfen,
    /// dass Mehrfachtippen keine doppelten Wiedergabebefehle auslöst.
    var playDelayNanoseconds: UInt64 = 0

    func connect(accessToken: String) {
        connectionStatus = .connected
    }

    func reconnectSilently() {
        if !connectionStatus.isConnected { connectionStatus = .connected }
    }

    func disconnect() {
        connectionStatus = .disconnected
        playbackState = .idle
    }

    func authorizeAndPlay(uri: String) {
        connectionStatus = .connected
        playCallCount += 1
        lastPlayedURI = uri
        playbackState = SpotifyPlaybackState(
            track: SampleData.sampleTrack, isPaused: false, playbackPosition: 0,
            isShuffled: false, repeatMode: 0, contextURI: uri
        )
    }

    func handleOpenURL(_ url: URL) -> Bool { true }

    func play(uri: String) async throws {
        if playDelayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: playDelayNanoseconds)
        }
        playCallCount += 1
        lastPlayedURI = uri
        playbackState = SpotifyPlaybackState(
            track: SampleData.sampleTrack, isPaused: false, playbackPosition: 0,
            isShuffled: playbackState.isShuffled, repeatMode: playbackState.repeatMode, contextURI: uri
        )
    }

    func pause() async throws {
        playbackState = SpotifyPlaybackState(
            track: playbackState.track, isPaused: true, playbackPosition: playbackState.playbackPosition,
            isShuffled: playbackState.isShuffled, repeatMode: playbackState.repeatMode, contextURI: playbackState.contextURI
        )
    }

    func resume() async throws {
        playbackState = SpotifyPlaybackState(
            track: playbackState.track, isPaused: false, playbackPosition: playbackState.playbackPosition,
            isShuffled: playbackState.isShuffled, repeatMode: playbackState.repeatMode, contextURI: playbackState.contextURI
        )
    }

    func skipToNext() async throws {}
    func skipToPrevious() async throws {}

    func setShuffle(_ enabled: Bool) async throws {
        playbackState = SpotifyPlaybackState(
            track: playbackState.track, isPaused: playbackState.isPaused, playbackPosition: playbackState.playbackPosition,
            isShuffled: enabled, repeatMode: playbackState.repeatMode, contextURI: playbackState.contextURI
        )
    }

    func setRepeatMode(_ mode: Int) async throws {
        playbackState = SpotifyPlaybackState(
            track: playbackState.track, isPaused: playbackState.isPaused, playbackPosition: playbackState.playbackPosition,
            isShuffled: playbackState.isShuffled, repeatMode: mode, contextURI: playbackState.contextURI
        )
    }
}
