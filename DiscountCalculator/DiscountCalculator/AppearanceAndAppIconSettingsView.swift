//
//  AppearanceAndAppIconSettingsView.swift
//  DiscountCalculator
//
//  Appearance + app-icon pickers. Icon previews are drawn from the single
//  transparent logo asset plus a gradient per color, so adding or retuning a
//  color needs no new artwork — the shipped .appiconset files stay the source
//  of truth for the icons iOS actually installs.
//

import SwiftUI
import UIKit

// MARK: - App icon styles

private extension Color {
    init(appIconHex value: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// One selectable icon color. Gradient stops were sampled from the real
/// `*AppIcon.appiconset` artwork so a preview matches the installed icon.
struct DiscountCalculatorAppIconStyle: Identifiable {
    let id: String
    let displayName: String
    /// The alternate icon name as configured in the app's Info.plist.
    let iconName: String?

    static let all: [DiscountCalculatorAppIconStyle] = [
        DiscountCalculatorAppIconStyle(id: "Red", displayName: "Red", iconName: "RedAppIcon"),
        DiscountCalculatorAppIconStyle(id: "Orange", displayName: "Orange", iconName: "OrangeAppIcon"),
        DiscountCalculatorAppIconStyle(id: "Yellow", displayName: "Yellow", iconName: "YellowAppIcon"),
        DiscountCalculatorAppIconStyle(id: "Green", displayName: "Green", iconName: "GreenAppIcon"),
        DiscountCalculatorAppIconStyle(id: "Blue", displayName: "Blue", iconName: "BlueAppIcon"),
        DiscountCalculatorAppIconStyle(id: "Purple", displayName: "Purple", iconName: "PurpleAppIcon"),
        DiscountCalculatorAppIconStyle(id: "Black", displayName: "Black", iconName: "BlackAppIcon"),
        DiscountCalculatorAppIconStyle(id: "White", displayName: "White", iconName: "WhiteAppIcon")
    ]

    static func style(for iconName: String) -> DiscountCalculatorAppIconStyle {
        all.first(where: { iconName == ($0.iconName ?? "BlueAppIcon") })
            ?? all.first(where: { $0.id == "Blue" })
            ?? all[0]
    }

    private var gradientDarkColor: Color {
        switch id {
        case "Red": return Color(appIconHex: 0xAB0101)
        case "Orange": return Color(appIconHex: 0xFC5D01)
        case "Yellow": return Color(appIconHex: 0xF5B801)
        case "Green": return Color(appIconHex: 0x017709)
        case "Blue": return Color(appIconHex: 0x311EA9)
        case "Purple": return Color(appIconHex: 0x6E0192)
        // Sampled white is a flat #FCFCFC, which would read as a blank tile, so
        // the low stop is darkened just enough to show the icon's shape.
        case "White": return Color(appIconHex: 0xC7C7C7)
        case "Black": return Color(appIconHex: 0x090809)
        default: return Color(appIconHex: 0x311EA9)
        }
    }

    private var gradientLightColor: Color {
        switch id {
        case "Red": return Color(appIconHex: 0xFE2627)
        case "Orange": return Color(appIconHex: 0xFE8E01)
        case "Yellow": return Color(appIconHex: 0xFEFC67)
        case "Green": return Color(appIconHex: 0x07D309)
        case "Blue": return Color(appIconHex: 0x537FC9)
        case "Purple": return Color(appIconHex: 0xCA5FEE)
        case "White": return Color(appIconHex: 0xFFFFFF)
        case "Black": return Color(appIconHex: 0x252526)
        default: return Color(appIconHex: 0x537FC9)
        }
    }

    var iconGradient: LinearGradient {
        LinearGradient(
            colors: [gradientDarkColor, gradientLightColor],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    /// On a dark tile a near-black icon would disappear, so Black lifts to gray.
    var darkAppearanceIconGradient: LinearGradient {
        LinearGradient(
            colors: id == "Black"
                ? [Color(appIconHex: 0x333333), Color(appIconHex: 0x585858)]
                : [gradientDarkColor, gradientLightColor],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
    }

    /// Flat color for chips and selection accents.
    var representativeColor: Color {
        switch id {
        case "White": return Color(appIconHex: 0xE8E8E8)
        case "Black": return Color(appIconHex: 0x2E2E2E)
        default: return gradientLightColor
        }
    }
}

enum AppIconPreviewAppearance {
    case light
    case dark
}

/// Recreates the alternate icon previews from the one transparent logo asset.
/// The actual app icons remain in their required appiconsets.
struct DiscountCalculatorIconPreview: View {
    let style: DiscountCalculatorAppIconStyle
    let appearance: AppIconPreviewAppearance
    var cornerRadius: CGFloat = 22
    var logoPadding: CGFloat = 12

    private var logo: some View {
        Image("DiscountCalculatorLogo(Transparent)")
            .resizable()
            .scaledToFit()
            .padding(logoPadding)
    }

    var body: some View {
        ZStack {
            if appearance == .light {
                // The white base keeps light gradient stops deterministic
                // instead of letting the surrounding UI show through.
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(style.iconGradient)

                logo
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.15), Color(white: 0.015)],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )

                ZStack {
                    logo

                    // Multiplication colors the white logo face while retaining
                    // the gray highlights and shading baked into the asset.
                    style.darkAppearanceIconGradient
                        .mask { logo }
                        .blendMode(.multiply)
                }
                .compositingGroup()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(appearance == .dark ? 0.12 : 0.32), lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(appearance == .dark ? 0.34 : 0.16), radius: 8, x: 0, y: 5)
        .accessibilityHidden(true)
    }
}

// MARK: - App Icon Settings

struct AppIconSettingsView: View {
    let onDone: (() -> Void)?

    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"
    @AppStorage("themeColor") private var themeColor: Int = 7
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    @State private var iconChangeErrorMessage: String?
    @State private var isChangingIcon: Bool = false

    /// iOS occasionally reports the icon service as busy; a few spaced retries
    /// clear that without bothering the user.
    private static let iconChangeRetryDelays: [TimeInterval] = [0.4, 0.9, 1.6]

    private let options = DiscountCalculatorAppIconStyle.all

    init(onDone: (() -> Void)? = nil) {
        self.onDone = onDone
    }

    private var selectedOption: DiscountCalculatorAppIconStyle {
        DiscountCalculatorAppIconStyle.style(for: selectedAppIconName)
    }

    private var accentColor: Color {
        AppTheme.paletteColor(themeColor: themeColor, colorScheme: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                AppIconSelectedShowcase(
                    option: selectedOption,
                    accentColor: accentColor,
                    isChanging: isChangingIcon
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose your icon")
                        .font(.headline)

                    Text("Select a color below. iOS automatically uses its matching light or dark version.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 74, maximum: 104), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        AppIconChoice(
                            option: option,
                            isSelected: selectedAppIconName == (option.iconName ?? "BlueAppIcon"),
                            accentColor: accentColor
                        ) {
                            applyIcon(option)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
            .disabled(isChangingIcon)
            .opacity(isChangingIcon ? 0.7 : 1)
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if let onDone {
                        onDone()
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "checkmark")
                }
                .tint(.primary)
                .accessibilityLabel("Done")
                .disabled(isChangingIcon)
            }
        }
        .onAppear {
            guard !AppRuntime.isRunningForPreviews else { return }
            syncSelectedIconFromSystem()
        }
        .alert(
            "Unable to Change App Icon",
            isPresented: Binding(
                get: { iconChangeErrorMessage != nil },
                set: { if !$0 { iconChangeErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(iconChangeErrorMessage ?? "Unknown error")
        }
    }

    // MARK: Applying the icon

    private func applyIcon(_ option: DiscountCalculatorAppIconStyle) {
        let desiredIconName = option.iconName ?? "BlueAppIcon"

        guard UIApplication.shared.supportsAlternateIcons else {
            iconChangeErrorMessage = "This device does not support alternate app icons."
            return
        }

        guard !isChangingIcon else { return }
        guard selectedAppIconName != desiredIconName else { return }
        guard scenePhase == .active else {
            iconChangeErrorMessage = "Discount Calculator needs to be active before iOS can change the app icon. Please try again in a moment."
            syncSelectedIconFromSystem()
            return
        }

        isChangingIcon = true
        iconChangeErrorMessage = nil
        setAlternateIcon(option, retryDelays: Self.iconChangeRetryDelays)
    }

    private func setAlternateIcon(_ option: DiscountCalculatorAppIconStyle, retryDelays: [TimeInterval]) {
        guard scenePhase == .active else {
            isChangingIcon = false
            iconChangeErrorMessage = "Discount Calculator needs to be active before iOS can change the app icon. Please try again in a moment."
            syncSelectedIconFromSystem()
            return
        }

        let iconNameToSet = option.iconName
        let desiredIconName = iconNameToSet ?? "BlueAppIcon"

        UIApplication.shared.setAlternateIconName(iconNameToSet) { error in
            DispatchQueue.main.async {
                if let error {
                    if isTransientIconChangeError(error), let retryDelay = retryDelays.first {
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                            setAlternateIcon(option, retryDelays: Array(retryDelays.dropFirst()))
                        }
                        return
                    }

                    finishIconChangeFailure(error)
                    return
                }

                isChangingIcon = false
                selectedAppIconName = desiredIconName
            }
        }
    }

    /// The system owns which icon is actually installed, so trust it over the
    /// stored preference whenever the two disagree.
    private func syncSelectedIconFromSystem() {
        selectedAppIconName = UIApplication.shared.alternateIconName ?? "BlueAppIcon"
    }

    private func finishIconChangeFailure(_ error: Error) {
        isChangingIcon = false
        syncSelectedIconFromSystem()

        if isTransientIconChangeError(error) {
            // NSPOSIXErrorDomain 35 ("Resource temporarily unavailable") from
            // LSIconAlertManager — a known iOS 26.1+ regression where the icon
            // service wedges until the device is rebooted, so retrying can't help.
            iconChangeErrorMessage = "iOS could not change the app icon right now. Restarting your device usually clears this — then try again."
        } else if isMissingIconFileError(error) {
            // NSCocoaErrorDomain 4/260 ("The file doesn't exist.") even though the
            // icons are verifiably in the bundle: after an app update, iOS 26 can
            // keep a stale icon registration pointing at the old install path.
            iconChangeErrorMessage = "This copy of the app is missing its alternate icons — a delivery issue rather than a problem with your device. It should be resolved in the next app update."
        } else {
            iconChangeErrorMessage = error.localizedDescription
        }
    }

    private func isMissingIconFileError(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain
            && (nsError.code == NSFileNoSuchFileError || nsError.code == NSFileReadNoSuchFileError)
    }

    private func isTransientIconChangeError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let searchableText = [
            nsError.localizedDescription,
            nsError.localizedFailureReason,
            nsError.localizedRecoverySuggestion
        ]
            .compactMap { $0 }
            .joined(separator: " ")
            .lowercased()

        return searchableText.contains("temporarily unavailable")
            || (searchableText.contains("resource") && searchableText.contains("unavailable"))
    }
}

private struct AppIconSelectedShowcase: View {
    let option: DiscountCalculatorAppIconStyle
    let accentColor: Color
    let isChanging: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Icon")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(option.displayName)
                        .font(.title2.weight(.bold))
                }

                Spacer()

                if isChanging {
                    ProgressView()
                        .tint(accentColor)
                        .accessibilityLabel("Changing app icon")
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(accentColor)
                }
            }

            HStack(spacing: 16) {
                AppIconAppearancePreview(label: "Light", option: option, appearance: .light)
                AppIconAppearancePreview(label: "Dark", option: option, appearance: .dark)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

private struct AppIconAppearancePreview: View {
    let label: String
    let option: DiscountCalculatorAppIconStyle
    let appearance: AppIconPreviewAppearance

    var body: some View {
        VStack(spacing: 8) {
            DiscountCalculatorIconPreview(
                style: option,
                appearance: appearance,
                cornerRadius: 24,
                logoPadding: 13
            )
            .aspectRatio(1, contentMode: .fit)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AppIconChoice: View {
    let option: DiscountCalculatorAppIconStyle
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                DiscountCalculatorIconPreview(
                    style: option,
                    appearance: .light,
                    cornerRadius: 16,
                    logoPadding: 7
                )
                .frame(width: 64, height: 64)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, accentColor)
                            .offset(x: 5, y: -5)
                            .accessibilityLabel("Selected")
                    }
                }

                Text(option.displayName)
                    .font(.caption.weight(isSelected ? .bold : .semibold))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? accentColor : Color.primary.opacity(0.10), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.displayName)
        .accessibilityValue(isSelected ? "Selected" : "")
    }
}

#Preview("App Icon Settings") {
    NavigationStack {
        AppIconSettingsView()
    }
}

// MARK: - Appearance Mode Settings

struct AppearanceModeSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("themeColor") private var themeColor: Int = 7
    @Environment(\.colorScheme) private var systemColorScheme

    private var accentColor: Color {
        AppTheme.paletteColor(themeColor: themeColor, colorScheme: systemColorScheme)
    }

    var body: some View {
        List {
            // System option
            Section {
                Button {
                    appearanceMode = 0
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System")
                                .foregroundColor(accentColor)
                            Text("Match device appearance")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if appearanceMode == 0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(accentColor)
                        }
                    }
                }
                .contentShape(Rectangle())
            }

            // Visual preview for Light / Dark
            Section("Preview") {
                HStack(spacing: 16) {
                    AppearancePreviewCard(
                        title: "Light",
                        isSelected: appearanceMode == 1,
                        isDark: false,
                        accentColor: accentColor
                    ) {
                        appearanceMode = 1
                        dismiss()
                    }

                    AppearancePreviewCard(
                        title: "Dark",
                        isSelected: appearanceMode == 2,
                        isDark: true,
                        accentColor: accentColor
                    ) {
                        appearanceMode = 2
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: appearanceMode)
    }
}

struct AppearancePreviewCard: View {
    let title: String
    let isSelected: Bool
    let isDark: Bool
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: isDark
                                    ? [Color.black, Color(red: 0.055, green: 0.055, blue: 0.06)]
                                    : [Color.white, Color(red: 0.96, green: 0.96, blue: 0.97)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.15),
                                radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    isSelected ? accentColor.opacity(0.45) : Color.primary.opacity(0.2),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )

                    // Neutral ambient light, matching the app's mostly
                    // colorless canvas. The selected border carries the accent.
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    (isDark ? Color.white : Color.black).opacity(0.07),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 18)
                        .offset(x: -24, y: -28)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    (isDark ? Color.white : Color.black).opacity(0.25),
                                    Color.clear
                                ],
                                startPoint: .bottomTrailing,
                                endPoint: .topLeading
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 18)
                        .offset(x: 24, y: 24)
                }
                .aspectRatio(9.0 / 16.0, contentMode: .fit)

                Text(title)
                    .font(.footnote.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? accentColor : .secondary)
            }
            .padding(6)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Appearance Settings") {
    NavigationStack {
        AppearanceModeSettingsView()
    }
}
