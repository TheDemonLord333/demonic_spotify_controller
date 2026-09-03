//
//  MockKeychainService.swift
//  DemonicSpotifyController
//
//  In-Memory-Ersatz für KeychainService, verwendet in Tests und Previews.
//

import Foundation

final class MockKeychainService: KeychainServicing {
    private var storage: [String: String] = [:]

    func set(_ value: String, forKey key: String) throws {
        storage[key] = value
    }

    func string(forKey key: String) -> String? {
        storage[key]
    }

    func removeValue(forKey key: String) {
        storage.removeValue(forKey: key)
    }

    func removeAll(keys: [String]) {
        keys.forEach { storage.removeValue(forKey: $0) }
    }
}
