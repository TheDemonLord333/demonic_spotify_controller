//
//  SettingsView.swift
//  DemonicSpotifyController
//
//  Konto- und Verbindungsstatus sowie Abmelden.
//

import SwiftUI

struct SettingsView: View {
    let environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var showingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicBackground()
                List {
                    Section("Spotify-Konto") {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(accountStatusText).foregroundStyle(DemonicPalette.textSecondary)
                        }
                        HStack {
                            Text("App Remote")
                            Spacer()
                            ConnectionStatusView(status: environment.playbackCoordinator.connectionStatus)
                        }
                        if environment.isDemoMode {
                            Text(environment.configurationError?.errorDescription ?? "Demo-Modus aktiv")
                                .font(.caption)
                                .foregroundStyle(DemonicPalette.emberOrange)
                        }
                    }
                    .listRowBackground(DemonicPalette.smokeGlass)

                    Section {
                        Button(role: .destructive) {
                            showingLogoutConfirmation = true
                        } label: {
                            Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .disabled(environment.isDemoMode)
                    }
                    .listRowBackground(DemonicPalette.smokeGlass)

                    Section("Über") {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(appVersion).foregroundStyle(DemonicPalette.textSecondary)
                        }
                    }
                    .listRowBackground(DemonicPalette.smokeGlass)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .confirmationDialog("Wirklich abmelden?", isPresented: $showingLogoutConfirmation, titleVisibility: .visible) {
                Button("Abmelden", role: .destructive) {
                    environment.authService.logout()
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            }
        }
    }

    private var accountStatusText: String {
        switch environment.authService.state {
        case .signedIn: return "Verbunden"
        case .signedOut: return "Nicht verbunden"
        case .authorizing: return "Verbinde …"
        case .error: return "Fehler"
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return version
    }
}
