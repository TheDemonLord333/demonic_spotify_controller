//
//  SpotifyWebAPIService.swift
//  DemonicSpotifyController
//
//  Reiner REST-Client für die Spotify Web API (Suche, Metadaten, Cover,
//  eigene Playlists). Steuert niemals die Wiedergabe – dafür ist
//  ausschließlich SpotifyAppRemoteService zuständig.
//

import Foundation

protocol SpotifyWebAPIServicing {
    func fetchMetadata(for reference: ParsedSpotifyReference) async throws -> SpotifyContentMetadata
    func searchPlaylists(query: String) async throws -> [SpotifySearchResultItem]
    func searchAlbums(query: String) async throws -> [SpotifySearchResultItem]
    func fetchCurrentUserPlaylists() async throws -> [SpotifySearchResultItem]
}

final class SpotifyWebAPIService: SpotifyWebAPIServicing {
    private let urlSession: URLSession
    private let accessTokenProvider: () async throws -> String

    init(urlSession: URLSession = .shared, accessTokenProvider: @escaping () async throws -> String) {
        self.urlSession = urlSession
        self.accessTokenProvider = accessTokenProvider
    }

    func fetchMetadata(for reference: ParsedSpotifyReference) async throws -> SpotifyContentMetadata {
        switch reference.type {
        case .playlist:
            var components = URLComponents(
                url: AppConstants.spotifyWebAPIBaseURL.appendingPathComponent("playlists/\(reference.id)"),
                resolvingAgainstBaseURL: false
            )!
            components.queryItems = [
                URLQueryItem(name: "fields", value: "id,uri,name,images,owner.display_name,tracks.total")
            ]
            let request = try await authorizedRequest(components.url!)
            let dto: PlaylistDTO = try await perform(request)
            return SpotifyContentMetadata(
                spotifyID: dto.id, uri: dto.uri, type: .playlist, name: dto.name,
                coverImageURLString: dto.images?.first?.url,
                artistOrOwner: dto.owner?.displayName, trackCount: dto.tracks?.total
            )
        case .album:
            let url = AppConstants.spotifyWebAPIBaseURL.appendingPathComponent("albums/\(reference.id)")
            let request = try await authorizedRequest(url)
            let dto: AlbumDTO = try await perform(request)
            return SpotifyContentMetadata(
                spotifyID: dto.id, uri: dto.uri, type: .album, name: dto.name,
                coverImageURLString: dto.images?.first?.url,
                artistOrOwner: dto.artists?.first?.name, trackCount: dto.totalTracks
            )
        }
    }

    func searchPlaylists(query: String) async throws -> [SpotifySearchResultItem] {
        try await search(query: query, type: .playlist)
    }

    func searchAlbums(query: String) async throws -> [SpotifySearchResultItem] {
        try await search(query: query, type: .album)
    }

    func fetchCurrentUserPlaylists() async throws -> [SpotifySearchResultItem] {
        var components = URLComponents(
            url: AppConstants.spotifyWebAPIBaseURL.appendingPathComponent("me/playlists"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "limit", value: "50")]
        let request = try await authorizedRequest(components.url!)
        let dto: UserPlaylistsResponse = try await perform(request)
        return dto.items.compactMap { item in
            guard let item else { return nil }
            return SpotifySearchResultItem(
                spotifyID: item.id, uri: item.uri, type: .playlist, name: item.name,
                coverImageURLString: item.images?.first?.url, artistOrOwner: item.owner?.displayName
            )
        }
    }

    // MARK: - Suche

    private func search(query: String, type: SpotifyContentType) async throws -> [SpotifySearchResultItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(
            url: AppConstants.spotifyWebAPIBaseURL.appendingPathComponent("search"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "type", value: type.rawValue),
            URLQueryItem(name: "limit", value: "20")
        ]
        let request = try await authorizedRequest(components.url!)

        switch type {
        case .playlist:
            let dto: PlaylistSearchResponse = try await perform(request)
            return (dto.playlists?.items ?? []).compactMap { item in
                guard let item else { return nil }
                return SpotifySearchResultItem(
                    spotifyID: item.id, uri: item.uri, type: .playlist, name: item.name,
                    coverImageURLString: item.images?.first?.url, artistOrOwner: item.owner?.displayName
                )
            }
        case .album:
            let dto: AlbumSearchResponse = try await perform(request)
            return (dto.albums?.items ?? []).compactMap { item in
                guard let item else { return nil }
                return SpotifySearchResultItem(
                    spotifyID: item.id, uri: item.uri, type: .album, name: item.name,
                    coverImageURLString: item.images?.first?.url, artistOrOwner: item.artists?.first?.name
                )
            }
        }
    }

    // MARK: - HTTP-Hilfsfunktionen

    private func authorizedRequest(_ url: URL) async throws -> URLRequest {
        let token = try await accessTokenProvider()
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
            throw DemonicError.noInternet
        } catch {
            throw DemonicError.unknown(String(describing: error))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DemonicError.unknown("Keine HTTP-Antwort")
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw DemonicError.accessTokenExpired
        case 403:
            throw DemonicError.contentPrivateOrInaccessible
        case 404:
            throw DemonicError.contentNotFound
        case 429:
            throw DemonicError.rateLimited
        default:
            throw DemonicError.unknown("Spotify Web API Status \(httpResponse.statusCode)")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            AppLog.debugOnly(AppLog.webAPI, "Decodierfehler: \(error)")
            throw DemonicError.unknown("Antwort konnte nicht gelesen werden")
        }
    }
}

// MARK: - DTOs (nur die tatsächlich benötigten Felder)

private struct ImageDTO: Decodable { let url: String }
private struct OwnerDTO: Decodable {
    let displayName: String?
    enum CodingKeys: String, CodingKey { case displayName = "display_name" }
}
private struct ArtistDTO: Decodable { let name: String }
private struct TracksSummaryDTO: Decodable { let total: Int }

private struct PlaylistDTO: Decodable {
    let id: String
    let uri: String
    let name: String
    let images: [ImageDTO]?
    let owner: OwnerDTO?
    let tracks: TracksSummaryDTO?
}

private struct AlbumDTO: Decodable {
    let id: String
    let uri: String
    let name: String
    let images: [ImageDTO]?
    let artists: [ArtistDTO]?
    let totalTracks: Int?
    enum CodingKeys: String, CodingKey {
        case id, uri, name, images, artists
        case totalTracks = "total_tracks"
    }
}

private struct PlaylistSearchResponse: Decodable {
    struct Page: Decodable { let items: [PlaylistDTO?]? }
    let playlists: Page?
}

private struct AlbumSearchResponse: Decodable {
    struct Page: Decodable { let items: [AlbumDTO?]? }
    let albums: Page?
}

private struct UserPlaylistsResponse: Decodable {
    let items: [PlaylistDTO?]
}
