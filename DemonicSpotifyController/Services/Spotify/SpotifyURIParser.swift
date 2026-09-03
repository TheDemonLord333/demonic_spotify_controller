//
//  SpotifyURIParser.swift
//  DemonicSpotifyController
//
//  Erkennt Spotify-Links und Spotify-URIs für Playlists und Alben,
//  entfernt dabei automatisch Tracking-/Sitzungsparameter wie `si` oder
//  `utm_source` (diese stehen ohnehin nur in der Query, die beim Parsen
//  über den URL-Pfad nicht berücksichtigt wird).
//

import Foundation

struct ParsedSpotifyReference: Equatable {
    let type: SpotifyContentType
    let id: String
    var uri: String { "spotify:\(type.rawValue):\(id)" }
}

enum SpotifyLinkParsingError: LocalizedError, Equatable {
    case emptyInput
    case invalidLink
    case unsupportedContentType(String)
    case missingID

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Bitte gib einen Spotify-Link oder eine Spotify-URI ein."
        case .invalidLink:
            return DemonicError.invalidSpotifyLink.errorDescription
        case .unsupportedContentType(let type):
            return "Der Inhaltstyp \"\(type)\" wird nicht unterstützt. Nur Playlists und Alben können hinzugefügt werden."
        case .missingID:
            return "In diesem Link/dieser URI konnte keine Spotify-ID gefunden werden."
        }
    }
}

enum SpotifyURIParser {

    /// Verarbeitet sowohl Weblinks (`https://open.spotify.com/playlist/...`)
    /// als auch native URIs (`spotify:playlist:...`).
    static func parse(_ raw: String) -> Result<ParsedSpotifyReference, SpotifyLinkParsingError> {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .failure(.emptyInput) }

        if trimmed.lowercased().hasPrefix("spotify:") {
            return parseURI(trimmed)
        }
        return parseWebLink(trimmed)
    }

    private static func parseURI(_ uri: String) -> Result<ParsedSpotifyReference, SpotifyLinkParsingError> {
        // Erwartetes Format: spotify:playlist:<id> bzw. spotify:album:<id>
        let components = uri.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
        guard components.count >= 3 else { return .failure(.invalidLink) }

        let typeToken = components[1].lowercased()
        let idToken = components[2].split(separator: "?", maxSplits: 1).first.map(String.init) ?? components[2]

        guard let type = SpotifyContentType(rawValue: typeToken) else {
            return .failure(.unsupportedContentType(typeToken))
        }
        guard !idToken.isEmpty else { return .failure(.missingID) }
        return .success(ParsedSpotifyReference(type: type, id: idToken))
    }

    private static func parseWebLink(_ link: String) -> Result<ParsedSpotifyReference, SpotifyLinkParsingError> {
        guard let url = URL(string: link),
              let host = url.host?.lowercased(),
              host.contains("spotify.com") else {
            return .failure(.invalidLink)
        }

        // url.pathComponents enthält keine Query-Parameter (si, utm_source, ...) –
        // diese werden dadurch automatisch verworfen.
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard pathComponents.count >= 2 else { return .failure(.invalidLink) }

        let typeToken = pathComponents[pathComponents.count - 2].lowercased()
        let idToken = pathComponents[pathComponents.count - 1]

        guard let type = SpotifyContentType(rawValue: typeToken) else {
            return .failure(.unsupportedContentType(typeToken))
        }
        guard !idToken.isEmpty else { return .failure(.missingID) }
        return .success(ParsedSpotifyReference(type: type, id: idToken))
    }
}
