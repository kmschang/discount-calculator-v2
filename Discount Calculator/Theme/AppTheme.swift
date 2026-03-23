//
//  AppTheme.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

struct AppTheme: Codable, Equatable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let lightAccentHex: String
    let lightBackgroundHex: String
    let darkAccentHex: String
    let darkBackgroundHex: String
    
    init(
        id: UUID = UUID(),
        name: String,
        lightAccentHex: String,
        lightBackgroundHex: String,
        darkAccentHex: String,
        darkBackgroundHex: String
    ) {
        self.id = id
        self.name = name
        self.lightAccentHex = lightAccentHex
        self.lightBackgroundHex = lightBackgroundHex
        self.darkAccentHex = darkAccentHex
        self.darkBackgroundHex = darkBackgroundHex
    }
    
    func accentColor(for colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? darkAccentHex : lightAccentHex)
    }
    
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        Color(hex: colorScheme == .dark ? darkBackgroundHex : lightBackgroundHex)
    }
    
    static let defaultTheme = AppTheme(
        name: "Classic Red",
        lightAccentHex: "#FF0000",
        lightBackgroundHex: "#FFFFFF",
        darkAccentHex: "#FF5555",
        darkBackgroundHex: "#121212"
    )
}
