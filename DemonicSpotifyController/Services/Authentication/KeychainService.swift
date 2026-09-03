//
//  KeychainService.swift
//  DemonicSpotifyController
//
//  Sicherer Speicher für Access Token, Refresh Token und Ablaufdatum.
//  Verwendet ausschließlich die Keychain – niemals UserDefaults.
//

import Foundation
import Security

protocol KeychainServicing {
    func set(_ value: String, forKey key: String) throws
    func string(forKey key: String) -> String?
    func removeValue(forKey key: String)
    func removeAll(keys: [String])
}

enum KeychainError: LocalizedError {
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        "Auf die Keychain konnte nicht zugegriffen werden."
    }
}

/// Dünner, generischer Wrapper um die Security-Framework-Keychain-APIs.
final class KeychainService: KeychainServicing {
    private let service: String

    init(service: String = Bundle.main.bundleIdentifier ?? "DemonicSpotifyController") {
        self.service = service
    }

    func set(_ value: String, forKey key: String) throws {
        let data = Data(value.utf8)
        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let deleteStatus = SecItemDelete(baseQuery(forKey: key) as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(deleteStatus)
        }

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unexpectedStatus(addStatus)
        }
    }

    func string(forKey key: String) -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func removeValue(forKey key: String) {
        SecItemDelete(baseQuery(forKey: key) as CFDictionary)
    }

    func removeAll(keys: [String]) {
        keys.forEach { removeValue(forKey: $0) }
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
    }
}
