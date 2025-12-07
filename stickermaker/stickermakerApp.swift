//
//  stickermakerApp.swift
//  stickermaker
//
//  Created by jihong on 12/4/25.
//

import SwiftUI

@main
struct stickermakerApp: App {
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
        }
    }
}
