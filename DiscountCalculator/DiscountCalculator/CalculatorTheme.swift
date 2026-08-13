import SwiftUI

// MARK: - Theme resolution
// Centralizes the accent-color / appearance logic that the whole app shares,
// matching the Day Calculator theming system (themeColor 1...6 = colors, 7 = mono).

enum AppTheme {
    static func appColorScheme(appearanceMode: Int) -> ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    static func effectiveScheme(appearanceMode: Int, systemScheme: ColorScheme) -> ColorScheme {
        appColorScheme(appearanceMode: appearanceMode) ?? systemScheme
    }

    static func accentColor(themeColor: Int, appearanceMode: Int, systemScheme: ColorScheme) -> Color {
        switch themeColor {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        case 6: return .purple
        case 7:
            return effectiveScheme(appearanceMode: appearanceMode, systemScheme: systemScheme) == .dark ? .white : .black
        default:
            return .accentColor
        }
    }
}

// MARK: - Shared background
// The Day Calculator-style ambient background: a soft gradient with two blurred
// accent/neutral blobs. Used behind every primary screen for a consistent feel.

struct CalculatorBackground: View {
    var accentColor: Color
    var colorScheme: ColorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        ZStack {
            LinearGradient(
                colors: isDark
                    ? [Color.black, Color(red: 0.04, green: 0.05, blue: 0.09)]
                    : [Color(red: 0.94, green: 0.96, blue: 1.0), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(LinearGradient(colors: [accentColor.opacity(0.40), .clear],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -130, y: -300)

            Circle()
                .fill(LinearGradient(colors: [accentColor.opacity(0.22), .clear],
                                     startPoint: .bottomTrailing, endPoint: .topLeading))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 170, y: 300)
        }
    }
}

// MARK: - Glass card
// The reusable "liquid glass" surface. Prefers the iOS 26 glass effect, with a
// material + accent-stroke fallback for older systems.

extension View {
    @ViewBuilder
    func glassCard(accentColor: Color, cornerRadius: CGFloat = 22, emphasized: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular
                    .tint(accentColor.opacity(emphasized ? 0.25 : 0.14))
                    .interactive(),
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(accentColor.opacity(emphasized ? 0.45 : 0.22), lineWidth: 1)
                }
        }
    }
}

// MARK: - Currency helper

enum AppFormat {
    static var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    static var currencySymbol: String {
        Locale.current.currencySymbol ?? "$"
    }

    /// Formats a percentage value, dropping the decimals when it's a whole number.
    static func percent(_ value: Double) -> String {
        let isWhole = value.truncatingRemainder(dividingBy: 1) == 0
        return value.formatted(.number.precision(.fractionLength(isWhole ? 0 : 2)))
    }

    /// Parses user-typed numbers, accepting both "7.25" and "7,25".
    static func parse(_ text: String) -> Double? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }
}
