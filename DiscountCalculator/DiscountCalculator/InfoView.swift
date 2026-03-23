import SwiftUI

struct InfoView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("selectedAppIconName") private var selectedAppIconName: String = "BlueAppIcon"
    @AppStorage("suppressExternalLinkWarning") private var suppressExternalLinkWarning: Bool = false
    @State private var showDiscountDestinationOptions: Bool = false
    @State private var showExternalLinkWarningAlert: Bool = false
    @State private var pendingExternalURL: URL? = nil

    private var accentColor: Color {
        switch themeColor {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        case 6: return .purple
        case 7:
            return colorScheme == .dark ? .white : .black
        default:
            return .accentColor
        }
    }

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
        return colorScheme == .dark ? "\(baseName)_Dark" : baseName
    }

    private let websiteURL = URL(string: "https://www.sonnazgroup.com")
    private let webAppURL = URL(string: "https://sonnazgroup.com/discount-calculator")
    private let privacyURL = URL(string: "https://www.sonnazgroup.com/privacy")
    private let termsURL = URL(string: "https://www.sonnazgroup.com/terms")
    private let supportEmail = "support@sonnazgroup.com"
    private let discountCalculatorURL = URL(string: "https://sonnazgroup.com/discount-calculator")
    private let quickerTipperURL = URL(string: "https://sonnazgroup.com/quicker-tipper")

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer
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
                        Image(systemName: "xmark")
                    }
                    .tint(.primary)
                }
            }
        }
        .tint(accentColor)
    }

    private var backgroundLayer: some View {
        let isDarkMode = colorScheme == .dark
        return ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [Color.black, Color(red: 0.05, green: 0.05, blue: 0.1)]
                    : [Color(red: 0.94, green: 0.96, blue: 1.0), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.40), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -150, y: -260)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [(isDarkMode ? Color.white : Color.black).opacity(0.25), Color.clear],
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 160, y: 220)
        }
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

    private var appCard: some View {
        VStack(spacing: 20) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.4 : 0.65),
                                    accentColor.opacity(0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .frame(width: 180, height: 180)
                .overlay {
                    Image(currentAppIconPreviewName)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .padding(20)
                }

            VStack(spacing: 0) {
                Text("Discount")
                Text("Calculator")
            }
            .font(.system(size: 30, weight: .heavy, design: .default))
            .foregroundColor(colorScheme == .dark ? .white : .primary)

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

                ViewThatFits(in: .horizontal) {
                    companyAppsLogoGrid(columnCount: 4, spacing: 14, minimumTileWidth: 60)
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(colorScheme == .dark ? 0.5 : 0.7), accentColor.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.18), radius: 26, x: 0, y: 18)
    }

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
            logoLinkTile(
                imageName: assetName("SonnazGroupLogo"),
                url: websiteURL,
                maximumTileWidth: maximumTileWidth
            )
            logoActionTile(imageName: assetName("DiscountCalculatorLogo"), maximumTileWidth: maximumTileWidth) {
                showDiscountDestinationOptions = true
            }
            logoLinkTile(
                imageName: assetName("DiscountCalculatorLogo"),
                url: discountCalculatorURL,
                maximumTileWidth: maximumTileWidth
            )
            logoLinkTile(
                imageName: assetName("QuickerTipperLogo"),
                url: quickerTipperURL,
                maximumTileWidth: maximumTileWidth
            )
        }
        .frame(maxWidth: gridMaxWidth ?? .infinity, alignment: alignment)
        .frame(maxWidth: .infinity, alignment: alignment)
    }

    private func logoActionTile(
        imageName: String,
        maximumTileWidth: CGFloat? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let cornerRadius: CGFloat = 18
        return Button(action: action) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(colorScheme == .dark ? 0.4 : 0.65), accentColor.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                        .padding(10)
                }
        }
        .frame(maxWidth: maximumTileWidth)
        .buttonStyle(.plain)
    }

    private func logoLinkTile(imageName: String, url: URL?, maximumTileWidth: CGFloat? = nil) -> some View {
        let cornerRadius: CGFloat = 18
        return Button {
            if let url {
                openLinkWithWarning(url)
            }
        } label: {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(colorScheme == .dark ? 0.4 : 0.65), accentColor.opacity(0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 0, style: .continuous))
                        .padding(10)
                }
        }
        .frame(maxWidth: maximumTileWidth)
        .buttonStyle(.plain)
        .opacity(url == nil ? 0.4 : 1.0)
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

#Preview("Info – Light") {
    InfoView()
        .preferredColorScheme(.light)
}

#Preview("Info – Dark") {
    InfoView()
        .preferredColorScheme(.dark)
}
