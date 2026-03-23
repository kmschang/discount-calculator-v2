import SwiftUI

enum DiscountCalculatorLogoAppearance: String {
    case light = "Light"
    case dark = "Dark"
}

func discountCalculatorLogoName(appearance: DiscountCalculatorLogoAppearance, color: String) -> String {
    "DiscountCalculatorLogo(\(appearance.rawValue))(\(color))"
}

func discountCalculatorLogoAppearance(for colorScheme: ColorScheme) -> DiscountCalculatorLogoAppearance {
    colorScheme == .dark ? .dark : .light
}

func discountCalculatorLogoColor(forAppIconName appIconName: String) -> String {
    switch appIconName {
    case "Primary", "BlueAppIcon": return "Blue"
    case "GreenAppIcon": return "Green"
    case "OrangeAppIcon": return "Orange"
    case "PurpleAppIcon": return "Purple"
    case "RedAppIcon": return "Red"
    case "WhiteAppIcon": return "White"
    case "BlackAppIcon": return "Black"
    case "YellowAppIcon": return "Yellow"
    default: return "Blue"
    }
}
