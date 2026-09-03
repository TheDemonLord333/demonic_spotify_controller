//
//  SpotifyAuthService.swift
//  DemonicSpotifyController
//
//  Verwaltet die Spotify-Anmeldung über Authorization Code Flow mit PKCE.
//  Es wird bewusst KEIN Client Secret verwendet oder benötigt – PKCE ist
//  für native/mobile Apps als "public client" ausgelegt (siehe SETUP.md).
//
//  Der Login läuft über ASWebAuthenticationSession (App-Store-konform,
//  System-UI). Der App-Remote-spezifische Reaktivierungs-Callback
//  (`authorizeAndPlayURI`) läuft dagegen über das Redirect-URL-Scheme und
//  wird zusätzlich über `onOpenURL` in `SpotifyAppRemoteService` behandelt.
//

import Foundation
import AuthenticationServices
import Observation
#if canImport(UIKit)
import UIKit
#endif

enum SpotifyAuthState: Equatable {
    case signedOut
    case authorizing
    case signedIn
    case error(DemonicError)
}

@MainActor
protocol SpotifyAuthServicing: AnyObject {
    var state: SpotifyAuthState { get }
    func restoreSession() async
    func beginAuthorization() async throws
    func validAccessToken() async throws -> String
    func logout()
}

@MainActor
@Observable
final class SpotifyAuthService: NSObject, SpotifyAuthServicing {

    private(set) var state: SpotifyAuthState = .signedOut

    private let configuration: SpotifyConfiguration
    private let keychain: KeychainServicing
    private let urlSession: URLSession
    private var webAuthSession: ASWebAuthenticationSession?

    init(
        configuration: SpotifyConfiguration,
        keychain: KeychainServicing = KeychainService(),
        urlSession: URLSession = .shared
    ) {
        self.configuration = configuration
        self.keychain = keychain
        self.urlSession = urlSession
        super.init()
    }

    // MARK: - Sitzung wiederherstellen

    func restoreSession() async {
        guard let token = loadStoredToken() else {
            state = .signedOut
            return
        }
        if token.isValid {
            state = .signedIn
            return
        }
        guard token.refreshToken != nil else {
            state = .signedOut
            return
        }
        do {
            _ = try await refreshAccessToken()
            state = .signedIn
        } catch {
            AppLog.debugOnly(AppLog.auth, "Sitzungswiederherstellung fehlgeschlagen: \(error)")
            state = .signedOut
        }
    }

    // MARK: - Anmeldung starten (Authorization Code + PKCE)

    func beginAuthorization() async throws {
        guard let redirectURL = configuration.redirectURL, let scheme = redirectURL.scheme else {
            state = .error(.redirectURIMismatch)
            throw DemonicError.redirectURIMismatch
        }

        state = .authorizing
        let verifier = PKCEHelper.generateCodeVerifier()
        let challenge = PKCEHelper.codeChallenge(forVerifier: verifier)
        let requestState = PKCEHelper.generateState()
        let authURL = makeAuthorizationURL(codeChallenge: challenge, state: requestState)

        do {
            let callbackURL = try await presentAuthenticationSession(url: authURL, callbackScheme: scheme)
            try validateState(in: callbackURL, expected: requestState)
            let code = try extractAuthorizationCode(from: callbackURL)
            try await exchangeCodeForToken(code: code, verifier: verifier, redirectURL: redirectURL)
            state = .signedIn
        } catch let error as DemonicError {
            state = .error(error)
            throw error
        } catch {
            let denied = DemonicError.authorizationDenied
            state = .error(denied)
            throw denied
        }
    }

    private func presentAuthenticationSession(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: error ?? DemonicError.authorizationDenied)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.webAuthSession = session
            if !session.start() {
                continuation.resume(throwing: DemonicError.authorizationDenied)
            }
        }
    }

    private func makeAuthorizationURL(codeChallenge: String, state: String) -> URL {
        var components = URLComponents()
        components.scheme = AppConstants.spotifyAccountsBaseURL.scheme
        components.host = AppConstants.spotifyAccountsBaseURL.host
        components.path = AppConstants.spotifyAuthorizePath
        components.queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectUri),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "scope", value: AppConstants.spotifyScopes.joined(separator: " "))
        ]
        return components.url!
    }

    private func validateState(in url: URL, expected: String) throws {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let returnedState = items.first { $0.name == "state" }?.value
        guard returnedState == expected else {
            throw DemonicError.authorizationDenied
        }
    }

    private func extractAuthorizationCode(from url: URL) throws -> String {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        if let errorValue = items.first(where: { $0.name == "error" })?.value {
            AppLog.debugOnly(AppLog.auth, "Spotify-Autorisierung abgelehnt: \(errorValue)")
            throw DemonicError.authorizationDenied
        }
        guard let code = items.first(where: { $0.name == "code" })?.value else {
            throw DemonicError.authorizationDenied
        }
        return code
    }

    // MARK: - Token-Austausch (ohne Client Secret)

    private func exchangeCodeForToken(code: String, verifier: String, redirectURL: URL) async throws {
        var bodyItems = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURL.absoluteString,
            "client_id": configuration.clientId,
            "code_verifier": verifier
        ]
        let response = try await performTokenRequest(bodyItems: &bodyItems)
        try store(response: response, fallbackRefreshToken: nil)
    }

    func refreshAccessToken() async throws -> AuthToken {
        guard let refreshToken = keychain.string(forKey: AppConstants.KeychainKeys.refreshToken) else {
            throw DemonicError.tokenRefreshFailed
        }
        var bodyItems = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": configuration.clientId
        ]
        do {
            let response = try await performTokenRequest(bodyItems: &bodyItems)
            try store(response: response, fallbackRefreshToken: refreshToken)
        } catch {
            throw DemonicError.tokenRefreshFailed
        }
        guard let token = loadStoredToken() else { throw DemonicError.tokenRefreshFailed }
        return token
    }

    private func performTokenRequest(bodyItems: inout [String: String]) async throws -> SpotifyTokenResponse {
        var request = URLRequest(url: AppConstants.spotifyAccountsBaseURL.appendingPathComponent(AppConstants.spotifyTokenPath))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyItems
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, urlResponse) = try await urlSession.data(for: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw DemonicError.unknown("Keine HTTP-Antwort")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            AppLog.debugOnly(AppLog.auth, "Token-Anfrage fehlgeschlagen mit Status \(httpResponse.statusCode)")
            if httpResponse.statusCode == 429 { throw DemonicError.rateLimited }
            throw DemonicError.tokenRefreshFailed
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(SpotifyTokenResponse.self, from: data)
    }

    private func store(response: SpotifyTokenResponse, fallbackRefreshToken: String?) throws {
        let expiryDate = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        try keychain.set(response.accessToken, forKey: AppConstants.KeychainKeys.accessToken)
        if let refreshToken = response.refreshToken ?? fallbackRefreshToken {
            try keychain.set(refreshToken, forKey: AppConstants.KeychainKeys.refreshToken)
        }
        try keychain.set(ISO8601DateFormatter().string(from: expiryDate), forKey: AppConstants.KeychainKeys.tokenExpiryDate)
        try keychain.set(response.scope ?? "", forKey: AppConstants.KeychainKeys.scope)
    }

    // MARK: - Gültiger Access Token / Status

    func validAccessToken() async throws -> String {
        guard let token = loadStoredToken() else {
            state = .signedOut
            throw DemonicError.spotifyAccountNotConnected
        }
        if token.isValid {
            return token.accessToken
        }
        let refreshed = try await refreshAccessToken()
        state = .signedIn
        return refreshed.accessToken
    }

    func loadStoredToken() -> AuthToken? {
        guard let accessToken = keychain.string(forKey: AppConstants.KeychainKeys.accessToken),
              let expiryString = keychain.string(forKey: AppConstants.KeychainKeys.tokenExpiryDate),
              let expiryDate = ISO8601DateFormatter().date(from: expiryString) else {
            return nil
        }
        let refreshToken = keychain.string(forKey: AppConstants.KeychainKeys.refreshToken)
        let scope = keychain.string(forKey: AppConstants.KeychainKeys.scope) ?? ""
        return AuthToken(accessToken: accessToken, refreshToken: refreshToken, expiryDate: expiryDate, scope: scope)
    }

    // MARK: - Abmelden

    func logout() {
        keychain.removeAll(keys: [
            AppConstants.KeychainKeys.accessToken,
            AppConstants.KeychainKeys.refreshToken,
            AppConstants.KeychainKeys.tokenExpiryDate,
            AppConstants.KeychainKeys.scope
        ])
        state = .signedOut
    }
}

extension SpotifyAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        #if canImport(UIKit)
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window ?? ASPresentationAnchor()
        #else
        return ASPresentationAnchor()
        #endif
    }
}

private struct SpotifyTokenResponse: Decodable {
    let accessToken: String
    let tokenType: String?
    let scope: String?
    let expiresIn: Int
    let refreshToken: String?
}

private extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return allowed
    }()
}
