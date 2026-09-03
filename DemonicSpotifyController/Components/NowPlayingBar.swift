//
//  NowPlayingBar.swift
//  DemonicSpotifyController
//
//  Now-Playing-Player im dämonischen Stil. Kompakt im Hochformat, größer
//  im Querformat. Ein Tippen auf den Player öffnet niemals Spotify – dafür
//  gibt es ausschließlich die separate Aktion "In Spotify öffnen".
//

import SwiftUI

struct NowPlayingBar: View {
    let coordinator: PlaybackCoordinator
    var isExpanded: Bool = false

    var body: some View {
        if let track = coordinator.playbackState.track {
            content(for: track)
        } else {
            idleContent
        }
    }

    @ViewBuilder
    private func content(for track: SpotifyTrack) -> some View {
        if isExpanded {
            expandedLayout(track: track)
        } else {
            compactLayout(track: track)
        }
    }

    private func compactLayout(track: SpotifyTrack) -> some View {
        HStack(spacing: 12) {
            artwork(size: 46)

            VStack(alignment: .leading, spacing: 1) {
                Text(track.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                Text(track.artistName).font(.caption).foregroundStyle(DemonicPalette.textSecondary).lineLimit(1)
            }
            .foregroundStyle(DemonicPalette.textPrimary)

            Spacer()

            controlButton(systemImage: "backward.fill") { Task { await coordinator.skipToPrevious() } }
            playPauseButton(size: 40)
            controlButton(systemImage: "forward.fill") { Task { await coordinator.skipToNext() } }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .demonicCardBackground(cornerRadius: DemonicTheme.cardCornerRadius)
        .padding(.horizontal, 12)
        .contextMenu {
            openInSpotifyButton(uri: track.uri)
        }
    }

    private func expandedLayout(track: SpotifyTrack) -> some View {
        VStack(spacing: 16) {
            artwork(size: 220)
                .shadow(color: .black.opacity(0.5), radius: 16, y: 8)

            VStack(spacing: 4) {
                Text(track.name).font(.title3.weight(.bold)).lineLimit(2).multilineTextAlignment(.center)
                Text(track.artistName).font(.subheadline).foregroundStyle(DemonicPalette.textSecondary)
                Text(track.albumName).font(.caption).foregroundStyle(DemonicPalette.textTertiary)
            }
            .foregroundStyle(DemonicPalette.textPrimary)

            progressView(track: track)

            HStack(spacing: 28) {
                controlButton(systemImage: "shuffle", isActive: coordinator.playbackState.isShuffled) {
                    Task { await coordinator.toggleShuffle() }
                }
                controlButton(systemImage: "backward.fill") { Task { await coordinator.skipToPrevious() } }
                playPauseButton(size: 62)
                controlButton(systemImage: "forward.fill") { Task { await coordinator.skipToNext() } }
                controlButton(systemImage: repeatSymbol, isActive: coordinator.playbackState.repeatMode != 0) {
                    Task { await coordinator.cycleRepeatMode() }
                }
            }

            HStack {
                ConnectionStatusView(status: coordinator.connectionStatus)
                Spacer()
                openInSpotifyButton(uri: track.uri)
            }
        }
        .padding(24)
        .demonicCardBackground(cornerRadius: DemonicTheme.cardCornerRadius)
        .padding(20)
    }

    private var idleContent: some View {
        HStack {
            Image(systemName: "moon.stars")
                .foregroundStyle(DemonicPalette.textTertiary)
            Text("Keine Wiedergabe aktiv")
                .font(.subheadline)
                .foregroundStyle(DemonicPalette.textSecondary)
            Spacer()
            ConnectionStatusView(status: coordinator.connectionStatus)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .demonicCardBackground(cornerRadius: DemonicTheme.cardCornerRadius)
        .padding(.horizontal, 12)
    }

    // MARK: - Bausteine

    private func artwork(size: CGFloat) -> some View {
        Group {
            if let image = coordinator.nowPlayingArtwork {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    DemonicPalette.tileGradient
                    Image(systemName: "flame.fill").foregroundStyle(DemonicPalette.glowingScarlet.opacity(0.6))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size > 100 ? 16 : 8, style: .continuous))
    }

    private func playPauseButton(size: CGFloat) -> some View {
        Button {
            Task { await coordinator.togglePlayPause() }
        } label: {
            Image(systemName: coordinator.playbackState.isPaused ? "play.fill" : "pause.fill")
        }
        .buttonStyle(DemonicIconButtonStyle(size: size))
        .accessibilityLabel(coordinator.playbackState.isPaused ? "Wiedergabe fortsetzen" : "Wiedergabe pausieren")
    }

    private func controlButton(systemImage: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
        }
        .buttonStyle(DemonicIconButtonStyle(size: 40))
        .foregroundStyle(isActive ? DemonicPalette.glowingScarlet : DemonicPalette.textPrimary)
    }

    private func openInSpotifyButton(uri: String) -> some View {
        Button {
            coordinator.openInSpotify(uri: coordinator.playbackState.contextURI ?? uri)
        } label: {
            Label("In Spotify öffnen", systemImage: "arrow.up.right.square")
        }
    }

    private func progressView(track: SpotifyTrack) -> some View {
        let progress = track.duration > 0 ? min(coordinator.playbackState.playbackPosition / track.duration, 1) : 0
        return VStack(spacing: 4) {
            ProgressView(value: progress)
                .tint(DemonicPalette.glowingScarlet)
            HStack {
                Text(formatted(coordinator.playbackState.playbackPosition))
                Spacer()
                Text(formatted(track.duration))
            }
            .font(.caption2)
            .foregroundStyle(DemonicPalette.textTertiary)
        }
    }

    private var repeatSymbol: String {
        coordinator.playbackState.repeatMode == 2 ? "repeat.1" : "repeat"
    }

    private func formatted(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
