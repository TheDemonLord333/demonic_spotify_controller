//
//  ConnectionStatus.swift
//  DemonicSpotifyController
//

import Foundation

/// Verbindungsstatus von Spotify App Remote (lokale Wiedergabesteuerung).
enum AppRemoteConnectionStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(DemonicError)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var shortLabel: String {
        switch self {
        case .disconnected: return "Getrennt"
        case .connecting: return "Verbinde …"
        case .connected: return "Verbunden"
        case .failed: return "Fehler"
        }
    }
}
