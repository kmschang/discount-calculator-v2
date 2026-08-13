import SwiftUI

/// Settings sheet, redesigned: colored icon tiles, glassy rows over the app
/// background, and only the options that still matter — the sales-tax choice
/// itself now lives on the main screen.
struct SettingsView: View {
    private enum SettingHelp: String, Identifiable {
        case roundToPenny
        case taxOriginalPrice
        case launchLocation
        case appearance
        case accentColor
        case appIcon
        case iCloudSync
        case developerTools

        var id: String { rawValue }

        var title: String {
            switch self {
            case .roundToPenny: return "Round to the Penny"
            case .taxOriginalPrice: return "Tax the Original Price"
            case .launchLocation: return "Set Tax from My Location"
            case .appearance: return "Appearance"
            case .accentColor: return "Accent Color"
            case .appIcon: return "App Icon"
            case .iCloudSync: return "Sync with iCloud"
            case .developerTools: return "Developer Tools"
            }
        }

        var message: String {
            switch self {
            case .roundToPenny:
                return "Rounds the discounted subtotal, tax, and final total to the nearest cent. Turn this off to keep full calculation precision."
            case .taxOriginalPrice:
                return "Calculates sales tax from the price before discounts. Most stores tax the discounted price, so leave this off unless you specifically need it."
            case .launchLocation:
                return "Uses your device location when the app opens to select your state's base sales-tax rate. You can still choose a state or enter a rate manually."
            case .appearance:
                return "Choose whether the app follows your device appearance or always uses Light or Dark Mode."
            case .accentColor:
                return "Chooses the highlight color used sparingly for controls, icons, and selected items throughout the app."
            case .appIcon:
                return "Changes the icon shown for Discount Calculator on your Home Screen. Light and dark variants are included."
            case .iCloudSync:
                return "Keeps your sales-tax choice and calculator options in sync across your devices. Appearance, accent color, and app icon remain specific to each device."
            case .developerTools:
                return "Opens diagnostics and testing controls intended for development and troubleshooting."
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var systemColorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"
    @AppStorage("roundToCents") private var roundToCents: Bool = true
    @AppStorage("taxOnOriginal") private var taxOnOriginal: Bool = false
    @AppStorage("autoDetectStateFromLocation") private var autoDetectStateFromLocation: Bool = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = true
    @AppStorage("devModeEnabled") private var devModeEnabled: Bool = false
    @State private var versionTapCount = 0
    @State private var presentedHelp: SettingHelp?

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: systemColorScheme)
    }

    private var appColorScheme: ColorScheme? {
        AppTheme.appColorScheme(appearanceMode: appearanceMode)
    }

    private var appearanceName: String {
        switch appearanceMode {
        case 1: return "Light"
        case 2: return "Dark"
        default: return "System"
        }
    }

    private var currentAppIconDisplayName: String {
        switch selectedAppIconName {
        case "RedAppIcon": return "Red"
        case "OrangeAppIcon": return "Orange"
        case "YellowAppIcon": return "Yellow"
        case "GreenAppIcon": return "Green"
        case "BlueAppIcon": return "Blue"
        case "PurpleAppIcon": return "Purple"
        case "WhiteAppIcon": return "White"
        case "BlackAppIcon": return "Black"
        default: return "Blue"
        }
    }

    private var currentAppIconPreviewName: String {
        discountCalculatorLogoName(
            appearance: discountCalculatorLogoAppearance(for: systemColorScheme),
            color: discountCalculatorLogoColor(forAppIconName: selectedAppIconName)
        )
    }

    private var accentColorName: String {
        switch themeColor {
        case 1: return "Red"
        case 2: return "Orange"
        case 3: return "Yellow"
        case 4: return "Green"
        case 5: return "Blue"
        case 6: return "Purple"
        case 7: return systemColorScheme == .dark ? "White" : "Black"
        default: return "Blue"
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CalculatorBackground(accentColor: accentColor, colorScheme: systemColorScheme)

                List {
                    calculatorSection
                    appearanceSection
                    accountSection
                    developerSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .tint(.primary)
                }
            }
        }
        .preferredColorScheme(appColorScheme)
        .tint(accentColor)
        .alert(item: $presentedHelp) { help in
            Alert(
                title: Text(help.title),
                message: Text(help.message),
                dismissButton: .default(Text("Got It"))
            )
        }
    }

    // MARK: - Sections

    private var calculatorSection: some View {
        Section {
            HStack(spacing: 12) {
                settingHelpButton(
                    systemName: "dollarsign.circle.fill",
                    color: .green,
                    help: .roundToPenny
                )
                Spacer(minLength: 8)
                Toggle("Round to the penny", isOn: $roundToCents)
                    .labelsHidden()
            }

            HStack(spacing: 12) {
                settingHelpButton(
                    systemName: "receipt.fill",
                    color: .orange,
                    help: .taxOriginalPrice
                )
                Spacer(minLength: 8)
                Toggle("Tax the original price", isOn: $taxOnOriginal)
                    .labelsHidden()
            }

            HStack(spacing: 12) {
                settingHelpButton(
                    systemName: "location.fill",
                    color: .blue,
                    help: .launchLocation
                )
                Spacer(minLength: 8)
                Toggle("Set tax from my location at launch", isOn: $autoDetectStateFromLocation)
                    .labelsHidden()
            }
        } header: {
            Text("Calculator")
        } footer: {
            Text("Tap a setting’s name or icon for a quick description.")
        }
        .listRowBackground(rowBackground)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            HStack(spacing: 12) {
                settingHelpButton(
                    systemName: "circle.lefthalf.filled",
                    color: .indigo,
                    help: .appearance
                )
                Spacer(minLength: 8)
                NavigationLink {
                    AppearanceModeSettingsView()
                } label: {
                    Text(appearanceName)
                        .foregroundColor(.secondary)
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Open Appearance settings")
            }

            HStack(spacing: 12) {
                settingHelpButton(
                    systemName: "paintpalette.fill",
                    color: .pink,
                    help: .accentColor
                )
                Spacer(minLength: 8)
                NavigationLink {
                    AccentColorSettingsView()
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 14, height: 14)
                        Text(accentColorName)
                            .foregroundColor(.secondary)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Open Accent Color settings")
            }

            HStack(spacing: 12) {
                appIconHelpButton
                Spacer(minLength: 8)
                NavigationLink {
                    AppIconSettingsView(onDone: {
                        dismiss()
                    })
                } label: {
                    Text(currentAppIconDisplayName)
                        .foregroundColor(.secondary)
                }
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityLabel("Open App Icon settings")
            }
        }
        .listRowBackground(rowBackground)
    }

    private var accountSection: some View {
        Section("Account") {
            HStack(spacing: 12) {
                settingHelpButton(
                    systemName: "icloud.fill",
                    color: .cyan,
                    help: .iCloudSync
                )
                Spacer(minLength: 8)
                Toggle("Sync with iCloud", isOn: $iCloudSyncEnabled)
                    .labelsHidden()
                    .onChange(of: iCloudSyncEnabled) { _, newValue in
                        ICloudSyncManager.shared.isEnabled = newValue
                    }
            }
        }
        .listRowBackground(rowBackground)
    }

    @ViewBuilder
    private var developerSection: some View {
        if devModeEnabled || isDebugBuild {
            Section("Developer") {
                HStack(spacing: 12) {
                    settingHelpButton(
                        systemName: "hammer.fill",
                        color: .gray,
                        help: .developerTools
                    )
                    .layoutPriority(1)
                    Spacer(minLength: 8)
                    NavigationLink {
                        DeveloperToolsView()
                    } label: {
                        Text(devModeEnabled ? "On" : "Debug")
                            .foregroundColor(.secondary)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel("Open Developer Tools")
                }
            }
            .listRowBackground(rowBackground)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersionString)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                versionTapCount += 1
                if versionTapCount >= 8 {
                    devModeEnabled.toggle()
                    versionTapCount = 0
                }
            }

            HStack {
                Text("Developer")
                Spacer()
                Text("Sonnaz Group, LLC")
                    .foregroundColor(.secondary)
            }
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - Row building blocks

    private var rowBackground: some View {
        Rectangle().fill(.ultraThinMaterial)
    }

    private func settingHelpButton(
        systemName: String,
        color: Color,
        help: SettingHelp
    ) -> some View {
        Button {
            presentedHelp = help
        } label: {
            HStack(spacing: 12) {
                iconTile(systemName, color: color)
                Text(help.title)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .tint(.primary)
        .accessibilityHint("Shows a description of this setting")
    }

    private var appIconHelpButton: some View {
        Button {
            presentedHelp = .appIcon
        } label: {
            HStack(spacing: 12) {
                Image(currentAppIconPreviewName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(radius: 2, x: 0, y: 1)
                Text(SettingHelp.appIcon.title)
                    .foregroundStyle(.primary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .tint(.primary)
        .accessibilityHint("Shows a description of this setting")
    }

    private func iconTile(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 30, height: 30)
            .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(0.12), lineWidth: 0.5)
            }
    }

}

#Preview("Settings - Light") {
    SettingsView()
        .preferredColorScheme(.light)
}

#Preview("Settings - Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}
