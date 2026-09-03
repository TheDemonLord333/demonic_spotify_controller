//
//  Logger.swift
//  DemonicSpotifyController
//
//  Dünner Wrapper um os.Logger. Protokolliert Details ausschließlich in
//  Debug-Builds. Tokens, Codes oder andere Zugangsdaten dürfen NIEMALS
//  über diesen Logger ausgegeben werden.
//

import Foundation
import os

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "DemonicSpotifyController"

    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let appRemote = Logger(subsystem: subsystem, category: "AppRemote")
    static let webAPI = Logger(subsystem: subsystem, category: "WebAPI")
    static let playback = Logger(subsystem: subsystem, category: "Playback")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let config = Logger(subsystem: subsystem, category: "Configuration")
    static let general = Logger(subsystem: subsystem, category: "General")

    /// Protokolliert eine Nachricht nur in Debug-Builds. Niemals mit Token-/Secret-Werten aufrufen.
    static func debugOnly(_ logger: Logger, _ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }
}
