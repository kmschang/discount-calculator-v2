//
//  ThemeEnvironment.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .defaultTheme
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}
