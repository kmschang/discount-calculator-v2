//
//  Discount.swift
//  Discount Calculator
//
//  Created by Kyle Schang on 6/8/25.
//

import SwiftUI

struct Discount: View {
    @Environment(\.appTheme) var theme
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Text("Discount")
    }
}

#Preview {
    Discount()
}
