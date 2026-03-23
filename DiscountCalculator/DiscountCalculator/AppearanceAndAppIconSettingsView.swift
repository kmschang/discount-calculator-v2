//
//  AppearanceAndAppIconSettingsView.swift
//  DayCalculator
//
//  Created by Kyle Schang on 12/10/25.
//

import SwiftUI
import UIKit

// MARK: - App Icon Settings

struct AppIconSettingsView: View {
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"
    @Environment(\.dismiss) private var dismiss
    @State private var iconChangeErrorMessage: String?
    @State private var isChangingIcon: Bool = false
    
    struct AppIconOption: Identifiable {
        let id: String
        let displayName: String
        let previewImageNameLight: String
        let previewImageNameDark: String
        /// The alternate icon name as configured in the app's Info.plist.
        /// Use nil for the primary/default icon.
        let iconName: String?
    }
    
    private let options: [AppIconOption] = [
        AppIconOption(id: "Red",    displayName: "Red",    previewImageNameLight: discountCalculatorLogoName(appearance: .light, color: "Red"),    previewImageNameDark: discountCalculatorLogoName(appearance: .dark, color: "Red"),    iconName: "RedAppIcon"),
        AppIconOption(id: "Orange", displayName: "Orange", previewImageNameLight: discountCalculatorLogoName(appearance: .light, color: "Orange"), previewImageNameDark: discountCalculatorLogoName(appearance: .dark, color: "Orange"), iconName: "OrangeAppIcon"),
        AppIconOption(id: "Yellow", displayName: "Yellow", previewImageNameLight: discountCalculatorLogoName(appearance: .light, color: "Yellow"), previewImageNameDark: discountCalculatorLogoName(appearance: .dark, color: "Yellow"), iconName: "YellowAppIcon"),
        AppIconOption(id: "Green",  displayName: "Green",  previewImageNameLight: discountCalculatorLogoName(appearance: .light, color: "Green"),  previewImageNameDark: discountCalculatorLogoName(appearance: .dark, color: "Green"),  iconName: "GreenAppIcon"),
        AppIconOption(id: "Blue",   displayName: "Blue",   previewImageNameLight: discountCalculatorLogoName(appearance: .light, color: "Blue"),   previewImageNameDark: discountCalculatorLogoName(appearance: .dark, color: "Blue"),   iconName: "BlueAppIcon"),
        AppIconOption(id: "Purple", displayName: "Purple", previewImageNameLight: discountCalculatorLogoName(appearance: .light, color: "Purple"), previewImageNameDark: discountCalculatorLogoName(appearance: .dark, color: "Purple"), iconName: "PurpleAppIcon"),
        AppIconOption(id: "Black",  displayName: "Black",  previewImageNameLight: discountCalculatorLogoName(appearance: .light, color: "Black"),  previewImageNameDark: discountCalculatorLogoName(appearance: .dark, color: "Black"),  iconName: "BlackAppIcon"),
        AppIconOption(id: "White",  displayName: "White",  previewImageNameLight: discountCalculatorLogoName(appearance: .light, color: "White"),  previewImageNameDark: discountCalculatorLogoName(appearance: .dark, color: "White"),  iconName: "WhiteAppIcon")
    ]
    
    private var selectedOption: AppIconOption {
        // Match current persisted selection and fall back to Blue if something is out of sync.
        if let match = options.first(where: { selectedAppIconName == ($0.iconName ?? "BlueAppIcon") }) {
            return match
        }
        if let blue = options.first(where: { $0.iconName == "BlueAppIcon" }) {
            return blue
        }
        return options[0]
    }
    
    // Theme color from Settings
    @AppStorage("themeColor") private var themeColor: Int = 1
    @Environment(\.colorScheme) var colorScheme
    
    private var accentColor: Color {
        switch themeColor {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        case 6: return .purple
        case 7:
            // Mono accent: black in light mode, white in dark mode
            return colorScheme == .dark ? .white : .black
        default:
            return .accentColor
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SelectedAppIconShowcase(
                option: selectedOption,
                accentColor: accentColor
            )
            .padding(.horizontal, 18)
            .padding(.top, 8)

            Divider().overlay(colorScheme == .dark ? .white.opacity(0.25) : .black.opacity(0.25))
                .padding(.horizontal, 20)
                .padding(.top, 20)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    ForEach(options) { option in
                        AppIconPreviewCard(
                            option: option,
                            isSelected: selectedAppIconName == (option.iconName ?? "BlueAppIcon"),
                            accentColor: accentColor
                        ) {
                            applyIcon(option)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
                .padding(.top, 15)
            }
        }
        .navigationTitle("App Icon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
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
    
    private func applyIcon(_ option: AppIconOption) {
        let iconNameToSet = option.iconName
        let desiredIconName = iconNameToSet ?? "BlueAppIcon"
        
        guard UIApplication.shared.supportsAlternateIcons else {
            iconChangeErrorMessage = "This device does not support alternate app icons."
            return
        }

        guard !isChangingIcon else { return }
        guard selectedAppIconName != desiredIconName else { return }

        isChangingIcon = true
        
        UIApplication.shared.setAlternateIconName(iconNameToSet) { error in
            DispatchQueue.main.async {
                isChangingIcon = false

                if let error = error {
                    print("Error setting alternate icon: \(error.localizedDescription)")
                    iconChangeErrorMessage = error.localizedDescription
                    syncSelectedIconFromSystem()
                    return
                }

                selectedAppIconName = desiredIconName
            }
        }
    }

    private func syncSelectedIconFromSystem() {
        selectedAppIconName = UIApplication.shared.alternateIconName ?? "BlueAppIcon"
    }
}

private struct SelectedAppIconShowcase: View {
    let option: AppIconSettingsView.AppIconOption
    let accentColor: Color

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                Text("Preview")
                    .font(.headline)

                Text("Light & Dark variants")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 14) {
                LabeledIconPreview(
                    label: "Light",
                    imageName: option.previewImageNameLight
                )

                LabeledIconPreview(
                    label: "Dark",
                    imageName: option.previewImageNameDark
                )
            }
            .frame(maxWidth: .infinity)

            Text("This screen shows both versions so you can see how the icon looks in each appearance.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(accentColor.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct LabeledIconPreview: View {
    let label: String
    let imageName: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.secondarySystemBackground).opacity(0.85),
                                Color(.systemBackground).opacity(0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )

                Image(imageName)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(12)
            }
            .frame(width: 120, height: 120)

            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(.thinMaterial)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AppIconPreviewCard: View {
    let option: AppIconSettingsView.AppIconOption
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color(.systemBackground).opacity(0.35),
                                    Color(.secondarySystemBackground).opacity(0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        )
                        .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .strokeBorder(
                                    isSelected ? accentColor : Color.primary.opacity(0.2),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    
                    HStack(spacing: 12) {
                        VStack(spacing: 8) {
                            Image(option.previewImageNameLight)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .frame(width: 56, height: 56)

                            Text("Light")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(.thinMaterial)
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 8) {
                            Image(option.previewImageNameDark)
                                .resizable()
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .frame(width: 56, height: 56)

                            Text("Dark")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(.thinMaterial)
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                                )
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                }
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            // First color is the checkmark, second is the filled circle.
                            .foregroundStyle(.white, accentColor)
                            // Push it slightly outside the card so it doesn't cover the previews.
                            .offset(x: 4, y: -4)
                            .accessibilityLabel("Selected")
                    }
                }

            }
            .padding(4)
        }
        .buttonStyle(.plain)
    }
}

#Preview("App Icon Settings") {
    NavigationStack {
        AppIconSettingsView()
            .background(Color(.systemGroupedBackground))
    }
}


// MARK: - Appearance Mode Settings

struct AppearanceModeSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @Environment(\.dismiss) private var dismiss
    @AppStorage("themeColor") private var themeColor: Int = 7
    @Environment(\.colorScheme) private var systemColorScheme

    private var accentColor: Color {
        switch themeColor {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        case 6: return .purple
        case 7:
            // Mono accent for previews: black in light, white in dark
            return systemColorScheme == .dark ? .white : .black
        default:
            return .accentColor
        }
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
                                    ? [Color.black, Color(red: 0.05, green: 0.05, blue: 0.12)]
                                    : [Color.white, Color(red: 0.94, green: 0.96, blue: 1.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.black.opacity(isDark ? 0.4 : 0.15),
                                radius: 8, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    isSelected ? accentColor.opacity(0.6) : Color.primary.opacity(0.2),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                    
                    // Accent-colored blobs to preview the main screen look
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.45), Color.clear],
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
