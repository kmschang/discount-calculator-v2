//
//  Home.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

struct Home: View {
    @Environment(\.appTheme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme

    
    var body: some View {
        
        TabView {
            NavigationView {
                Calculator()
            }
            .tabItem {
                Label("Today", systemImage: "numbersign")
            }
            Discount()
                .tabItem {
                    Label("Discount", systemImage: "gauge.open.with.lines.needle.33percent")
                }
            Tax()
                .tabItem {
                    Label("Tax", systemImage: "coloncurrencysign.gauge.chart.leftthird.topthird.rightthird")
                }
        }
        
        
    }
}

#Preview {
    Home()
}
