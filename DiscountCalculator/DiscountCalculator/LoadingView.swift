//
//  loadingView.swift
//  DayCalculator
//
//  Created by Kyle Schang on 12/11/25.
//

import SwiftUI
import UIKit

struct LoadingView: View {
    @State private var currentTab: Int = 0
    
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"
    private let totalTabs = 2

    // MARK: - Accent Color from Theme

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
    
    // Neutral blob color that adapts to appearance
    private var secondaryBlobColor: Color {
        if colorScheme == .dark {
            // Lighter gray for contrast on dark backgrounds
            return Color.white.opacity(0.24)
        } else {
            // Darker gray for subtle depth on light backgrounds
            return Color.black.opacity(0.12)
        }
    }
    
    // Appearance/tint helpers for logo asset naming
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

    private func assetName(_ base: String) -> String {
        "\(base)(\(appearanceToken))(\(tintToken))"
    }

    private var logoColorName: String {
        assetName("SonnazGroupLogo")
    }
    
    private var logoColorName_DiscountCalculator: String {
        assetName("DiscountCalculatorLogo")
    }
    
    private var currentAppIconPreviewName: String {
        let baseName: String
        switch selectedAppIconName {
        case "Primary":
            baseName = "BlueAppIconLogoRounded"
        case "BlueAppIcon":
            baseName = "BlueAppIconLogoRounded"
        case "GreenAppIcon":
            baseName = "GreenAppIconLogoRounded"
        case "OrangeAppIcon":
            baseName = "OrangeAppIconLogoRounded"
        case "PurpleAppIcon":
            baseName = "PurpleAppIconLogoRounded"
        case "RedAppIcon":
            baseName = "RedAppIconLogoRounded"
        case "WhiteAppIcon":
            baseName = "WhiteAppIconLogoRounded"
        case "BlackAppIcon":
            baseName = "BlackAppIconLogoRounded"
        case "YellowAppIcon":
            baseName = "YellowAppIconLogoRounded"
        default:
            baseName = "BlueAppIconLogoRounded"
        }

        // Match the current appearance (light/dark) by selecting the appropriate preview asset.
        return colorScheme == .dark ? "\(baseName)_Dark" : baseName
    }
    
    var body: some View {
        let isDarkMode = (colorScheme == .dark)
        let timer = Timer.publish(every: 45, on: .main, in: .common).autoconnect()
        
        ZStack {
            // Background changes with light / dark mode (mirrors Info view behavior)
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

            // Colored glow orbs behind the glass card
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

                // Main glass card
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.55), radius: 40, x: 0, y: 30)

                    // Shiny border
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.05)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.0
                        )
                        .blendMode(.overlay)

                    VStack(spacing: 24) {
                        // Mini gallery for app / developer photos
                        TabView(selection: $currentTab) {
                            Image(logoColorName_DiscountCalculator)
                                .resizable()
                                .frame(width: 256, height: 256, alignment: .top)
                                .padding(.bottom, 48)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(isDarkMode ? 0.35 : 0.12), radius: 10, x: 0, y: 16)
                                .tag(0)

                            Image(logoColorName)
                                .resizable()
                                .frame(width: 256, height: 256, alignment: .top)
                                .padding(.bottom, 48)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(isDarkMode ? 0.35 : 0.12), radius: 10, x: 0, y: 16)
                                .tag(1)
                        }
                        .frame(height: 304)
                        .tabViewStyle(.page)
                        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                        .padding(.top, 0)
                        .onReceive(timer) { _ in
                            withAnimation {
                                currentTab = (currentTab + 1) % totalTabs
                            }
                        }
                        .onAppear {
                            // Customize the page control dots to use the app's accent color
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
                }
                .padding(.horizontal, 24)

                Spacer()

                VStack() {
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
    let themeColor: Int
    
    init(themeColor: Int) {
        self.themeColor = themeColor
        
        // Map themeColor to a matching app icon name
        let iconName: String
        switch themeColor {
        case 1: iconName = "RedAppIcon"
        case 2: iconName = "OrangeAppIcon"
        case 3: iconName = "YellowAppIcon"
        case 4: iconName = "GreenAppIcon"
        case 5: iconName = "BlueAppIcon"
        case 6: iconName = "PurpleAppIcon"
        case 7: iconName = "WhiteAppIcon"   // Mono / neutral
        default:
            iconName = "WhiteAppIcon"
        }
        
        // These only affect the preview process
        UserDefaults.standard.set(themeColor, forKey: "themeColor")
        UserDefaults.standard.set(iconName, forKey: "selectedAppIconName")
    }
    
    var body: some View {
        LoadingView()
    }
}

#Preview("Red – Dark") {
    LoadingPreviewWrapper(themeColor: 1)
        .preferredColorScheme(.dark)
}

#Preview("Red – Light") {
    LoadingPreviewWrapper(themeColor: 1)
        .preferredColorScheme(.light)
}

#Preview("Orange – Dark") {
    LoadingPreviewWrapper(themeColor: 2)
        .preferredColorScheme(.dark)
}

#Preview("Orange – Light") {
    LoadingPreviewWrapper(themeColor: 2)
        .preferredColorScheme(.light)
}

#Preview("Yellow – Dark") {
    LoadingPreviewWrapper(themeColor: 3)
        .preferredColorScheme(.dark)
}

#Preview("Yellow – Light") {
    LoadingPreviewWrapper(themeColor: 3)
        .preferredColorScheme(.light)
}

#Preview("Green – Dark") {
    LoadingPreviewWrapper(themeColor: 4)
        .preferredColorScheme(.dark)
}

#Preview("Green – Light") {
    LoadingPreviewWrapper(themeColor: 4)
        .preferredColorScheme(.light)
}

#Preview("Blue – Dark") {
    LoadingPreviewWrapper(themeColor: 5)
        .preferredColorScheme(.dark)
}

#Preview("Blue – Light") {
    LoadingPreviewWrapper(themeColor: 5)
        .preferredColorScheme(.light)
}

#Preview("Purple – Dark") {
    LoadingPreviewWrapper(themeColor: 6)
        .preferredColorScheme(.dark)
}

#Preview("Purple – Light") {
    LoadingPreviewWrapper(themeColor: 6)
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

