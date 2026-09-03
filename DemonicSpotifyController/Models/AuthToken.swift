//
//  AuthToken.swift
//  DemonicSpotifyController
//
//  Repräsentiert einen Spotify-Zugriffstoken-Satz. Wird niemals in
//  UserDefaults gespeichert – nur über KeychainService.
//

import Foundation

struct AuthToken: Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiryDate: Date
    let scope: String

    var isExpired: Bool {
        // 60 Sekunden Sicherheitsmarge, bevor der Token tatsächlich abläuft.
        Date() >= expiryDate.addingTimeInterval(-60)
    }

    var isValid: Bool {
        !accessToken.isEmpty && !isExpired
    }
}
