//
//  ContentView.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TabView(selection: $selectedTab) {
            ImprovedStickerMakerTab()
                .tabItem {
                    Label("tab.sticker".localized, systemImage: "photo.badge.plus")
                }
                .tag(0)

            GIFMakerView()
                .tabItem {
                    Label("tab.photo_gif".localized, systemImage: "photo.stack")
                }
                .tag(1)

            VideoToGIFView()
                .tabItem {
                    Label("tab.video_gif".localized, systemImage: "video.badge.waveform")
                }
                .tag(2)

            BackgroundCompositorView()
                .tabItem {
                    Label("tab.background".localized, systemImage: "rectangle.on.rectangle")
                }
                .tag(3)

            StickerPackView()
                .tabItem {
                    Label("tab.sticker_pack".localized, systemImage: "square.grid.3x3")
                }
                .tag(4)
        }
        .environmentObject(themeManager)
    }
}

struct ThemeToggleButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showThemeMenu = false

    var body: some View {
        Button(action: {
            themeManager.toggleTheme()
        }) {
            Image(systemName: themeManager.currentTheme.icon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .background(Color.appCardBackground)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        }
    }
}

struct CheckerboardView: View {
    let squareSize: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            let columns = Int(geometry.size.width / squareSize) + 1
            let rows = Int(geometry.size.height / squareSize) + 1

            Canvas { context, size in
                for row in 0..<rows {
                    for column in 0..<columns {
                        let isEvenRow = row % 2 == 0
                        let isEvenColumn = column % 2 == 0
                        let shouldFill = isEvenRow == isEvenColumn

                        if shouldFill {
                            let rect = CGRect(
                                x: CGFloat(column) * squareSize,
                                y: CGFloat(row) * squareSize,
                                width: squareSize,
                                height: squareSize
                            )
                            context.fill(Path(rect), with: .color(.gray.opacity(0.2)))
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
