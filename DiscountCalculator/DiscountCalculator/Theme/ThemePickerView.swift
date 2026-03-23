//
//  ThemePickerView.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            ForEach(Themes.allThemes) { theme in
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.accentColor(for: colorScheme))
                        .frame(width: 40, height: 40)

                    Text(theme.name)
                        .foregroundColor(theme.accentColor(for: colorScheme))
                    
                    Spacer()
                    
                    if theme == themeManager.currentTheme {
                        Image(systemName: "checkmark")
                            .foregroundColor(theme.accentColor(for: colorScheme))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    themeManager.updateTheme(theme)
                }
            }
        }
        .navigationTitle("Select Theme")
    }
}
