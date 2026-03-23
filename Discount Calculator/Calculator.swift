//
//  Calculator.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

struct Calculator: View {
    @Environment(\.appTheme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showSettingsSheet:Bool = false
    
    var body: some View {
        NavigationStack {
            Text("Calculator")
                .tint(theme.accentColor(for: colorScheme))
        }
        .navigationTitle("Discount Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettingsSheet, content: {
            NavigationView {
                ThemePickerView()
            }
        })
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                withAnimation {
                    ZStack {
                        HStack(spacing: 10) {
                            Button {
                                showSettingsSheet = true
                            } label: {
                                Label("Settings", systemImage: "gear")
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    Calculator()
}
