//
//  SpotifyAuthServiceTests.swift
//  DemonicSpotifyControllerTests
//

import Testing
import Foundation
@testable import DemonicSpotifyController

struct AuthTokenTests {
    @Test func validTokenIsNotExpired() {
        let token = AuthToken(accessToken: "abc", refreshToken: "def", expiryDate: Date().addingTimeInterval(3600), scope: "")
        #expect(token.isValid)
        #expect(!token.isExpired)
    }

    @Test func tokenNearExpiryCountsAsExpired() {
        // Innerhalb der 60-Sekunden-Sicherheitsmarge.
        let token = AuthToken(accessToken: "abc", refreshToken: "def", expiryDate: Date().addingTimeInterval(30), scope: "")
        #expect(token.isExpired)
        #expect(!token.isValid)
    }

    @Test func emptyAccessTokenIsNeverValid() {
        let token = AuthToken(accessToken: "", refreshToken: nil, expiryDate: Date().addingTimeInterval(3600), scope: "")
        #expect(!token.isValid)
    }
}

struct PKCEHelperTests {
    @Test func codeVerifierHasExpectedLengthAndCharacterSet() {
        let verifier = PKCEHelper.generateCodeVerifier()
        #expect(verifier.count == 64)
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        #expect(verifier.unicodeScalars.allSatisfy { allowed.contains($0) })
    }

    @Test func codeVerifiersAreRandomized() {
        let first = PKCEHelper.generateCodeVerifier()
        let second = PKCEHelper.generateCodeVerifier()
        #expect(first != second)
    }

    @Test func codeChallengeIsDeterministicForSameVerifier() {
        let verifier = "test-verifier-value"
        let challengeA = PKCEHelper.codeChallenge(forVerifier: verifier)
        let challengeB = PKCEHelper.codeChallenge(forVerifier: verifier)
        #expect(challengeA == challengeB)
        #expect(!challengeA.contains("="))
        #expect(!challengeA.contains("+"))
        #expect(!challengeA.contains("/"))
    }
}

@MainActor
struct SpotifyAuthServiceTests {
    private let configuration = SpotifyConfiguration(clientId: "test-client-id", redirectUri: "demonicspotify://callback")

    @Test func restoresValidSessionFromKeychain() async {
        let keychain = MockKeychainService()
        try? keychain.set("valid-token", forKey: AppConstants.KeychainKeys.accessToken)
        try? keychain.set(ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)), forKey: AppConstants.KeychainKeys.tokenExpiryDate)
        try? keychain.set("refresh-token", forKey: AppConstants.KeychainKeys.refreshToken)

        let service = SpotifyAuthService(configuration: configuration, keychain: keychain)
        await service.restoreSession()

        #expect(service.state == .signedIn)
    }

    @Test func restoreWithoutStoredTokenSignsOut() async {
        let service = SpotifyAuthService(configuration: configuration, keychain: MockKeychainService())
        await service.restoreSession()
        #expect(service.state == .signedOut)
    }

    @Test func validAccessTokenReturnsStoredTokenWhenValid() async throws {
        let keychain = MockKeychainService()
        try keychain.set("valid-token", forKey: AppConstants.KeychainKeys.accessToken)
        try keychain.set(ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)), forKey: AppConstants.KeychainKeys.tokenExpiryDate)

        let service = SpotifyAuthService(configuration: configuration, keychain: keychain)
        let token = try await service.validAccessToken()
        #expect(token == "valid-token")
    }

    @Test func validAccessTokenThrowsWhenNoTokenStored() async {
        let service = SpotifyAuthService(configuration: configuration, keychain: MockKeychainService())
        await #expect(throws: DemonicError.spotifyAccountNotConnected) {
            _ = try await service.validAccessToken()
        }
    }

    @Test func refreshFailsCleanlyWithoutRefreshToken() async throws {
        let keychain = MockKeychainService()
        try keychain.set("expired-token", forKey: AppConstants.KeychainKeys.accessToken)
        try keychain.set(ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)), forKey: AppConstants.KeychainKeys.tokenExpiryDate)
        // Bewusst kein Refresh-Token gespeichert.

        let service = SpotifyAuthService(configuration: configuration, keychain: keychain)
        await #expect(throws: DemonicError.tokenRefreshFailed) {
            _ = try await service.refreshAccessToken()
        }
    }

    @Test func logoutClearsKeychainAndState() throws {
        let keychain = MockKeychainService()
        try keychain.set("token", forKey: AppConstants.KeychainKeys.accessToken)
        let service = SpotifyAuthService(configuration: configuration, keychain: keychain)

        service.logout()

        #expect(service.state == .signedOut)
        #expect(keychain.string(forKey: AppConstants.KeychainKeys.accessToken) == nil)
    }
}
