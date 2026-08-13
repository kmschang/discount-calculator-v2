import SwiftUI

/// Settings sheet, redesigned: colored icon tiles, glassy rows over the app
/// background, and only the options that still matter — the sales-tax choice
/// itself now lives on the main screen.
struct SettingsView: View {
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
    }

    // MARK: - Sections

    private var calculatorSection: some View {
        Section {
            iconRow("dollarsign.circle.fill", .green) {
                Toggle("Round to the penny", isOn: $roundToCents)
            }
            iconRow("receipt.fill", .orange) {
                Toggle("Tax the original price", isOn: $taxOnOriginal)
            }
            iconRow("location.fill", .blue) {
                Toggle("Set tax from my location at launch", isOn: $autoDetectStateFromLocation)
            }
        } header: {
            Text("Calculator")
        } footer: {
            Text("“Tax the original price” charges sales tax on the price before discounts — most stores tax the discounted price, so leave it off unless you need it. The location option looks up your state's tax each time the app opens; you can always tap Local on the main screen instead.")
        }
        .listRowBackground(rowBackground)
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            NavigationLink {
                AppearanceModeSettingsView()
            } label: {
                iconRow("circle.lefthalf.filled", .indigo) {
                    HStack {
                        Text("Appearance")
                        Spacer()
                        Text(appearanceName)
                            .foregroundColor(.secondary)
                    }
                }
            }

            NavigationLink {
                AccentColorSettingsView()
            } label: {
                iconRow("paintpalette.fill", .pink) {
                    HStack {
                        Text("Accent Color")
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accentColor)
                                .frame(width: 14, height: 14)
                            Text(accentColorName)
                                .foregroundColor(accentColor)
                        }
                    }
                }
            }

            NavigationLink {
                AppIconSettingsView(onDone: {
                    dismiss()
                })
            } label: {
                HStack(spacing: 12) {
                    Image(currentAppIconPreviewName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .shadow(radius: 2, x: 0, y: 1)
                    Text("App Icon")
                    Spacer()
                    Text(currentAppIconDisplayName)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listRowBackground(rowBackground)
    }

    private var accountSection: some View {
        Section {
            iconRow("icloud.fill", .cyan) {
                Toggle("Sync with iCloud", isOn: $iCloudSyncEnabled)
                    .onChange(of: iCloudSyncEnabled) { _, newValue in
                        ICloudSyncManager.shared.isEnabled = newValue
                    }
            }
        } header: {
            Text("Account")
        } footer: {
            Text("Keeps your sales-tax choice and calculator options in sync across your devices with iCloud. Appearance, accent color, and app icon stay set per-device.")
        }
        .listRowBackground(rowBackground)
    }

    @ViewBuilder
    private var developerSection: some View {
        if devModeEnabled || isDebugBuild {
            Section("Developer") {
                NavigationLink {
                    DeveloperToolsView()
                } label: {
                    iconRow("hammer.fill", .gray) {
                        HStack {
                            Text("Developer Tools")
                            Spacer()
                            Text(devModeEnabled ? "On" : "Debug")
                                .foregroundColor(.secondary)
                        }
                    }
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

    private func iconRow(_ systemName: String, _ color: Color, @ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            content()
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
