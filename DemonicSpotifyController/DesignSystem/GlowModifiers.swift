//
//  GlowModifiers.swift
//  DemonicSpotifyController
//
//  View-Modifier für das kurze rote Aufleuchten beim Antippen und den
//  pulsierenden Rand für aktuell wiedergegebene Inhalte. Respektiert
//  "Bewegung reduzieren".
//

import SwiftUI

/// Kurzes, rotes Aufleuchten – z. B. beim Antippen einer Kachel.
struct FlashOverlay: ViewModifier {
    var isActive: Bool
    var cornerRadius: CGFloat = DemonicTheme.tileCornerRadius

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(DemonicPalette.glowingScarlet.opacity(isActive ? 0.35 : 0))
                .animation(.easeOut(duration: 0.35), value: isActive)
                .allowsHitTesting(false)
        )
    }
}

/// Pulsierender roter Rand für aktuell laufenden Inhalt.
struct PulsingGlowBorder: ViewModifier {
    var isActive: Bool
    var cornerRadius: CGFloat = DemonicTheme.tileCornerRadius
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(DemonicPalette.glowingScarlet.opacity(isActive ? (pulse ? 1 : 0.55) : 0), lineWidth: 2.5)
                    .shadow(color: DemonicPalette.glowingScarlet.opacity(isActive ? 0.7 : 0), radius: pulse ? 8 : 3)
            )
            .onAppear { startPulseIfNeeded() }
            .onChange(of: isActive) { _, _ in startPulseIfNeeded() }
    }

    private func startPulseIfNeeded() {
        guard isActive, !reduceMotion else {
            pulse = false
            return
        }
        withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
            pulse = true
        }
    }
}

extension View {
    func flashOverlay(isActive: Bool, cornerRadius: CGFloat = DemonicTheme.tileCornerRadius) -> some View {
        modifier(FlashOverlay(isActive: isActive, cornerRadius: cornerRadius))
    }

    func pulsingGlowBorder(isActive: Bool, cornerRadius: CGFloat = DemonicTheme.tileCornerRadius) -> some View {
        modifier(PulsingGlowBorder(isActive: isActive, cornerRadius: cornerRadius))
    }
}
