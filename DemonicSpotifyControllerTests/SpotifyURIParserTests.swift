//
//  SpotifyURIParserTests.swift
//  DemonicSpotifyControllerTests
//

import Testing
@testable import DemonicSpotifyController

struct SpotifyURIParserTests {

    @Test func parsesPlaylistWebLink() throws {
        let result = SpotifyURIParser.parse("https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M")
        let reference = try result.get()
        #expect(reference.type == .playlist)
        #expect(reference.id == "37i9dQZF1DXcBWIGoYBM5M")
        #expect(reference.uri == "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M")
    }

    @Test func parsesAlbumWebLink() throws {
        let result = SpotifyURIParser.parse("https://open.spotify.com/album/4LH4d3cOWNNsVw41Gqt2kv")
        let reference = try result.get()
        #expect(reference.type == .album)
        #expect(reference.id == "4LH4d3cOWNNsVw41Gqt2kv")
    }

    @Test func stripsTrackingQueryParameters() throws {
        let result = SpotifyURIParser.parse("https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc123&utm_source=copy-link")
        let reference = try result.get()
        #expect(reference.id == "37i9dQZF1DXcBWIGoYBM5M")
    }

    @Test func handlesLocalizedWebLinkPrefix() throws {
        let result = SpotifyURIParser.parse("https://open.spotify.com/intl-de/album/4LH4d3cOWNNsVw41Gqt2kv?si=xyz")
        let reference = try result.get()
        #expect(reference.type == .album)
        #expect(reference.id == "4LH4d3cOWNNsVw41Gqt2kv")
    }

    @Test func parsesNativeURI() throws {
        let result = SpotifyURIParser.parse("spotify:playlist:37i9dQZF1DXcBWIGoYBM5M")
        let reference = try result.get()
        #expect(reference.type == .playlist)
        #expect(reference.id == "37i9dQZF1DXcBWIGoYBM5M")
    }

    @Test func parsesNativeURIWithTrailingQuery() throws {
        let result = SpotifyURIParser.parse("spotify:album:4LH4d3cOWNNsVw41Gqt2kv?si=abc")
        let reference = try result.get()
        #expect(reference.id == "4LH4d3cOWNNsVw41Gqt2kv")
    }

    @Test func rejectsEmptyInput() {
        let result = SpotifyURIParser.parse("   ")
        #expect(throws: SpotifyLinkParsingError.emptyInput) { try result.get() }
    }

    @Test func rejectsUnsupportedContentType() {
        let result = SpotifyURIParser.parse("spotify:track:2takcwOaAZWiXQijPHIx7B")
        switch result {
        case .failure(.unsupportedContentType(let type)):
            #expect(type == "track")
        default:
            Issue.record("Erwartete unsupportedContentType-Fehler, erhielt \(result)")
        }
    }

    @Test func rejectsNonSpotifyLink() {
        let result = SpotifyURIParser.parse("https://example.com/playlist/123")
        #expect(throws: SpotifyLinkParsingError.invalidLink) { try result.get() }
    }

    @Test func rejectsGarbageInput() {
        let result = SpotifyURIParser.parse("not a link at all")
        #expect(throws: SpotifyLinkParsingError.invalidLink) { try result.get() }
    }
}
