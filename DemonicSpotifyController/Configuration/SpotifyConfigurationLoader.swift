//
//  SpotifyConfigurationLoader.swift
//  DemonicSpotifyController
//
//  Lädt SpotifyConfig.json genau einmal aus dem App-Bundle, validiert sie
//  und stellt das Ergebnis per Dependency Injection für die übrigen
//  Spotify-Dienste bereit. Erkennt fehlende Dateien, leere Werte und nicht
//  ersetzte Platzhalter mit aussagekräftigen Fehlermeldungen.
//

import Foundation

enum SpotifyConfigurationError: LocalizedError {
    case fileNotFound
    case unreadable(underlying: Error)
    case malformedJSON(underlying: Error)
    case missingClientId
    case missingRedirectUri
    case placeholderClientId
    case invalidRedirectUri(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "SpotifyConfig.json wurde nicht im App-Bundle gefunden. Erstelle sie gemäß SETUP.md aus SpotifyConfig.example.json."
        case .unreadable:
            return "SpotifyConfig.json konnte nicht gelesen werden."
        case .malformedJSON:
            return "SpotifyConfig.json enthält kein gültiges JSON."
        case .missingClientId:
            return "SpotifyConfig.json enthält keine clientId."
        case .missingRedirectUri:
            return "SpotifyConfig.json enthält keine redirectUri."
        case .placeholderClientId:
            return "SpotifyConfig.json enthält noch den Platzhalter für clientId. Bitte deine echte Spotify Client-ID eintragen."
        case .invalidRedirectUri(let value):
            return "Die redirectUri \"\(value)\" ist keine gültige URL."
        }
    }
}

protocol SpotifyConfigurationLoading {
    func loadConfiguration() -> Result<SpotifyConfiguration, SpotifyConfigurationError>
}

/// Lädt die Konfiguration aus einer Bundle-Ressource namens `SpotifyConfig.json`.
final class SpotifyConfigurationLoader: SpotifyConfigurationLoading {
    private let bundle: Bundle
    private let resourceName: String

    init(bundle: Bundle = .main, resourceName: String = "SpotifyConfig") {
        self.bundle = bundle
        self.resourceName = resourceName
    }

    /// Lädt und validiert die Konfiguration. Das Ergebnis sollte vom Aufrufer
    /// (typischerweise `AppEnvironment`) genau einmal berechnet und danach
    /// per Dependency Injection weitergereicht werden.
    func loadConfiguration() -> Result<SpotifyConfiguration, SpotifyConfigurationError> {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            AppLog.config.error("SpotifyConfig.json nicht im Bundle gefunden.")
            return .failure(.fileNotFound)
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            AppLog.config.error("SpotifyConfig.json konnte nicht gelesen werden.")
            return .failure(.unreadable(underlying: error))
        }

        let configuration: SpotifyConfiguration
        do {
            configuration = try JSONDecoder().decode(SpotifyConfiguration.self, from: data)
        } catch {
            AppLog.config.error("SpotifyConfig.json ist kein gültiges JSON.")
            return .failure(.malformedJSON(underlying: error))
        }

        let trimmedClientId = configuration.clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedClientId.isEmpty {
            return .failure(.missingClientId)
        }
        if SpotifyConfiguration.placeholderValues.contains(trimmedClientId) {
            return .failure(.placeholderClientId)
        }

        let trimmedRedirect = configuration.redirectUri.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedRedirect.isEmpty {
            return .failure(.missingRedirectUri)
        }
        guard let redirectURL = URL(string: trimmedRedirect), redirectURL.scheme != nil else {
            return .failure(.invalidRedirectUri(trimmedRedirect))
        }

        AppLog.config.info("Spotify-Konfiguration erfolgreich geladen.")
        return .success(configuration)
    }
}
