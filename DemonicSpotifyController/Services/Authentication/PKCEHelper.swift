//
//  PKCEHelper.swift
//  DemonicSpotifyController
//
//  Erzeugt Code-Verifier und Code-Challenge für den Authorization Code
//  Flow mit PKCE (RFC 7636). Reine, seiteneffektfreie Funktionen – gut
//  unit-testbar.
//

import Foundation
import CryptoKit

enum PKCEHelper {
    /// Erzeugt einen kryptographisch zufälligen Code-Verifier (43–128 Zeichen,
    /// unreserved Characters gemäß RFC 7636).
    static func generateCodeVerifier(length: Int = 64) -> String {
        let allowed = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        if status == errSecSuccess {
            return String(bytes.map { allowed[Int($0) % allowed.count] })
        }
        // Fallback (praktisch nie erreicht) – weiterhin zufällig, nur ohne SecRandom.
        return String((0..<length).map { _ in allowed.randomElement()! })
    }

    /// S256-Code-Challenge gemäß RFC 7636: BASE64URL(SHA256(verifier)) ohne Padding.
    static func codeChallenge(forVerifier verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        let data = Data(digest)
        return base64URLEncode(data)
    }

    /// Zufälliger State-Parameter gegen CSRF im Authorization-Code-Flow.
    static func generateState() -> String {
        generateCodeVerifier(length: 32)
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
