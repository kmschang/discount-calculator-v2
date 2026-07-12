import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var systemColorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"
    @AppStorage("homeStateCode") private var homeStateCode: String = ""
    @AppStorage("localTaxRate") private var localTaxRate: Double = 0
    @AppStorage("roundToCents") private var roundToCents: Bool = true
    @AppStorage("taxOnOriginal") private var taxOnOriginal: Bool = false
    @AppStorage("autoDetectStateFromLocation") private var autoDetectStateFromLocation: Bool = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = true
    @AppStorage("devModeEnabled") private var devModeEnabled: Bool = false
    @State private var versionTapCount = 0

    private var accentColor: Color {
        switch themeColor {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        case 6: return .purple
        case 7:
            let effectiveScheme: ColorScheme
            if let appScheme = appColorScheme {
                effectiveScheme = appScheme
            } else {
                effectiveScheme = systemColorScheme
            }
            return effectiveScheme == .dark ? .white : .black
        default:
            return .accentColor
        }
    }

    private var appColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1:
            return .light
        case 2:
            return .dark
        default:
            return nil
        }
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

    private var homeStateName: String {
        guard !homeStateCode.isEmpty, let state = USStateTax.byCode(homeStateCode) else { return "Not set" }
        return state.name
    }

    private var localTaxLabel: String {
        localTaxRate > 0 ? "\(AppFormat.percent(localTaxRate))%" : "None"
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
            List {
                Section {
                    NavigationLink {
                        HomeStateSettingsView()
                    } label: {
                        HStack {
                            Text("Home State")
                            Spacer()
                            Text(homeStateName)
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink {
                        LocalTaxSettingsView()
                    } label: {
                        HStack {
                            Text("Local Tax")
                            Spacer()
                            Text(localTaxLabel)
                                .foregroundColor(.secondary)
                        }
                    }

                    Toggle("Round to the penny", isOn: $roundToCents)
                    Toggle("Tax the original price", isOn: $taxOnOriginal)
                    Toggle("Find my state automatically", isOn: $autoDetectStateFromLocation)
                } header: {
                    Text("Calculator")
                } footer: {
                    Text("“Tax the original price” charges sales tax on the price before discounts. Most stores tax the discounted price, so leave this off unless you need it. “Find my state automatically” uses your location on launch to set your state's tax.")
                }

                Section("Appearance") {
                    NavigationLink {
                        AppearanceModeSettingsView()
                    } label: {
                        HStack {
                            Text("Appearance")
                            Spacer()
                            Text(appearanceName)
                                .foregroundColor(.secondary)
                        }
                    }

                    NavigationLink {
                        AccentColorSettingsView()
                    } label: {
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

                    NavigationLink {
                        AppIconSettingsView(onDone: {
                            dismiss()
                        })
                    } label: {
                        HStack {
                            Text("App Icon")
                            Spacer()
                            HStack(spacing: 8) {
                                Image(currentAppIconPreviewName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 28, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .shadow(radius: 2, x: 0, y: 1)

                                Text(currentAppIconDisplayName)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Section {
                    Toggle("Sync with iCloud", isOn: $iCloudSyncEnabled)
                        .onChange(of: iCloudSyncEnabled) { _, newValue in
                            ICloudSyncManager.shared.isEnabled = newValue
                        }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Keeps your home state, local tax, and calculator options in sync across your devices with iCloud. Appearance, accent color, and app icon stay set per-device.")
                }

                if devModeEnabled || isDebugBuild {
                    Section("Developer") {
                        NavigationLink {
                            DeveloperToolsView()
                        } label: {
                            HStack {
                                Text("Developer Tools")
                                Spacer()
                                Text(devModeEnabled ? "On" : "Debug")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

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
}

#Preview("Settings - Light") {
    SettingsView()
        .preferredColorScheme(.light)
}

#Preview("Settings - Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}
