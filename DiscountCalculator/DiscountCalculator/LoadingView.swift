//
//  LoadingView.swift
//  DiscountCalculator
//
//  Loading screen aligned with Day Calculator: a neutral brand tile, soft
//  accent glow, custom glass card, loading animation, and company footer.
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("themeColor") private var storedThemeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    private let previewThemeColor: Int?
    private let animates: Bool
    private let logoName = "DiscountCalculatorLogo(Transparent)"

    init(previewThemeColor: Int? = nil, animates: Bool = true) {
        self.previewThemeColor = previewThemeColor
        self.animates = animates
    }

    // MARK: - Theme

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: colorScheme)
    }

    private var themeColor: Int {
        previewThemeColor ?? storedThemeColor
    }

    private var secondaryBlobColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.24)
            : Color.black.opacity(0.12)
    }

    // MARK: - Body

    var body: some View {
        let isDarkMode = (colorScheme == .dark)

        ZStack {
            Group {
                if isDarkMode {
                    RadialGradient(
                        colors: [
                            Color.black,
                            Color(red: 0.02, green: 0.02, blue: 0.06),
                            Color(red: 0.08, green: 0.0, blue: 0.15)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 600
                    )
                } else {
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.94, green: 0.95, blue: 0.98)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .ignoresSafeArea()

            Circle()
                .fill(accentColor.opacity(0.35))
                .blur(radius: 120)
                .offset(x: -120, y: -260)

            Circle()
                .fill(secondaryBlobColor)
                .blur(radius: 120)
                .offset(x: 140, y: 260)

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.55), radius: 40, x: 0, y: 30)

                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.7),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .blendMode(.overlay)

                    VStack(spacing: 24) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color(red: 0.035, green: 0.04, blue: 0.075))

                            Circle()
                                .fill(accentColor.opacity(0.44))
                                .frame(width: 210, height: 210)
                                .blur(radius: 72)
                                .offset(x: -72, y: -72)

                            Circle()
                                .fill(Color.white.opacity(0.07))
                                .frame(width: 180, height: 180)
                                .blur(radius: 62)
                                .offset(x: 86, y: 94)

                            Image(logoName)
                                .resizable()
                                .scaledToFit()
                                .padding(24)
                        }
                        .frame(width: 256, height: 256)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.42),
                                            accentColor.opacity(0.30)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.2
                                )
                        }
                        .shadow(
                            color: Color.black.opacity(isDarkMode ? 0.38 : 0.18),
                            radius: 16,
                            x: 0,
                            y: 12
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Discount Calculator")

                        VStack(spacing: 8) {
                            Text("Preparing Discount Calculator…")
                                .font(.system(size: 22, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)

                            Text("Making sure everything is ready for you.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        BouncingDots(color: accentColor, isDark: isDarkMode, animates: animates)
                            .padding(.top, 24)
                    }
                    .padding(24)
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack {
                    Text("Sonnaz Group, LLC")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary.opacity(0.75))

                    Text("© 2026. All Rights Reserved")
                        .font(.caption2)
                        .foregroundColor(.primary.opacity(0.50))
                        .padding(.bottom, 6)

                    Text("For Grandma 💙")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary.opacity(0.75))
                }
                .padding(.bottom, 30)
            }
            .frame(maxWidth: 500)
        }
    }
}

// MARK: - Loading Animation

private struct BouncingDots: View {
    let color: Color
    let isDark: Bool
    let animates: Bool
    @State private var animate = false

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isDark ? 0.95 : 0.90),
                                color.opacity(isDark ? 0.60 : 0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 10)
                    .shadow(color: color.opacity(isDark ? 0.50 : 0.25), radius: 6, x: 0, y: 2)
                    .offset(y: animate ? -6 : 6)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(0.12 * Double(index)),
                        value: animate
                    )
            }
        }
        .frame(height: 24)
        .onAppear {
            guard animates else { return }
            animate = true
        }
    }
}

// MARK: - Previews

#Preview("Blue – Dark") {
    LoadingView(previewThemeColor: 5, animates: false)
        .preferredColorScheme(.dark)
}

#Preview("Blue – Light") {
    LoadingView(previewThemeColor: 5, animates: false)
        .preferredColorScheme(.light)
}

#Preview("Mono – Dark") {
    LoadingView(previewThemeColor: 7, animates: false)
        .preferredColorScheme(.dark)
}

#Preview("Mono – Light") {
    LoadingView(previewThemeColor: 7, animates: false)
        .preferredColorScheme(.light)
}
