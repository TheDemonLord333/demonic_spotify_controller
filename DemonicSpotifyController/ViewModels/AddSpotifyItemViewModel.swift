//
//  AddSpotifyItemViewModel.swift
//  DemonicSpotifyController
//
//  Logik hinter dem Hinzufügen-Dialog: Link/URI-Vorschau, Suche nach
//  Playlists/Alben sowie Laden der eigenen Playlists.
//

import Foundation
import Observation

@MainActor
@Observable
final class AddSpotifyItemViewModel {
    private let webAPI: SpotifyWebAPIServicing

    var linkInput: String = ""
    var isLoadingPreview = false
    var previewMetadata: SpotifyContentMetadata?
    var previewErrorMessage: String?

    var searchQuery: String = ""
    var searchType: SpotifyContentType = .playlist
    var isSearching = false
    var searchResults: [SpotifySearchResultItem] = []
    var searchErrorMessage: String?

    var ownPlaylists: [SpotifySearchResultItem] = []
    var isLoadingOwnPlaylists = false
    var ownPlaylistsErrorMessage: String?

    init(webAPI: SpotifyWebAPIServicing) {
        self.webAPI = webAPI
    }

    func fetchPreview() async {
        previewErrorMessage = nil
        previewMetadata = nil

        switch SpotifyURIParser.parse(linkInput) {
        case .failure(let error):
            previewErrorMessage = error.localizedDescription
        case .success(let reference):
            isLoadingPreview = true
            defer { isLoadingPreview = false }
            do {
                previewMetadata = try await webAPI.fetchMetadata(for: reference)
            } catch {
                previewErrorMessage = message(for: error)
            }
        }
    }

    func search() async {
        searchErrorMessage = nil
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }
        do {
            searchResults = searchType == .playlist
                ? try await webAPI.searchPlaylists(query: searchQuery)
                : try await webAPI.searchAlbums(query: searchQuery)
        } catch {
            searchResults = []
            searchErrorMessage = message(for: error)
        }
    }

    func loadOwnPlaylists() async {
        guard ownPlaylists.isEmpty else { return }
        isLoadingOwnPlaylists = true
        defer { isLoadingOwnPlaylists = false }
        do {
            ownPlaylists = try await webAPI.fetchCurrentUserPlaylists()
        } catch {
            ownPlaylistsErrorMessage = message(for: error)
        }
    }

    func selectSearchResult(_ result: SpotifySearchResultItem) {
        previewMetadata = SpotifyContentMetadata(
            spotifyID: result.spotifyID, uri: result.uri, type: result.type, name: result.name,
            coverImageURLString: result.coverImageURLString, artistOrOwner: result.artistOrOwner, trackCount: nil
        )
        previewErrorMessage = nil
        linkInput = result.uri
    }

    func reset() {
        linkInput = ""
        previewMetadata = nil
        previewErrorMessage = nil
        searchQuery = ""
        searchResults = []
        searchErrorMessage = nil
    }

    private func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? DemonicError.unknown(nil).localizedDescription
    }
}
