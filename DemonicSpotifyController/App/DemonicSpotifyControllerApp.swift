//
//  DemonicSpotifyControllerApp.swift
//  DemonicSpotifyController
//

import SwiftUI
import SwiftData

@main
struct DemonicSpotifyControllerApp: App {
    @State private var environment = AppEnvironment.bootstrap()
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedSpotifyItem.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("SwiftData-ModelContainer konnte nicht erstellt werden: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(environment: environment)
                .task {
                    await environment.authService.restoreSession()
                }
                .onOpenURL { url in
                    // Deckt sowohl den PKCE-Web-Login-Callback als auch den
                    // App-Remote-Autorisierungs-Callback (authorizeAndPlayURI) ab.
                    environment.playbackCoordinator.handleOpenURL(url)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    guard newPhase == .active else { return }
                    environment.playbackCoordinator.handleSceneBecameActive()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
