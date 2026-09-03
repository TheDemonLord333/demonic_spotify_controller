//
//  ConnectSpotifyView.swift
//  DemonicSpotifyController
//
//  Erster Bildschirm, solange kein Spotify-Konto verbunden ist. Zeigt im
//  Demo-Modus (fehlende/unvollständige SpotifyConfig.json) einen Hinweis
//  und erlaubt trotzdem, die Kachelübersicht mit Mock-Daten zu erkunden.
//

import SwiftUI

struct ConnectSpotifyView: View {
    let environment: AppEnvironment

    @State private var isConnecting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 56))
                .foregroundStyle(DemonicPalette.glowingScarlet)
                .shadow(color: DemonicPalette.glowingScarlet.opacity(0.6), radius: 16)

            VStack(spacing: 8) {
                Text("Demonic Spotify Controller")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DemonicPalette.textPrimary)
                Text("Verbinde dein Spotify-Konto, um deine Playlists und Alben als Kacheln zu speichern.")
                    .font(.subheadline)
                    .foregroundStyle(DemonicPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if environment.isDemoMode {
                VStack(spacing: 6) {
                    Label("Demo-Modus", systemImage: "wand.and.stars")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DemonicPalette.emberOrange)
                    Text(environment.configurationError?.errorDescription ?? "Spotify-Konfiguration fehlt.")
                        .font(.caption2)
                        .foregroundStyle(DemonicPalette.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 4)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(DemonicPalette.glowingScarlet)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                Task { await connect() }
            } label: {
                if isConnecting {
                    ProgressView().tint(.white)
                } else {
                    Label("Mit Spotify verbinden", systemImage: "bolt.fill")
                }
            }
            .buttonStyle(DemonicPrimaryButtonStyle())
            .disabled(isConnecting)
            .padding(.horizontal, 40)

            if environment.isDemoMode {
                Text("Im Demo-Modus kannst du die Oberfläche mit Beispieldaten erkunden.")
                    .font(.caption2)
                    .foregroundStyle(DemonicPalette.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer().frame(height: 24)
        }
    }

    private func connect() async {
        isConnecting = true
        errorMessage = nil
        defer { isConnecting = false }
        do {
            try await environment.authService.beginAuthorization()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? DemonicError.authorizationDenied.errorDescription
        }
    }
}
