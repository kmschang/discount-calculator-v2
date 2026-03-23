//
//  AccentColorSettingsView.swift
//  DayCalculator
//
//  Created by Kyle Schang on 12/10/25.
//

import SwiftUI

struct AccentColorSettingsView: View {
    @AppStorage("themeColor") private var themeColor: Int = 7
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemColorScheme

    private struct ColorOption: Identifiable {
        let id: Int
        let name: String
        let baseColor: Color
        let themeImageName: String
    }

    private let options: [ColorOption] = [
        ColorOption(id: 1, name: "Red", baseColor: .red, themeImageName: "RedTheme"),
        ColorOption(id: 2, name: "Orange", baseColor: .orange, themeImageName: "OrangeTheme"),
        ColorOption(id: 3, name: "Yellow", baseColor: .yellow, themeImageName: "YellowTheme"),
        ColorOption(id: 4, name: "Green", baseColor: .green, themeImageName: "GreenTheme"),
        ColorOption(id: 5, name: "Blue", baseColor: .blue, themeImageName: "BlueTheme"),
        ColorOption(id: 6, name: "Purple", baseColor: .purple, themeImageName: "PurpleTheme"),
        ColorOption(id: 7, name: "Black / White", baseColor: .primary, themeImageName: "BlackTheme")
    ]

    private var colorOptions: [ColorOption] {
        options.filter { $0.id != 7 }
    }

    private var monoOption: ColorOption {
        options.first(where: { $0.id == 7 }) ?? options[0]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                    ForEach(colorOptions) { option in
                        AccentColorPreviewCard(
                            displayName: option.name,
                            imageName: option.themeImageName,
                            isSelected: themeColor == option.id,
                            accentColor: option.baseColor
                        ) {
                            themeColor = option.id
                            dismiss()
                        }
                    }
                }

                AccentColorPreviewCard(
                    displayName: monoDisplayName,
                    imageName: monoThemeImageName,
                    isSelected: themeColor == monoOption.id,
                    accentColor: monoPreviewColor,
                    fullWidth: true
                ) {
                    themeColor = monoOption.id
                    dismiss()
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
        .navigationTitle("Accent Color")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monoDisplayName: String {
        systemColorScheme == .dark ? "White" : "Black"
    }

    private var monoThemeImageName: String {
        systemColorScheme == .dark ? "WhiteTheme" : "BlackTheme"
    }

    private var monoPreviewColor: Color {
        systemColorScheme == .dark ? .white : .black
    }
}

private struct AccentColorPreviewCard: View {
    let displayName: String
    let imageName: String
    let isSelected: Bool
    let accentColor: Color
    var fullWidth: Bool = false
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

                    Image(imageName)
                        .resizable()
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 78, height: 78)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.72), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                }
                .frame(height: 110)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, accentColor)
                            .offset(x: 4, y: -4)
                            .accessibilityLabel("Selected")
                    }
                }

                Text(displayName)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? accentColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(4)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .gridCellColumns(fullWidth ? 2 : 1)
    }
}

#Preview("Accent Color Settings") {
    NavigationStack {
        AccentColorSettingsView()
            .background(Color(.systemGroupedBackground))
    }
}

