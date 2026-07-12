//
//  InfoView.swift
//  DiscountCalculator
//
//  About screen styled after Day Calculator: glass card with app icon,
//  version/build info, developer credit, tappable company logo grid,
//  and external-link confirmation.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"
    @AppStorage("suppressExternalLinkWarning") private var suppressExternalLinkWarning: Bool = false

    @State private var showDiscountDestinationOptions: Bool = false
    @State private var showExternalLinkWarningAlert: Bool = false
    @State private var pendingExternalURL: URL? = nil

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

    private var quickerTipperLogoAssetName: String {
        "QuickerTipperLogo(\(appearanceToken))(\(tintToken))"
    }

    private var discountCalculatorLogoAssetName: String {
        discountCalculatorLogoName(
            appearance: discountCalculatorLogoAppearance(for: colorScheme),
            color: tintToken
        )
    }

    /// Logo variant that matches the user's currently selected app icon.
    private var currentAppIconPreviewName: String {
        discountCalculatorLogoName(
            appearance: discountCalculatorLogoAppearance(for: colorScheme),
            color: discountCalculatorLogoColor(forAppIconName: selectedAppIconName)
        )
    }

    // MARK: - URLs

    private let websiteURL = URL(string: "https://www.sonnazgroup.com")
    private let webAppURL = URL(string: "https://sonnazgroup.com/discount-calculator")
    private let privacyURL = URL(string: "https://www.sonnazgroup.com/privacy")
    private let termsURL = URL(string: "https://www.sonnazgroup.com/terms")
    private let supportEmail = "support@sonnazgroup.com"
    private let discountCalculatorURL = URL(string: "https://sonnazgroup.com/discount-calculator")
    private let quickerTipperURL = URL(string: "https://sonnazgroup.com/quicker-tipper")

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CalculatorBackground(accentColor: accentColor, colorScheme: colorScheme)
                contentLayer
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Leave Discount Calculator?", isPresented: $showExternalLinkWarningAlert) {
                Button("Continue") { openPendingExternalLink() }
                Button("Continue and Don't Show Again") {
                    suppressExternalLinkWarning = true
                    openPendingExternalLink()
                }
                Button("Cancel", role: .cancel) { clearPendingExternalLink() }
            } message: {
                Text("You are opening an external link outside the app:\n\n\(pendingExternalURL?.absoluteString ?? "")")
            }
            .tint(.primary)
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
        .tint(accentColor)
    }

    private var contentLayer: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                appCard
                linksSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 25)
        }
    }

    // MARK: - App card

    private var appCard: some View {
        VStack(spacing: 20) {
            // App icon showcase
            Image(currentAppIconPreviewName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(20)
                .frame(width: 180, height: 180)
                .glassCard(accentColor: accentColor, cornerRadius: 32, emphasized: true)

            // App title
            VStack(spacing: 0) {
                Text("Discount")
                Text("Calculator")
            }
            .font(.system(size: 30, weight: .heavy, design: .default))
            .foregroundColor(colorScheme == .dark ? .white : .primary)

            // Accent divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.8), accentColor.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .padding(.horizontal, 40)

            // Version & about info
            VStack(spacing: 16) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(Bundle.main.releaseVersionNumber ?? "1.0.0")")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)

                HStack {
                    Text("Build Number")
                    Spacer()
                    Text("\(Bundle.main.buildVersionNumber ?? "1")")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Developer")
                            .font(.subheadline)
                        Spacer(minLength: 0)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Sonnaz Group, LLC")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Text("© 2026. All Rights Reserved")
                            .foregroundColor(.secondary)
                            .font(.footnote)
                    }
                }

                // Company + apps — tappable logos
                ViewThatFits(in: .horizontal) {
                    companyAppsLogoGrid(columnCount: 3, spacing: 14, minimumTileWidth: 60)
                    companyAppsLogoGrid(
                        columnCount: 2,
                        spacing: 14,
                        minimumTileWidth: 84,
                        maximumTileWidth: 88,
                        gridMaxWidth: 190,
                        alignment: .center
                    )
                }
                .padding(.top, 8)
                .confirmationDialog("Open Discount Calculator", isPresented: $showDiscountDestinationOptions, titleVisibility: .visible) {
                    Button("Website") {
                        if let url = discountCalculatorURL {
                            openLinkWithWarning(url, title: "Discount Calculator Website")
                        }
                    }
                    Button("Web App") {
                        if let url = webAppURL {
                            openLinkWithWarning(url, title: "Discount Calculator Web App")
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Where would you like to go?")
                }
                .tint(.primary)
            }
        }
        .padding(24)
        .frame(maxWidth: 380)
        .glassCard(accentColor: accentColor, cornerRadius: 30, emphasized: true)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.18), radius: 26, x: 0, y: 18)
    }

    // MARK: - Links section

    private var linksSection: some View {
        VStack(spacing: 10) {
            infoLinkButton(title: "Website", url: websiteURL)
            infoLinkButton(title: "Web App", url: webAppURL)
            infoLinkButton(title: "Privacy Statement", url: privacyURL)
            infoLinkButton(title: "Terms & Conditions", url: termsURL)
            Button {
                openEmailSupport()
            } label: {
                Text("Email Support")
                    .font(.subheadline)
                    .foregroundColor(accentColor)
                    .underline()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Logo grid

    private func companyAppsLogoGrid(
        columnCount: Int,
        spacing: CGFloat,
        minimumTileWidth: CGFloat,
        maximumTileWidth: CGFloat? = nil,
        gridMaxWidth: CGFloat? = nil,
        alignment: Alignment = .leading
    ) -> some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: minimumTileWidth), spacing: spacing), count: columnCount)

        return LazyVGrid(columns: columns, spacing: spacing) {
            logoTile(imageName: sonnazGroupLogoAssetName, maximumTileWidth: maximumTileWidth) {
                if let url = websiteURL {
                    openLinkWithWarning(url, title: "Sonnaz Group Website")
                }
            }
            logoTile(imageName: discountCalculatorLogoAssetName, maximumTileWidth: maximumTileWidth) {
                showDiscountDestinationOptions = true
            }
            logoTile(imageName: quickerTipperLogoAssetName, maximumTileWidth: maximumTileWidth) {
                if let url = quickerTipperURL {
                    openLinkWithWarning(url, title: "Quicker Tipper")
                }
            }
        }
        .frame(maxWidth: gridMaxWidth ?? .infinity, alignment: alignment)
        .frame(maxWidth: .infinity, alignment: alignment)
    }

    private func logoTile(
        imageName: String,
        maximumTileWidth: CGFloat? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .padding(10)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .glassCard(accentColor: accentColor, cornerRadius: 18)
        }
        .frame(maxWidth: maximumTileWidth)
        .buttonStyle(.plain)
    }

    private func infoLinkButton(title: String, url: URL?) -> some View {
        Button {
            if let url {
                openLinkWithWarning(url, title: title)
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .foregroundColor(accentColor)
                .underline()
                .frame(maxWidth: .infinity)
        }
        .disabled(url == nil)
        .opacity(url == nil ? 0.4 : 1.0)
    }

    // MARK: - External links

    private func openEmailSupport() {
        let encoded = supportEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? supportEmail
        if let url = URL(string: "mailto:\(encoded)") {
            openLinkWithWarning(url, title: "Email Support")
        }
    }

    private func openLinkWithWarning(_ url: URL, title: String? = nil) {
        if suppressExternalLinkWarning {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        pendingExternalURL = url
        showExternalLinkWarningAlert = true
    }

    private func openPendingExternalLink() {
        guard let url = pendingExternalURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        clearPendingExternalLink()
    }

    private func clearPendingExternalLink() {
        pendingExternalURL = nil
        showExternalLinkWarningAlert = false
    }
}

private extension Bundle {
    var releaseVersionNumber: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }
}

// MARK: - Previews

#Preview("Info – Light") {
    InfoView()
        .preferredColorScheme(.light)
}

#Preview("Info – Dark") {
    InfoView()
        .preferredColorScheme(.dark)
}
