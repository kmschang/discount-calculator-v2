import SwiftUI

/// Settings sub-screen: pick the state whose tax is used by default.
struct HomeStateSettingsView: View {
    @AppStorage("homeStateCode") private var homeStateCode: String = ""
    @Environment(\.dismiss) private var dismiss

    private var homeCode: String? { homeStateCode.isEmpty ? nil : homeStateCode }

    var body: some View {
        StatePickerView(selectedCode: homeCode, showNoTaxOption: true) { code in
            homeStateCode = code ?? ""
            dismiss()
        }
        .navigationTitle("Home State")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Settings sub-screen: an extra local/city/county tax percentage added on top
/// of the chosen state's base rate, so totals can match a real receipt.
struct LocalTaxSettingsView: View {
    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("localTaxRate") private var localTaxRate: Double = 0
    @Environment(\.colorScheme) private var systemScheme

    @State private var text: String = ""

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: systemScheme)
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("0", text: $text)
                        .keyboardType(.decimalPad)
                        .font(.title2.weight(.semibold))
                        .onChange(of: text) { _, newValue in
                            let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
                            localTaxRate = max(0, Double(cleaned) ?? 0)
                        }
                    Text("%")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Local tax added on top")
            } footer: {
                Text("Many cities and counties add their own sales tax on top of the state rate. Enter that extra percentage here and it will be added to whichever state you pick. Leave at 0 if you're not sure.")
            }

            Section {
                Button("Clear local tax") {
                    text = ""
                    localTaxRate = 0
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Local Tax")
        .navigationBarTitleDisplayMode(.inline)
        .tint(accentColor)
        .onAppear {
            if localTaxRate > 0 { text = AppFormat.percent(localTaxRate) }
        }
    }
}
