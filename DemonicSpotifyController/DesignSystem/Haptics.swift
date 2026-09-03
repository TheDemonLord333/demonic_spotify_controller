//
//  Haptics.swift
//  DemonicSpotifyController
//
//  Kleiner Helfer für konsistentes haptisches Feedback bei Erfolg/Fehler.
//

import UIKit

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func failure() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
