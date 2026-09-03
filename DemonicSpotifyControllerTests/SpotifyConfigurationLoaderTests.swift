//
//  SpotifyConfigurationLoaderTests.swift
//  DemonicSpotifyControllerTests
//

import Testing
import Foundation
@testable import DemonicSpotifyController

struct SpotifyConfigurationLoaderTests {

    private func makeBundle(withJSON json: String?, fileName: String = "SpotifyConfig.json") throws -> Bundle {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let json {
            try json.write(to: directory.appendingPathComponent(fileName), atomically: true, encoding: .utf8)
        }
        return Bundle(path: directory.path) ?? Bundle()
    }

    @Test func loadsValidConfiguration() throws {
        let bundle = try makeBundle(withJSON: """
        { "clientId": "abc123", "redirectUri": "demonicspotify://callback" }
        """)
        let loader = SpotifyConfigurationLoader(bundle: bundle, resourceName: "SpotifyConfig")
        let config = try loader.loadConfiguration().get()
        #expect(config.clientId == "abc123")
        #expect(config.redirectUri == "demonicspotify://callback")
    }

    @Test func reportsMissingFile() throws {
        let bundle = try makeBundle(withJSON: nil)
        let loader = SpotifyConfigurationLoader(bundle: bundle, resourceName: "SpotifyConfig")
        #expect(throws: SpotifyConfigurationError.fileNotFound) {
            try loader.loadConfiguration().get()
        }
    }

    @Test func reportsPlaceholderClientId() throws {
        let bundle = try makeBundle(withJSON: """
        { "clientId": "DEINE_SPOTIFY_CLIENT_ID", "redirectUri": "demonicspotify://callback" }
        """)
        let loader = SpotifyConfigurationLoader(bundle: bundle, resourceName: "SpotifyConfig")
        #expect(throws: SpotifyConfigurationError.placeholderClientId) {
            try loader.loadConfiguration().get()
        }
    }

    @Test func reportsMissingClientId() throws {
        let bundle = try makeBundle(withJSON: """
        { "clientId": "", "redirectUri": "demonicspotify://callback" }
        """)
        let loader = SpotifyConfigurationLoader(bundle: bundle, resourceName: "SpotifyConfig")
        #expect(throws: SpotifyConfigurationError.missingClientId) {
            try loader.loadConfiguration().get()
        }
    }

    @Test func reportsInvalidRedirectUri() throws {
        let bundle = try makeBundle(withJSON: """
        { "clientId": "abc123", "redirectUri": "" }
        """)
        let loader = SpotifyConfigurationLoader(bundle: bundle, resourceName: "SpotifyConfig")
        #expect(throws: SpotifyConfigurationError.missingRedirectUri) {
            try loader.loadConfiguration().get()
        }
    }

    @Test func reportsMalformedJSON() throws {
        let bundle = try makeBundle(withJSON: "{ not valid json ")
        let loader = SpotifyConfigurationLoader(bundle: bundle, resourceName: "SpotifyConfig")
        let result = loader.loadConfiguration()
        guard case .failure(.malformedJSON) = result else {
            Issue.record("Erwartete malformedJSON-Fehler, erhielt \(result)")
            return
        }
    }
}

extension SpotifyConfigurationError: Equatable {
    public static func == (lhs: SpotifyConfigurationError, rhs: SpotifyConfigurationError) -> Bool {
        switch (lhs, rhs) {
        case (.fileNotFound, .fileNotFound),
             (.missingClientId, .missingClientId),
             (.missingRedirectUri, .missingRedirectUri),
             (.placeholderClientId, .placeholderClientId):
            return true
        case (.invalidRedirectUri(let a), .invalidRedirectUri(let b)):
            return a == b
        default:
            return false
        }
    }
}
