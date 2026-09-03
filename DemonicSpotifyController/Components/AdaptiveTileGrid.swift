//
//  AdaptiveTileGrid.swift
//  DemonicSpotifyController
//
//  Adaptives Grid, das die Spaltenzahl aus der tatsächlich verfügbaren
//  Breite ableitet – keine feste Liste einzelner Gerätemodelle.
//

import SwiftUI

struct AdaptiveTileGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var minimumTileWidth: CGFloat = 150
    let content: (Item) -> Content

    var body: some View {
        GeometryReader { proxy in
            let columns = columnCount(for: proxy.size.width)
            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: DemonicTheme.standardSpacing),
                        count: columns
                    ),
                    spacing: DemonicTheme.standardSpacing
                ) {
                    ForEach(items) { item in
                        content(item)
                    }
                }
                .padding(DemonicTheme.standardSpacing)
                .padding(.bottom, 90) // Platz für den Now-Playing-Player
            }
        }
    }

    private func columnCount(for width: CGFloat) -> Int {
        max(2, Int(width / minimumTileWidth))
    }
}
