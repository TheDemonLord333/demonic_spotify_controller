//
//  CoverImageView.swift
//  DemonicSpotifyController
//
//  Lädt echte Spotify-Cover asynchron über ImageCache. Zeigt einen
//  dämonisch gestalteten Platzhalter beim Laden sowie einen klaren
//  Fehlerzustand, falls das Cover nicht verfügbar ist. Cover werden
//  niemals farblich verfälscht.
//

import SwiftUI

struct CoverImageView: View {
    let url: URL?
    var cornerRadius: CGFloat = DemonicTheme.tileCornerRadius

    @State private var loadedImage: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            if let loadedImage {
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if failed || url == nil {
                placeholder(showsErrorGlyph: failed)
            } else {
                placeholder(showsErrorGlyph: false)
                    .overlay(ProgressView().tint(DemonicPalette.glowingScarlet))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .task(id: url) { await load() }
    }

    private func placeholder(showsErrorGlyph: Bool) -> some View {
        ZStack {
            DemonicPalette.tileGradient
            Image(systemName: showsErrorGlyph ? "exclamationmark.triangle" : "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(DemonicPalette.glowingScarlet.opacity(0.7))
        }
    }

    private func load() async {
        failed = false
        loadedImage = nil
        guard let url else { return }
        do {
            loadedImage = try await ImageCache.shared.image(for: url)
        } catch {
            failed = true
        }
    }
}
