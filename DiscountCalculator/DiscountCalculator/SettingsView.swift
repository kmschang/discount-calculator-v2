import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var systemColorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"

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

    var body: some View {
        NavigationStack {
            List {
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
                        AppIconSettingsView()
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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
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
