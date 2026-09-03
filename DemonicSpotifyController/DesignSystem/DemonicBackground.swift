//
//  DemonicBackground.swift
//  DemonicSpotifyController
//
//  Obsidian-Hintergrund mit dezenten glühenden Rissen und Glutpartikeln.
//  Performant (Canvas-basiert) und respektiert "Bewegung reduzieren".
//

import SwiftUI

struct DemonicBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var showEmbers: Bool = true

    var body: some View {
        ZStack {
            DemonicPalette.backgroundGradient
                .ignoresSafeArea()

            RuneCracksOverlay()
                .opacity(0.18)
                .ignoresSafeArea()

            if showEmbers && !reduceMotion {
                EmberParticlesView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}

/// Feine, glühende Risse im Hintergrund – rein dekorativ, statisch gezeichnet.
private struct RuneCracksOverlay: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let points: [[CGPoint]] = [
                [CGPoint(x: size.width * 0.1, y: size.height * 0.15),
                 CGPoint(x: size.width * 0.3, y: size.height * 0.28),
                 CGPoint(x: size.width * 0.22, y: size.height * 0.42)],
                [CGPoint(x: size.width * 0.85, y: size.height * 0.6),
                 CGPoint(x: size.width * 0.7, y: size.height * 0.72),
                 CGPoint(x: size.width * 0.78, y: size.height * 0.88)]
            ]
            for segment in points {
                path.addLines(segment)
            }
            context.stroke(path, with: .color(DemonicPalette.glowingScarlet), lineWidth: 1)
        }
    }
}

/// Leichte, langsam aufsteigende Glut-/Rauchpartikel.
struct EmberParticlesView: View {
    private struct Ember: Identifiable {
        let id = UUID()
        let xFraction: CGFloat
        let delay: Double
        let duration: Double
        let scale: CGFloat
    }

    private let embers: [Ember] = (0..<14).map { index in
        Ember(
            xFraction: CGFloat.random(in: 0...1, using: &SeededGenerator(seed: index)),
            delay: Double.random(in: 0...4, using: &SeededGenerator(seed: index + 100)),
            duration: Double.random(in: 6...11, using: &SeededGenerator(seed: index + 200)),
            scale: CGFloat.random(in: 0.5...1.3, using: &SeededGenerator(seed: index + 300))
        )
    }

    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(embers) { ember in
                    Circle()
                        .fill(DemonicPalette.emberOrange.opacity(0.5))
                        .frame(width: 4 * ember.scale, height: 4 * ember.scale)
                        .blur(radius: 1)
                        .position(x: ember.xFraction * proxy.size.width, y: animate ? -20 : proxy.size.height + 20)
                        .animation(
                            .linear(duration: ember.duration).repeatForever(autoreverses: false).delay(ember.delay),
                            value: animate
                        )
                }
            }
            .onAppear { animate = true }
        }
    }
}

/// Deterministischer Zufallsgenerator, damit sich Partikelpositionen nicht
/// bei jedem Body-Neuaufbau ändern.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: Int) { state = UInt64(bitPattern: Int64(seed)) &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
