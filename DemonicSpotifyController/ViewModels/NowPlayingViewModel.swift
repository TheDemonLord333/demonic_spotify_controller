//
//  NowPlayingViewModel.swift
//  DemonicSpotifyController
//
//  Dünne Fassade über `PlaybackCoordinator` für Now-Playing-Ansichten.
//  Hält den Player-State bewusst nicht doppelt, sondern liest ihn direkt
//  vom Coordinator, damit Aktualisierungen über App Remote sofort
//  durchschlagen.
//

import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class NowPlayingViewModel {
    let coordinator: PlaybackCoordinator

    init(coordinator: PlaybackCoordinator) {
        self.coordinator = coordinator
    }

    var playbackState: SpotifyPlaybackState { coordinator.playbackState }
    var connectionStatus: AppRemoteConnectionStatus { coordinator.connectionStatus }
    var artwork: UIImage? { coordinator.nowPlayingArtwork }
    var lastError: DemonicError? { coordinator.lastError }

    func togglePlayPause() async { await coordinator.togglePlayPause() }
    func skipToNext() async { await coordinator.skipToNext() }
    func skipToPrevious() async { await coordinator.skipToPrevious() }
    func toggleShuffle() async { await coordinator.toggleShuffle() }
    func cycleRepeatMode() async { await coordinator.cycleRepeatMode() }

    func openInSpotify() {
        guard let uri = playbackState.contextURI ?? playbackState.track?.uri else { return }
        coordinator.openInSpotify(uri: uri)
    }
}
