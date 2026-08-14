//
//  AccentColorSettingsView.swift
//  DiscountCalculator
//
//  Accent picker. The swatches and the preview are drawn from the theme
//  palette rather than pre-rendered "*Theme" images, so the page always
//  reflects the real accent color and needs no artwork to stay in sync.
//

import SwiftUI

struct AccentColorSettingsView: View {
    let onDone: (() -> Void)?

    @AppStorage("themeColor") private var themeColor: Int = 7
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    init(onDone: (() -> Void)? = nil) {
        self.onDone = onDone
    }

    private struct ColorOption: Identifiable {
        let id: Int
        let name: String
        var isMonochrome = false
    }

    private let options: [ColorOption] = [
        ColorOption(id: 1, name: "Red"),
        ColorOption(id: 2, name: "Orange"),
        ColorOption(id: 3, name: "Yellow"),
        ColorOption(id: 4, name: "Green"),
        ColorOption(id: 5, name: "Blue"),
        ColorOption(id: 6, name: "Purple"),
        ColorOption(id: 7, name: "Black / White", isMonochrome: true)
    ]

    private var selectedAccentColor: Color {
        AppTheme.paletteColor(themeColor: themeColor, colorScheme: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                AccentLivePreview(accentColor: selectedAccentColor, colorScheme: colorScheme)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Choose your accent")
                        .font(.headline)

                    Text("See each color update the preview before you leave this page.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(options.filter { !$0.isMonochrome }) { option in
                            AccentColorChoice(
                                name: option.name,
                                subtitle: nil,
                                color: color(for: option),
                                isSelected: themeColor == option.id
                            ) {
                                select(option)
                            }
                        }
                    }

                    if let option = options.first(where: \.isMonochrome) {
                        AccentColorChoice(
                            name: option.name,
                            subtitle: "Adapts to appearance",
                            color: color(for: option),
                            isSelected: themeColor == option.id
                        ) {
                            select(option)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .navigationTitle("Accent Color")
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
            }
        }
        .tint(selectedAccentColor)
    }

    private func color(for option: ColorOption) -> Color {
        AppTheme.paletteColor(themeColor: option.id, colorScheme: colorScheme)
    }

    private func select(_ option: ColorOption) {
        withAnimation(.easeInOut(duration: 0.2)) {
            themeColor = option.id
        }
    }
}

/// A miniature of the calculator's result card, so the choice is judged on the
/// surface the accent actually appears on.
private struct AccentLivePreview: View {
    let accentColor: Color
    let colorScheme: ColorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 38, height: 38)
                    .background(accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Live Preview")
                        .font(.headline)
                    Text("How your accent looks in the app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("FINAL PRICE")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("$36.19")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                Spacer(minLength: 8)

                Text("−32.51%")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accentColor)
                    .monospacedDigit()
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(0.13), in: Capsule())
            }

            HStack(spacing: 10) {
                previewMetric(title: "List Price", value: "$49.99")
                previewMetric(title: "Discount", value: "$16.25")
                previewMetric(title: "Tax", value: "$2.45")
            }

            HStack(spacing: 7) {
                Image(systemName: "location.fill")
                Text("Use Local")
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)

                Circle()
                    .fill(accentColor.opacity(isDark ? 0.22 : 0.16))
                    .frame(width: 180, height: 180)
                    .blur(radius: 55)
                    .offset(x: -120, y: -90)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(isDark ? 0.35 : 0.75), accentColor.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(isDark ? 0.3 : 0.1), radius: 18, x: 0, y: 10)
        .animation(.easeInOut(duration: 0.2), value: colorScheme)
    }

    private func previewMetric(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(isDark ? 0.07 : 0.04), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct AccentColorChoice: View {
    let name: String
    let subtitle: String?
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.34), color],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                        .shadow(color: color.opacity(0.3), radius: 7, x: 0, y: 4)

                    Circle()
                        .strokeBorder(Color.white.opacity(0.65), lineWidth: 1)
                        .frame(width: 42, height: 42)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, color)
                        .accessibilityLabel("Selected")
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .strokeBorder(isSelected ? color : Color.primary.opacity(0.12), lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityValue(isSelected ? "Selected" : "")
    }
}

#Preview("Accent Color Settings") {
    NavigationStack {
        AccentColorSettingsView()
    }
}
