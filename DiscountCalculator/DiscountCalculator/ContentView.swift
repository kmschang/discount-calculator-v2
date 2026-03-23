//
//  ContentView.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.appTheme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Themed App")
                    .font(.largeTitle)
                    .foregroundColor(theme.accentColor(for: colorScheme))
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.backgroundColor(for: colorScheme))
                    .frame(height: 100)
                
                NavigationLink("Change Theme") {
                    ThemePickerView()
                }
                .tint(theme.accentColor(for: colorScheme))
            }
            .padding()
            .background(theme.backgroundColor(for: colorScheme))
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
