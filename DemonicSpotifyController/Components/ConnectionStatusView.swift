//
//  ConnectionStatusView.swift
//  DemonicSpotifyController
//
//  Kleine Statusanzeige für die App-Remote-Verbindung. Verwendet
//  Spotify-Grün sparsam, ausschließlich für den verbundenen Zustand.
//

import SwiftUI

struct ConnectionStatusView: View {
    let status: AppRemoteConnectionStatus

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status.shortLabel)
                .font(.caption2.weight(.medium))
                .foregroundStyle(DemonicPalette.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(DemonicPalette.smokeGlass, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Spotify-Verbindung: \(status.shortLabel)")
    }

    private var color: Color {
        switch status {
        case .connected: return DemonicPalette.spotifyGreen
        case .connecting: return DemonicPalette.emberOrange
        case .disconnected: return DemonicPalette.textTertiary
        case .failed: return DemonicPalette.glowingScarlet
        }
    }
}
