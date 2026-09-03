//
//  DemonicTheme.swift
//  DemonicSpotifyController
//
//  Wiederverwendbare Layout- und Stilkonstanten sowie Button-Styles.
//

import SwiftUI

enum DemonicTheme {
    static let tileCornerRadius: CGFloat = 18
    static let cardCornerRadius: CGFloat = 22
    static let controlCornerRadius: CGFloat = 14
    static let standardSpacing: CGFloat = 14
    static let minimumTapTarget: CGFloat = 44
}

struct DemonicPrimaryButtonStyle: ButtonStyle {
    var tint: Color = DemonicPalette.glowingScarlet

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(DemonicPalette.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(minHeight: DemonicTheme.minimumTapTarget)
            .background(
                RoundedRectangle(cornerRadius: DemonicTheme.controlCornerRadius, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.7 : 0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DemonicTheme.controlCornerRadius, style: .continuous)
                    .strokeBorder(tint.opacity(0.6), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct DemonicIconButtonStyle: ButtonStyle {
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(DemonicPalette.textPrimary)
            .frame(width: size, height: size)
            .background(
                Circle().fill(DemonicPalette.smokeGlass)
            )
            .overlay(
                Circle().strokeBorder(DemonicPalette.glowingScarlet.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    /// Obsidian-/Rauchglas-Karte mit feinem, rotem Leuchtrand.
    func demonicCardBackground(cornerRadius: CGFloat = DemonicTheme.cardCornerRadius) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(DemonicPalette.tileGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(DemonicPalette.glowingScarlet.opacity(0.25), lineWidth: 1)
        )
    }
}
