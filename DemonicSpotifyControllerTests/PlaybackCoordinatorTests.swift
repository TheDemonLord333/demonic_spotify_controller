//
//  PlaybackCoordinatorTests.swift
//  DemonicSpotifyControllerTests
//

import Testing
@testable import DemonicSpotifyController

@MainActor
struct PlaybackCoordinatorTests {

    @Test func playsImmediatelyWhenAlreadyConnected() async {
        let remote = MockSpotifyAppRemoteService()
        remote.connectionStatus = .connected
        let auth = MockSpotifyAuthService()
        let coordinator = PlaybackCoordinator(appRemote: remote, authService: auth)

        await coordinator.requestPlayback(uri: "spotify:playlist:abc")

        #expect(remote.playCallCount == 1)
        #expect(remote.lastPlayedURI == "spotify:playlist:abc")
        #expect(coordinator.lastError == nil)
    }

    @Test func triggersOfficialHandoffWhenNotConnected() async {
        let remote = MockSpotifyAppRemoteService()
        remote.connectionStatus = .disconnected
        let auth = MockSpotifyAuthService()
        let coordinator = PlaybackCoordinator(appRemote: remote, authService: auth)

        await coordinator.requestPlayback(uri: "spotify:album:xyz")

        // authorizeAndPlay() setzt im Mock den Verbindungsstatus selbst und
        // zählt als "Wiedergabe ausgelöst".
        #expect(remote.playCallCount == 1)
        #expect(remote.lastPlayedURI == "spotify:album:xyz")
        #expect(coordinator.lastError == .appSwitchRequired)
    }

    @Test func reportsMissingSpotifyApp() async {
        let remote = MockSpotifyAppRemoteService()
        remote.isSpotifyInstalled = false
        let auth = MockSpotifyAuthService()
        let coordinator = PlaybackCoordinator(appRemote: remote, authService: auth)

        await coordinator.requestPlayback(uri: "spotify:playlist:abc")

        #expect(remote.playCallCount == 0)
        #expect(coordinator.lastError == .spotifyAppNotInstalled)
    }

    @Test func reportsMissingSpotifyAccount() async {
        let remote = MockSpotifyAppRemoteService()
        let auth = MockSpotifyAuthService()
        auth.state = .signedOut
        let coordinator = PlaybackCoordinator(appRemote: remote, authService: auth)

        await coordinator.requestPlayback(uri: "spotify:playlist:abc")

        #expect(remote.playCallCount == 0)
        #expect(coordinator.lastError == .spotifyAccountNotConnected)
    }

    @Test func preventsDuplicatePlaybackCommandsForRapidDoubleTap() async {
        let remote = MockSpotifyAppRemoteService()
        remote.connectionStatus = .connected
        remote.playDelayNanoseconds = 150_000_000
        let auth = MockSpotifyAuthService()
        let coordinator = PlaybackCoordinator(appRemote: remote, authService: auth)

        async let first: Void = coordinator.requestPlayback(uri: "spotify:playlist:abc")
        try? await Task.sleep(nanoseconds: 20_000_000)
        async let second: Void = coordinator.requestPlayback(uri: "spotify:playlist:abc")
        _ = await (first, second)

        #expect(remote.playCallCount == 1)
    }

    @Test func clearErrorResetsLastError() async {
        let remote = MockSpotifyAppRemoteService()
        remote.isSpotifyInstalled = false
        let auth = MockSpotifyAuthService()
        let coordinator = PlaybackCoordinator(appRemote: remote, authService: auth)

        await coordinator.requestPlayback(uri: "spotify:playlist:abc")
        #expect(coordinator.lastError != nil)

        coordinator.clearError()
        #expect(coordinator.lastError == nil)
    }
}
