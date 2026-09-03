//
//  TileEditView.swift
//  DemonicSpotifyController
//
//  Bearbeiten von Anzeigename und Kategorie einer gespeicherten Kachel.
//

import SwiftUI

struct TileEditView: View {
    let item: SavedSpotifyItem
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var category: String

    init(item: SavedSpotifyItem, onSave: @escaping (String, String) -> Void) {
        self.item = item
        self.onSave = onSave
        _displayName = State(initialValue: item.localDisplayName ?? item.spotifyName)
        _category = State(initialValue: item.category)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DemonicBackground()
                VStack(spacing: 20) {
                    CoverImageView(url: item.coverImageURL, cornerRadius: 16)
                        .frame(width: 120, height: 120)
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anzeigename").font(.caption).foregroundStyle(DemonicPalette.textSecondary)
                        TextField(item.spotifyName, text: $displayName)
                            .padding(10)
                            .background(DemonicPalette.smokeGlass, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(DemonicPalette.textPrimary)

                        Text("Kategorie").font(.caption).foregroundStyle(DemonicPalette.textSecondary)
                        TextField("z. B. Workout", text: $category)
                            .padding(10)
                            .background(DemonicPalette.smokeGlass, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(DemonicPalette.textPrimary)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Kachel bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        onSave(displayName, category)
                        dismiss()
                    }
                }
            }
        }
    }
}
