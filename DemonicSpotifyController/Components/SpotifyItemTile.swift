//
//  SpotifyItemTile.swift
//  DemonicSpotifyController
//
//  Große Kachel für eine gespeicherte Playlist/ein Album. Ein kurzer Tipp
//  startet sofort die Wiedergabe (keine Zwischenseite). Zeigt echtes
//  Cover, Namen, Typ, Künstler/Besitzer, Wiedergabeindikator und ein
//  Kontextmenü zum Bearbeiten/Entfernen.
//

import SwiftUI

struct SpotifyItemTile: View {
    let item: SavedSpotifyItem
    var isPlaying: Bool
    var isLoading: Bool

    var onTap: () -> Void
    var onOpenInSpotify: () -> Void
    var onToggleFavorite: () -> Void
    var onEdit: () -> Void
    var onRemove: () -> Void

    @State private var flash = false

    var body: some View {
        Button {
            triggerTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    CoverImageView(url: item.coverImageURL)
                        .flashOverlay(isActive: flash)

                    if isLoading {
                        Color.black.opacity(0.35)
                            .clipShape(RoundedRectangle(cornerRadius: DemonicTheme.tileCornerRadius, style: .continuous))
                        ProgressView()
                            .tint(DemonicPalette.glowingScarlet)
                    }

                    if item.isFavorite {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                    .foregroundStyle(DemonicPalette.emberOrange)
                                    .padding(6)
                                    .background(.black.opacity(0.4), in: Circle())
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }
                }
                .pulsingGlowBorder(isActive: isPlaying)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DemonicPalette.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: item.contentType.sfSymbol)
                            .font(.caption2)
                        Text(subtitle)
                            .lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(DemonicPalette.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(item.displayName), \(item.contentType.displayName)\(isPlaying ? ", spielt gerade" : "")"))
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button {
                onToggleFavorite()
            } label: {
                Label(item.isFavorite ? "Favorit entfernen" : "Als Favorit markieren", systemImage: item.isFavorite ? "flame.slash" : "flame")
            }
            Button {
                onEdit()
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            Button {
                onOpenInSpotify()
            } label: {
                Label("In Spotify öffnen", systemImage: "arrow.up.right.square")
            }
            Divider()
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Entfernen", systemImage: "trash")
            }
        }
    }

    private var subtitle: String {
        if let artistOrOwner = item.artistOrOwner, !artistOrOwner.isEmpty {
            return artistOrOwner
        }
        return item.contentType.displayName
    }

    private func triggerTap() {
        guard !isLoading else { return }
        Haptics.lightTap()
        flash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { flash = false }
        onTap()
    }
}
