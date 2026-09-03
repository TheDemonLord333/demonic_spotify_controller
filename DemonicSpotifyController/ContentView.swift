//
//  ContentView.swift
//  DemonicSpotifyController
//
//  Wurzel-View: zeigt je nach Anmeldestatus entweder den Connect-Bildschirm
//  oder die Kachelübersicht. Erstellt das LibraryViewModel einmalig mit
//  dem SwiftData-ModelContext aus der Umgebung.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let environment: AppEnvironment

    @Environment(\.modelContext) private var modelContext
    @State private var libraryViewModel: LibraryViewModel?

    var body: some View {
        ZStack {
            DemonicBackground()

            switch environment.authService.state {
            case .signedIn:
                libraryOrLoading
            case .signedOut, .error(_):
                ConnectSpotifyView(environment: environment)
            case .authorizing:
                VStack(spacing: 16) {
                    ProgressView().tint(DemonicPalette.glowingScarlet)
                    Text(DemonicError.appSwitchRequired.errorDescription ?? "")
                        .font(.callout)
                        .foregroundStyle(DemonicPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .task {
            if libraryViewModel == nil {
                libraryViewModel = LibraryViewModel(modelContext: modelContext, playbackCoordinator: environment.playbackCoordinator)
            }
        }
    }

    @ViewBuilder
    private var libraryOrLoading: some View {
        if let libraryViewModel {
            LibraryView(viewModel: libraryViewModel, environment: environment)
        } else {
            ProgressView().tint(DemonicPalette.glowingScarlet)
        }
    }
}

#Preview {
    ContentView(environment: .bootstrap())
        .modelContainer(for: SavedSpotifyItem.self, inMemory: true)
}
