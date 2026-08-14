import SwiftUI

enum AppRuntime {
    static let isRunningForPreviews =
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

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
        paletteColor(
            themeColor: themeColor,
            colorScheme: effectiveScheme(appearanceMode: appearanceMode, systemScheme: systemScheme)
        )
    }

    /// Matches the true colors shown by the theme picker and app-icon artwork.
    /// The interface stays quiet by using this color sparingly rather than by
    /// changing the color itself.
    static func paletteColor(themeColor: Int, colorScheme: ColorScheme) -> Color {
        switch themeColor {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        case 6: return .purple
        case 7: return colorScheme == .dark ? .white : .black
        default: return .blue
        }
    }

    static let positiveColor = Color.green
    static let negativeColor = Color.red
}

// MARK: - Shared background
// A neutral ambient background shared by every primary screen. Accent color is
// intentionally reserved for small controls and selection states.

struct CalculatorBackground: View {
    var accentColor: Color
    var colorScheme: ColorScheme

    var body: some View {
        let isDark = colorScheme == .dark
        ZStack {
            LinearGradient(
                colors: isDark
                    ? [Color.black, Color(red: 0.055, green: 0.055, blue: 0.06)]
                    : [Color(red: 0.96, green: 0.96, blue: 0.97), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(LinearGradient(colors: [Color.primary.opacity(isDark ? 0.045 : 0.025), .clear],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -130, y: -300)

            Circle()
                .fill(LinearGradient(colors: [Color.secondary.opacity(isDark ? 0.035 : 0.02), .clear],
                                     startPoint: .bottomTrailing, endPoint: .topLeading))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 170, y: 300)
        }
    }
}

// MARK: - Glass card
// The reusable "liquid glass" surface. These are visual containers rather than
// controls; buttons inside them provide their own press feedback.

extension View {
    @ViewBuilder
    func glassCard(accentColor: Color, cornerRadius: CGFloat = 22, emphasized: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(emphasized ? 0.16 : 0.10), lineWidth: 1)
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

    /// The separator this device's decimal keypad actually produces.
    static var decimalSeparator: Character {
        Locale.current.decimalSeparator?.first ?? "."
    }

    /// Parses user-typed numbers, accepting both "7.25" and "7,25".
    static func parse(_ text: String) -> Double? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    /// How long a typed number is allowed to get. Applied as the user types so a
    /// field can never grow past what the layout (and the math) can show.
    struct NumberLimit {
        var maxIntegerDigits: Int
        var maxFractionDigits: Int

        /// Up to 9,999,999.99 — more than any register total needs.
        static let price = NumberLimit(maxIntegerDigits: 7, maxFractionDigits: 2)
        /// Room for 100.00% without allowing nonsense like 99999%.
        static let percentOff = NumberLimit(maxIntegerDigits: 3, maxFractionDigits: 2)
        /// Dollar discounts are money, so they match the price field.
        static let amountOff = price
        /// Same 3-digit cap as a percent discount. The third decimal is kept so
        /// real rates like 8.375% stay exact.
        static let taxRate = NumberLimit(maxIntegerDigits: 3, maxFractionDigits: 3)

        /// Keeps digits and at most one decimal separator, capping the digit count
        /// on each side. Anything else the user types (or pastes) is dropped.
        func clamped(_ text: String) -> String {
            var integerDigits = ""
            var fractionDigits = ""
            var separator: Character?

            for character in text {
                if character.isASCII, character.isNumber {
                    if separator == nil {
                        if integerDigits.count < maxIntegerDigits {
                            integerDigits.append(character)
                        }
                    } else if fractionDigits.count < maxFractionDigits {
                        fractionDigits.append(character)
                    }
                } else if character == AppFormat.decimalSeparator {
                    // Only the first separator counts, and only when this field
                    // actually accepts a fractional part.
                    if separator == nil, maxFractionDigits > 0 {
                        separator = character
                    }
                }
                // Any other character — including the grouping mark in a pasted
                // "1,234.56" — is dropped, so the value keeps its magnitude.
            }

            guard let separator else { return integerDigits }
            return "\(integerDigits)\(separator)\(fractionDigits)"
        }
    }
}

// MARK: - Appearance

extension View {
    /// Forces a resolved light/dark scheme onto this view.
    ///
    /// `preferredColorScheme` alone is not enough for sheets: UIKit won't restyle
    /// an already-presented sheet when the preference changes, so switching
    /// appearance from inside Settings would repaint the screen behind it and
    /// leave the sheet itself on the old scheme. Overriding the environment value
    /// too makes the presented content follow along immediately.
    func appAppearance(_ scheme: ColorScheme) -> some View {
        self
            .preferredColorScheme(scheme)
            .environment(\.colorScheme, scheme)
    }
}

extension View {
    /// Enforces a digit limit on a text field.
    ///
    /// The clamp deliberately runs *after* the typed value reaches `text`, not
    /// inside a filtering `Binding`: a binding that silently rejects a keystroke
    /// leaves the source of truth unchanged, so SwiftUI sees nothing to update
    /// and the rejected character stays visible in the field. Writing the
    /// shortened value back is a real change, so the field redraws without it.
    func digitLimit(_ limit: AppFormat.NumberLimit, text: Binding<String>) -> some View {
        onChange(of: text.wrappedValue) { _, newValue in
            let clamped = limit.clamped(newValue)
            if clamped != newValue { text.wrappedValue = clamped }
        }
    }
}
