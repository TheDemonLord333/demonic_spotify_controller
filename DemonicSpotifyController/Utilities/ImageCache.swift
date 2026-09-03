//
//  ImageCache.swift
//  DemonicSpotifyController
//
//  Einfacher, asynchroner Bild-Lader mit Memory- und Disk-Cache für
//  Spotify-Cover. Verändert die geladenen Bilder farblich nicht.
//

import Foundation
import UIKit

actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let diskCacheDirectory: URL

    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = caches.appendingPathComponent("DemonicCoverCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        memoryCache.countLimit = 200
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }
        let diskURL = diskCacheDirectory.appendingPathComponent(cacheFileName(for: url))
        if let diskData = try? Data(contentsOf: diskURL), let diskImage = UIImage(data: diskData) {
            memoryCache.setObject(diskImage, forKey: url as NSURL)
            return diskImage
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
              let image = UIImage(data: data) else {
            throw DemonicError.coverImageUnavailable
        }
        memoryCache.setObject(image, forKey: url as NSURL)
        try? data.write(to: diskURL)
        return image
    }

    private func cacheFileName(for url: URL) -> String {
        String(url.absoluteString.hashValue)
    }
}
