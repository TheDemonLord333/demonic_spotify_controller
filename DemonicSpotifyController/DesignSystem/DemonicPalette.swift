//
//  DemonicPalette.swift
//  DemonicSpotifyController
//
//  Zentrale Farbpalette im dämonischen Stil: nahezu schwarzer Hintergrund,
//  Obsidian, tiefes Blutrot, glühendes Scharlach, dezente Glut-Akzente.
//  Spotify-Grün wird bewusst nur sparsam für das offizielle Spotify-Symbol
//  bzw. den Verbindungsstatus verwendet.
//

import SwiftUI

enum DemonicPalette {
    static let voidBlack = Color(red: 0.02, green: 0.02, blue: 0.03)
    static let obsidian = Color(red: 0.06, green: 0.055, blue: 0.07)
    static let anthracite = Color(red: 0.11, green: 0.105, blue: 0.12)
    static let smokeGlass = Color(red: 0.16, green: 0.14, blue: 0.16).opacity(0.55)

    static let bloodRed = Color(red: 0.55, green: 0.03, blue: 0.05)
    static let bordeaux = Color(red: 0.32, green: 0.04, blue: 0.08)
    static let glowingScarlet = Color(red: 0.92, green: 0.11, blue: 0.16)
    static let emberOrange = Color(red: 0.98, green: 0.45, blue: 0.12)

    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.72)
    static let textTertiary = Color(white: 0.5)

    /// Nur für das offizielle Spotify-Symbol/den Verbindungsstatus.
    static let spotifyGreen = Color(red: 0.11, green: 0.73, blue: 0.33)

    static let backgroundGradient = LinearGradient(
        colors: [voidBlack, obsidian, Color(red: 0.08, green: 0.02, blue: 0.03)],
        startPoint: .top, endPoint: .bottom
    )

    static let tileGradient = LinearGradient(
        colors: [anthracite, obsidian],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let glowGradient = LinearGradient(
        colors: [glowingScarlet, bloodRed],
        startPoint: .leading, endPoint: .trailing
    )
}
