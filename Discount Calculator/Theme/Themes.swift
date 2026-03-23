//
//  Themes.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

struct Themes {
    static let allThemes: [AppTheme] = [
        .defaultTheme,
        AppTheme(
            name: "Ocean Blue",
            lightAccentHex: "#0077FF",
            lightBackgroundHex: "#E0F7FF",
            darkAccentHex: "#3399FF",
            darkBackgroundHex: "#101A26"
        ),
        AppTheme(
            name: "Army Green",
            lightAccentHex: "#4B5320",
            lightBackgroundHex: "#F5F5DC",
            darkAccentHex: "#6B8E23",
            darkBackgroundHex: "#222212"
        )
    ]
}
