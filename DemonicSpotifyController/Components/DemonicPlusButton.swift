//
//  DemonicPlusButton.swift
//  DemonicSpotifyController
//
//  Dämonisch gestalteter Plus-Button zum Hinzufügen neuer Inhalte.
//

import SwiftUI

struct DemonicPlusButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
        }
        .buttonStyle(DemonicIconButtonStyle(size: 52))
        .shadow(color: DemonicPalette.glowingScarlet.opacity(0.5), radius: 10)
        .accessibilityLabel("Spotify-Inhalt hinzufügen")
    }
}
