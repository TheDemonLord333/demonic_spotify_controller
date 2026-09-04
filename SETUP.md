# SETUP – Demonic Spotify Controller

Diese Anleitung beschreibt alle Schritte, um das Projekt lokal zu bauen,
mit Spotify zu verbinden und auf einem echten iPhone zu testen.

## Überblick über die Authentifizierung (wichtig zuerst lesen)

Die App verwendet **Authorization Code Flow mit PKCE** für die
Spotify-Anmeldung (Web API: Suche, Metadaten, Cover, eigene Playlists).
PKCE ist für native/mobile Apps ("public clients") konzipiert und
**benötigt kein Client Secret**. Aus diesem Grund:

- Die iOS-App enthält **kein** Client Secret und benötigt auch keines.
- Es gibt **kein Backend** in diesem Repository, weil keines nötig ist.
- Nur die **Client-ID** ist in `SpotifyConfig.json` hinterlegt – das ist
  laut Spotify unbedenklich, da die Client-ID als öffentlich gilt.

Für die reine Wiedergabesteuerung (Play/Pause/Skip/Shuffle/Repeat der
lokal installierten Spotify-App) wird zusätzlich das offizielle
**Spotify iOS SDK (App Remote)** verwendet. App Remote hat eine eigene,
kurzlebige Autorisierung über `authorizeAndPlayURI`, die ebenfalls ohne
Client Secret auskommt.

> Falls du das Projekt später um serverseitige Funktionen erweiterst, die
> zwingend ein Client Secret benötigen (z. B. Client Credentials Flow für
> rein serverseitige Aufrufe ohne Nutzerkontext), lege dafür ein separates
> Backend an, das ausschließlich `SpotifyServerConfig.json` liest. Diese
> Datei ist bereits in `.gitignore` vorgesehen, existiert aber bewusst
> nicht in diesem Repository, da sie für die App aktuell nicht gebraucht
> wird.

## 1. Spotify Developer Dashboard

1. Öffne https://developer.spotify.com/dashboard und melde dich mit
   deinem Spotify-Konto an.
2. Klicke auf **Create app**.
3. Vergib einen App-Namen (z. B. "Demonic Spotify Controller") und eine
   kurze Beschreibung.
4. Wähle bei "Which API/SDKs are you planning to use?" mindestens
   **Web API** und **iOS** aus.
5. Akzeptiere die Nutzungsbedingungen und erstelle die App.

## 2. Client-ID ermitteln

Nach dem Erstellen findest du auf der App-Übersichtsseite deine
**Client ID**. Kopiere sie – sie kommt in Schritt 6 in
`SpotifyConfig.json`.

Ein Client Secret wird ebenfalls angezeigt, wird von dieser App aber
**nicht verwendet** (siehe oben). Du kannst es ignorieren.

## 3. Redirect-URI im Dashboard eintragen

1. Öffne in deiner App die **Settings**.
2. Trage unter **Redirect URIs** exakt folgenden Wert ein:

   ```
   demonicspotify://callback
   ```

3. Speichere die Einstellungen.

Die Redirect-URI muss **exakt** mit dem Wert in `SpotifyConfig.json`
übereinstimmen (Groß-/Kleinschreibung, Schema, Pfad) – sonst schlägt die
Anmeldung mit einem "redirect_uri_mismatch"-Fehler fehl.

## 4. Bundle Identifier festlegen

Der Bundle Identifier des Xcode-Projekts ist bereits gesetzt auf:

```
me.thedemonlord333.DemonicSpotifyController
```

Falls du ein eigenes Entwicklerkonto/Team verwendest, passe ihn in Xcode
unter **Target → General → Identity** an deine eigene Domain an und
wähle unter **Signing & Capabilities** dein Team aus.

## 5./6./7. SpotifyConfig.json anlegen und Client-ID eintragen

1. Kopiere die Datei
   `DemonicSpotifyController/Configuration/SpotifyConfig.example.json`
   zu `DemonicSpotifyController/Configuration/SpotifyConfig.json`
   (diese Datei ist in `.gitignore` eingetragen und wird **nicht**
   committet).
2. Öffne `SpotifyConfig.json` und trage deine Client-ID ein:

   ```json
   {
     "clientId": "DEINE_ECHTE_CLIENT_ID",
     "redirectUri": "demonicspotify://callback"
   }
   ```

3. Stelle sicher, dass die Datei im Xcode-Projektnavigator im Ordner
   `Configuration` erscheint (der Ordner ist als
   "file system synchronized group" eingebunden – neue Dateien werden
   automatisch erkannt, ein manuelles Hinzufügen ist normalerweise nicht
   nötig).

Ohne eine gültige `SpotifyConfig.json` startet die App automatisch im
**Demo-Modus** mit Mock-Daten (siehe Abschnitt "Im Simulator starten").

## 8. URL Type in Xcode konfigurieren

Das Redirect-URL-Schema ist bereits in
`DemonicSpotifyController/Info.plist` unter `CFBundleURLTypes` als
`demonicspotify` hinterlegt. Falls du ein anderes Schema verwendest,
musst du es dort **und** in `SpotifyConfig.json` konsistent ändern.

Diese `Info.plist` ergänzt gezielt die Schlüssel, die Xcodes
automatisch generierte Info.plist (`GENERATE_INFOPLIST_FILE = YES`)
nicht über Build-Settings abdeckt (Xcode führt beide beim Build
automatisch zusammen).

## 9. Notwendige Info.plist-Einträge

Bereits enthalten in `DemonicSpotifyController/Info.plist`:

- `CFBundleURLTypes` mit dem Schema `demonicspotify` (Redirect-Callback).
- `LSApplicationQueriesSchemes` mit `spotify` (siehe Schritt 10).

## 10. LSApplicationQueriesSchemes

Der Eintrag `spotify` unter `LSApplicationQueriesSchemes` ist bereits
gesetzt. Er ist zwingend erforderlich, damit die App per
`UIApplication.canOpenURL` erkennen kann, ob die Spotify-App installiert
ist, und damit App Remote sowie `authorizeAndPlayURI` funktionieren.

## 11. Spotify iOS SDK einbinden

Das Projekt bindet das offizielle Spotify iOS SDK
(`https://github.com/spotify/ios-sdk`) als `SpotifyiOS.xcframework` ein.
Der gesamte App-Remote-Code ist unabhängig davon, wie das Framework
eingebunden wird, über `#if canImport(SpotifyiOS)` abgesichert: ist das
Framework (noch) nicht vorhanden, kompiliert das Projekt trotzdem und
verwendet automatisch Mock-Verhalten.

**Manuelle Einbindung als lokales Framework (empfohlen, kein Git/Netzwerk
in Xcode nötig):**

Das Repository veröffentlicht keine Versions-Tags und stellt das Framework
nur über Git bereit. Falls die Swift-Package-Manager-Auflösung in Xcode
Probleme macht (z. B. wegen eines defekten lokalen `git`), lässt sich das
`SpotifyiOS.xcframework` stattdessen manuell einbinden:

1. Lade das Framework herunter – entweder als ZIP direkt von Claude (siehe
   Chat) oder manuell über GitHubs Weboberfläche: gehe zu
   `https://github.com/spotify/ios-sdk`, klicke auf **Code → Download ZIP**
   (das nutzt nur HTTPS über den Browser, keinen lokalen `git`-Client) und
   entpacke die ZIP. Der Ordner `SpotifyiOS.xcframework` liegt darin im
   Hauptverzeichnis.
2. Öffne `DemonicSpotifyController.xcodeproj` in Xcode.
3. Ziehe den Ordner `SpotifyiOS.xcframework` per Drag & Drop in den
   Project Navigator, in die Gruppe `DemonicSpotifyController` (auf
   gleicher Ebene wie `App`, `Models`, `Views`, …).
4. Im erscheinenden Dialog: **"Copy items if needed"** aktivieren, unter
   **"Add to targets"** nur das Target `DemonicSpotifyController`
   ankreuzen, dann **Finish**.
5. Öffne **Target → General → Frameworks, Libraries, and Embedded
   Content**. `SpotifyiOS.xcframework` sollte dort erscheinen – stelle
   den Wert in der Spalte **Embed** auf **"Embed & Sign"** (das Framework
   ist eine dynamische Bibliothek und muss ins App-Bundle eingebettet
   werden, sonst startet die App auf dem Gerät nicht).
6. Baue das Projekt (⌘B).

**Alternative: Swift Package Manager**

Falls dein lokales `git` einwandfrei funktioniert, kannst du das SDK
stattdessen ganz normal als Swift-Package-Abhängigkeit hinzufügen:
**File → Add Package Dependencies…**, URL `https://github.com/spotify/ios-sdk`
eingeben, als Dependency Rule **"Exact Commit"**
(`8d3a71dc25282072f8aa8bb0611cea2324e18f28`, Stand des `master`-Branches
zum Zeitpunkt der Erstellung dieses Projekts) oder **"Branch" → master**
wählen, Produkt `SpotifyiOS` zum Target `DemonicSpotifyController`
hinzufügen. Beide Wege (lokales Framework oder SPM) funktionieren mit
demselben Code – verwende nicht beide gleichzeitig für dasselbe Target.

## 12./13./14./15. Auf einem echten iPhone testen

App Remote und die eigentliche Spotify-Wiedergabe funktionieren **nicht
im Simulator** (dort ist keine Spotify-App installierbar). Für den
vollständigen Test:

1. Verbinde ein echtes iPhone mit deinem Mac und wähle es in Xcode als
   Ziel aus.
2. Baue und installiere die App auf dem Gerät (⌘R). Bei Bedarf unter
   **Einstellungen → Allgemein → VPN & Geräteverwaltung** dem
   Entwicklerprofil vertrauen.
3. Installiere die offizielle Spotify-App aus dem App Store auf demselben
   Gerät und melde dich dort mit deinem Spotify-Konto an.
4. Öffne die Demonic Spotify Controller App, tippe auf
   **"Mit Spotify verbinden"** und schließe die Anmeldung ab (Authorization
   Code + PKCE über ein System-Anmeldefenster).
5. Füge über den Plus-Button eine Playlist oder ein Album hinzu und
   tippe auf die Kachel. Falls App Remote noch nicht verbunden ist, wird
   kurz zu Spotify gewechselt (`authorizeAndPlayURI`) und automatisch
   wieder zurückgeleitet.

## Im Simulator starten (Demo-Modus mit Mock-Daten)

Das Projekt lässt sich **ohne** gültige `SpotifyConfig.json` und ohne
Spotify-Konto im Simulator starten:

- Fehlt `SpotifyConfig.json` oder enthält sie noch Platzhalterwerte,
  erkennt `SpotifyConfigurationLoader` dies und die App verwendet
  automatisch `MockSpotifyAuthService`, `MockSpotifyAppRemoteService`
  und `MockSpotifyWebAPIService` mit realistischen Beispieldaten
  (`MockData/SampleData.swift`).
- Die komplette Oberfläche (Kachelübersicht, Hinzufügen-Dialog, Now
  Playing) ist damit ohne echte Spotify-Anmeldung erkundbar.
- Ein Hinweis "Demo-Modus" erscheint im Header und in den Einstellungen.

## Bekannte technische Einschränkungen

- **Kein vollständig unsichtbarer App-Wechsel**: iOS erlaubt es keiner
  App, eine andere App vollständig unsichtbar im Hintergrund zu
  autorisieren. Ist App Remote noch nicht verbunden, wechselt iOS kurz
  sichtbar zu Spotify (offizieller `authorizeAndPlayURI`-Ablauf) und
  leitet danach automatisch über die Redirect-URI zurück. Das ist eine
  von Apple/Spotify vorgegebene Plattformgrenze, kein Implementierungsfehler.
- **App Remote nur mit installierter Spotify-App**: Ohne installierte
  Spotify-App ist keine Wiedergabesteuerung möglich (offizielle
  Einschränkung von App Remote).
- **Wiedergabefortschritt**: Der angezeigte Fortschrittsbalken basiert auf
  den von App Remote gemeldeten Player-State-Updates. App Remote sendet
  diese bei Statusänderungen (Play/Pause/Track-Wechsel/Seek), nicht als
  kontinuierlichen Sekundentakt – der Balken kann daher zwischen zwei
  Updates leicht hinter der tatsächlichen Wiedergabe zurückbleiben.
- **Spotify-SDK ohne Versions-Tags**: `spotify/ios-sdk` veröffentlicht
  aktuell keine SemVer-Tags. Das Projekt bindet das SDK deshalb standardmäßig
  als lokales `SpotifyiOS.xcframework` ein (siehe Schritt 11) statt als
  Swift-Package-Abhängigkeit, um von Git-/Netzwerkproblemen bei der
  Paketauflösung unabhängig zu sein. Prüfe bei einem SDK-Update, ob
  inzwischen ein stabiler Tag verfügbar ist.
- **Premium-Funktionen**: Manche Wiedergabefunktionen (z. B. On-Demand-
  Wiedergabe bestimmter Inhalte) setzen laut Spotify ein Premium-Konto
  voraus. Die App zeigt in diesem Fall die Fehlermeldung "Dein
  Spotify-Konto oder -Tarif erlaubt diese Funktion nicht" an.

## Projektstruktur

```
DemonicSpotifyController/
  App/                     App-Einstiegspunkt, Kompositionswurzel
  Models/                  SwiftData-Modell, DTOs, Fehler-Enum
  Views/                   SwiftUI-Bildschirme
  ViewModels/              MVVM-ViewModels
  Components/              Wiederverwendbare SwiftUI-Bausteine
  Services/
    Spotify/               App Remote, Web API, Parser, Coordinator
    Authentication/        PKCE-Login, Keychain
    Persistence/           (SwiftData wird direkt über ModelContext genutzt)
  DesignSystem/             Farben, Typografie, Glow-/Partikeleffekte
  Utilities/                Logger, Bildcache, Konstanten
  Configuration/            SpotifyConfiguration + Loader + JSON-Dateien
  MockData/                 Mocks & Beispieldaten für Previews/Simulator
DemonicSpotifyControllerTests/   Unit Tests (Swift Testing)
```

## Tests ausführen

In Xcode: **Product → Test** (⌘U). Die Tests laufen ohne Spotify-Konto
und ohne Netzwerkzugriff (Mocks/In-Memory-SwiftData/temporäre Bundles).
