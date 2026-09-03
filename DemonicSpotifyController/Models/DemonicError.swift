//
//  DemonicError.swift
//  DemonicSpotifyController
//
//  Zentrale Fehlerdomäne der App mit benutzerfreundlichen, deutschen
//  Fehlermeldungen. Technische Details landen ausschließlich im Debug-Log,
//  niemals in der angezeigten Nachricht.
//

import Foundation

enum DemonicError: LocalizedError, Equatable, Identifiable {
    case spotifyAppNotInstalled
    case spotifyAccountNotConnected
    case authorizationDenied
    case accessTokenExpired
    case tokenRefreshFailed
    case appRemoteNotConnected
    case spotifyTerminated
    case appSwitchRequired
    case noInternet
    case invalidSpotifyLink
    case invalidSpotifyURI
    case contentNotFound
    case contentPrivateOrInaccessible
    case rateLimited
    case coverImageUnavailable
    case playbackFailed(String? = nil)
    case premiumRequired
    case configurationMissing
    case configurationPlaceholder
    case redirectURIMismatch
    case unknown(String? = nil)

    var id: String { errorDescription ?? "unknown" }

    var errorDescription: String? {
        switch self {
        case .spotifyAppNotInstalled:
            return "Spotify ist auf diesem Gerät nicht installiert. Installiere Spotify, um Inhalte abzuspielen."
        case .spotifyAccountNotConnected:
            return "Es ist kein Spotify-Konto verbunden. Verbinde zuerst dein Spotify-Konto."
        case .authorizationDenied:
            return "Die Spotify-Autorisierung wurde abgelehnt. Bitte versuche es erneut."
        case .accessTokenExpired:
            return "Deine Spotify-Sitzung ist abgelaufen. Sie wird automatisch erneuert."
        case .tokenRefreshFailed:
            return "Die Spotify-Sitzung konnte nicht erneuert werden. Bitte melde dich erneut an."
        case .appRemoteNotConnected:
            return "Keine Verbindung zur Spotify-App. Spotify wird kurz aktiviert."
        case .spotifyTerminated:
            return "Spotify wurde vollständig beendet und muss neu gestartet werden."
        case .appSwitchRequired:
            return "Spotify muss kurz aktiviert werden. Du wirst automatisch zurückgeleitet."
        case .noInternet:
            return "Keine Internetverbindung. Bitte überprüfe dein Netzwerk."
        case .invalidSpotifyLink:
            return "Dieser Spotify-Link konnte nicht erkannt werden."
        case .invalidSpotifyURI:
            return "Diese Spotify-URI ist ungültig."
        case .contentNotFound:
            return "Dieser Inhalt wurde bei Spotify nicht gefunden. Er wurde möglicherweise gelöscht."
        case .contentPrivateOrInaccessible:
            return "Dieser Inhalt ist privat oder für dein Konto nicht zugänglich."
        case .rateLimited:
            return "Spotify erhält gerade zu viele Anfragen. Bitte versuche es in Kürze erneut."
        case .coverImageUnavailable:
            return "Das Cover konnte nicht geladen werden."
        case .playbackFailed(let detail):
            return "Die Wiedergabe konnte nicht gestartet werden." + (detail.map { " (\($0))" } ?? "")
        case .premiumRequired:
            return "Dein Spotify-Konto oder -Tarif erlaubt diese Funktion nicht."
        case .configurationMissing:
            return "Die Spotify-Konfiguration fehlt. Bitte SpotifyConfig.json gemäß SETUP.md anlegen."
        case .configurationPlaceholder:
            return "Die Spotify-Konfiguration enthält noch Platzhalterwerte. Bitte SpotifyConfig.json ausfüllen."
        case .redirectURIMismatch:
            return "Die Redirect-URI stimmt nicht mit der Konfiguration im Spotify Dashboard überein."
        case .unknown(let detail):
            return "Es ist ein unerwarteter Fehler aufgetreten." + (detail.map { " (\($0))" } ?? "")
        }
    }

    /// True für Fehler, bei denen ein kurzer, offiziell unterstützter App-Wechsel zu Spotify
    /// zulässig ist (Autorisierung / Reaktivierung), statt nur eine Fehlermeldung zu zeigen.
    var mayTriggerOfficialSpotifyHandoff: Bool {
        switch self {
        case .spotifyAccountNotConnected, .appRemoteNotConnected, .spotifyTerminated, .appSwitchRequired:
            return true
        default:
            return false
        }
    }
}
