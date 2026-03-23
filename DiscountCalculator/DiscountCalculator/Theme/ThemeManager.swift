//
//  ThemeManager.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

class ThemeManager: ObservableObject {
    private let themeKey = "selectedTheme"
    
    @Published var currentTheme: AppTheme {
        didSet {
            saveTheme()
        }
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: themeKey),
           let loadedTheme = try? JSONDecoder().decode(AppTheme.self, from: data) {
            self.currentTheme = loadedTheme
        } else {
            self.currentTheme = .defaultTheme
        }
    }
    
    func updateTheme(_ theme: AppTheme) {
        currentTheme = theme
    }
    
    private func saveTheme() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            UserDefaults.standard.set(encoded, forKey: themeKey)
        }
    }
}
