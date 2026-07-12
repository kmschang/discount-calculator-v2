//
//  LoadingView.swift
//  DiscountCalculator
//
//  Loading screen styled after Day Calculator: soft gradient background with
//  blurred accent blobs, a glass card holding a rotating logo carousel,
//  bouncing-dot loading animation, and company branding footer.
//

import SwiftUI
import UIKit

struct LoadingView: View {
    @State private var currentTab: Int = 0

    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"

    private let totalTabs = 2

    // MARK: - Theme

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: colorScheme)
    }

    // Appearance/tint tokens for logo asset naming
    private var appearanceToken: String { colorScheme == .dark ? "Dark" : "Light" }

    private var tintToken: String {
        switch themeColor {
        case 1: return "Red"
        case 2: return "Orange"
        case 3: return "Yellow"
        case 4: return "Green"
        case 5: return "Blue"
        case 6: return "Purple"
        case 7: return colorScheme == .dark ? "White" : "Black"
        default: return colorScheme == .dark ? "White" : "Black"
        }
    }

    private var sonnazGroupLogoAssetName: String {
        "SonnazGroupLogo(\(appearanceToken))(\(tintToken))"
    }

    private var discountCalculatorLogoAssetName: String {
        discountCalculatorLogoName(
            appearance: discountCalculatorLogoAppearance(for: colorScheme),
            color: tintToken
        )
    }

    // MARK: - Body

    var body: some View {
        let isDarkMode = (colorScheme == .dark)
        let timer = Timer.publish(every: 45, on: .main, in: .common).autoconnect()

        ZStack {
            // Shared ambient background (gradient + blurred accent blobs)
            CalculatorBackground(accentColor: accentColor, colorScheme: colorScheme)

            VStack(spacing: 32) {
                Spacer()

                // Main glass card
                VStack(spacing: 24) {
                    // Rotating logo carousel
                    TabView(selection: $currentTab) {
                        carouselLogo(discountCalculatorLogoAssetName, isDarkMode: isDarkMode)
                            .tag(0)

                        carouselLogo(sonnazGroupLogoAssetName, isDarkMode: isDarkMode)
                            .tag(1)
                    }
                    .frame(height: 304)
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                    .onReceive(timer) { _ in
                        withAnimation {
                            currentTab = (currentTab + 1) % totalTabs
                        }
                    }
                    .onAppear {
                        // Match the page-control dots to the app's accent color
                        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(accentColor)
                        UIPageControl.appearance().pageIndicatorTintColor = UIColor(accentColor.opacity(0.25))
                    }

                    VStack(spacing: 8) {
                        Text("Preparing Discount Calculator…")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Making sure everything is ready for you.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    // Loading animation
                    BouncingDots(color: accentColor, isDark: isDarkMode)
                        .padding(.top, 24)
                }
                .padding(24)
                .glassCard(accentColor: accentColor, cornerRadius: 32, emphasized: true)
                .shadow(color: .black.opacity(isDarkMode ? 0.55 : 0.18), radius: 40, x: 0, y: 30)
                .padding(.horizontal, 24)

                Spacer()

                // Branding footer
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

    // MARK: - Pieces

    private func carouselLogo(_ imageName: String, isDarkMode: Bool) -> some View {
        Image(imageName)
            .resizable()
            .frame(width: 256, height: 256, alignment: .top)
            .padding(.bottom, 48)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color.black.opacity(isDarkMode ? 0.35 : 0.12), radius: 10, x: 0, y: 16)
    }
}

// MARK: - Loading Animation

private struct BouncingDots: View {
    let color: Color
    let isDark: Bool
    @State private var animate = false

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isDark ? 0.95 : 0.9),
                                color.opacity(isDark ? 0.6 : 0.55)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 10)
                    .shadow(color: color.opacity(isDark ? 0.5 : 0.25), radius: 6, x: 0, y: 2)
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
        .onAppear { animate = true }
    }
}

// MARK: - Previews

private struct LoadingPreviewWrapper: View {
    init(themeColor: Int) {
        // Map themeColor to a matching app icon name (preview process only)
        let iconName: String
        switch themeColor {
        case 1: iconName = "RedAppIcon"
        case 2: iconName = "OrangeAppIcon"
        case 3: iconName = "YellowAppIcon"
        case 4: iconName = "GreenAppIcon"
        case 5: iconName = "BlueAppIcon"
        case 6: iconName = "PurpleAppIcon"
        default: iconName = "WhiteAppIcon"   // Mono / neutral
        }

        UserDefaults.standard.set(themeColor, forKey: "themeColor")
        UserDefaults.standard.set(iconName, forKey: "selectedAppIconName")
    }

    var body: some View {
        LoadingView()
    }
}

#Preview("Blue – Dark") {
    LoadingPreviewWrapper(themeColor: 5)
        .preferredColorScheme(.dark)
}

#Preview("Blue – Light") {
    LoadingPreviewWrapper(themeColor: 5)
        .preferredColorScheme(.light)
}

#Preview("Mono – Dark") {
    LoadingPreviewWrapper(themeColor: 7)
        .preferredColorScheme(.dark)
}

#Preview("Mono – Light") {
    LoadingPreviewWrapper(themeColor: 7)
        .preferredColorScheme(.light)
}
