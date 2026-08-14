//
//  InfoView.swift
//  DiscountCalculator
//
//  About sheet, redesigned: app identity up top, a short "how it works"
//  walkthrough (this is the app's only help screen), a privacy note, and
//  links — with the external-link confirmation kept.
//

import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"
    @AppStorage("suppressExternalLinkWarning") private var suppressExternalLinkWarning: Bool = false

    @State private var showExternalLinkWarningAlert: Bool = false
    @State private var pendingExternalURL: URL? = nil

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: colorScheme)
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

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                CalculatorBackground(accentColor: accentColor, colorScheme: colorScheme)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        heroCard
                        howItWorksCard
                        privacyCard
                        linksCard

                        Text("© 2026 Sonnaz Group, LLC. All rights reserved.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Leave Discount Calculator?", isPresented: $showExternalLinkWarningAlert) {
                Button("Continue", role: .destructive) {
                    openPendingExternalLink()
                }
                Button("Continue and Don't Show Again", role: .destructive) {
                    suppressExternalLinkWarning = true
                    openPendingExternalLink()
                }
                Button("Cancel", role: .cancel) {
                    clearPendingExternalLink()
                }
            } message: {
                Text("You are opening an external link outside the app:\n\n\(pendingExternalURL?.absoluteString ?? "")")
            }
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

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 14) {
            Image(currentAppIconPreviewName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(14)
                .frame(width: 128, height: 128)
                .glassCard(accentColor: accentColor, cornerRadius: 28, emphasized: true)

            Text("Discount Calculator")
                .font(.system(.title2, design: .rounded).weight(.heavy))

            Text(appVersionString)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassCard(accentColor: accentColor, cornerRadius: 12)

            Text("by Sonnaz Group, LLC")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .glassCard(accentColor: accentColor, cornerRadius: 28, emphasized: true)
    }

    // MARK: - How it works

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it works")
                .font(.headline)

            stepRow(icon: "cart.fill",
                    text: "Type the price of the item.")
            stepRow(icon: "tag.fill",
                    text: "Add up to four discounts — percent or dollars off. They stack in the order you add them.")
            stepRow(icon: "location.fill",
                    text: "Tap Local to use your state's sales tax, pick a state from the list, or type any rate.")
            stepRow(icon: "checkmark.seal.fill",
                    text: "The big number is what you'll pay at the register. Tap Copy to share it.")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(accentColor: accentColor, cornerRadius: 24)
    }

    private func stepRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(width: 28, height: 28)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Privacy note

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "hand.raised.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(accentColor)
                .frame(width: 28, height: 28)
            Text("Your location never leaves this device — it's only used to look up your state's tax rate. Rates are approximate; edit them to match your receipt.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(accentColor: accentColor, cornerRadius: 24)
    }

    // MARK: - Links

    private var linksCard: some View {
        VStack(spacing: 0) {
            linkRow(title: "Website", icon: "globe") {
                if let url = websiteURL { openLinkWithWarning(url) }
            }
            linkDivider
            linkRow(title: "Web App", icon: "safari.fill") {
                if let url = webAppURL { openLinkWithWarning(url) }
            }
            linkDivider
            linkRow(title: "Privacy Statement", icon: "lock.fill") {
                if let url = privacyURL { openLinkWithWarning(url) }
            }
            linkDivider
            linkRow(title: "Terms & Conditions", icon: "doc.text.fill") {
                if let url = termsURL { openLinkWithWarning(url) }
            }
            linkDivider
            linkRow(title: "Email Support", icon: "envelope.fill") {
                openEmailSupport()
            }
        }
        .glassCard(accentColor: accentColor, cornerRadius: 24)
    }

    private var linkDivider: some View {
        Divider()
            .overlay(accentColor.opacity(0.15))
            .padding(.leading, 56)
    }

    private func linkRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 28)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - External links

    private func openEmailSupport() {
        let encoded = supportEmail.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? supportEmail
        if let url = URL(string: "mailto:\(encoded)") {
            openLinkWithWarning(url)
        }
    }

    private func openLinkWithWarning(_ url: URL) {
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

// MARK: - Previews

#Preview("Info – Light") {
    InfoView()
        .preferredColorScheme(.light)
}

#Preview("Info – Dark") {
    InfoView()
        .preferredColorScheme(.dark)
}
