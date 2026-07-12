import SwiftUI

/// Tab 2: browse every state's sales tax and set your "home" state.
/// Picking a state here applies it to the calculator and remembers it.
struct TaxByStateView: View {
    @Environment(CalculatorStore.self) private var store
    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("homeStateCode") private var homeStateCode: String = ""
    @Environment(\.colorScheme) private var systemScheme
    @ObservedObject private var location = LocationManager.shared

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: systemScheme)
    }

    private var homeCode: String? { homeStateCode.isEmpty ? nil : homeStateCode }

    var body: some View {
        ZStack {
            CalculatorBackground(accentColor: accentColor, colorScheme: systemScheme)

            VStack(spacing: 10) {
                if let home = homeCode, let state = USStateTax.byCode(home) {
                    homeBanner(for: state)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                }

                useMyLocationButton
                    .padding(.horizontal, 16)
                    .padding(.top, homeCode == nil ? 10 : 0)

                StatePickerView(selectedCode: homeCode, showNoTaxOption: false) { code in
                    homeStateCode = code ?? ""
                    store.selectState(code)
                }
            }
        }
    }

    private var useMyLocationButton: some View {
        Button {
            detectLocation()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .foregroundStyle(accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use my location")
                        .font(.headline)
                    Text(locationSubtitle)
                        .font(.caption)
                        .foregroundStyle(location.lastError == nil ? Color.secondary : Color.red)
                }
                Spacer()
                if location.isResolving {
                    ProgressView()
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .glassCard(accentColor: accentColor)
        }
        .buttonStyle(.plain)
        .disabled(location.isResolving)
    }

    private var locationSubtitle: String {
        if location.isResolving { return "Finding your state…" }
        if let error = location.lastError { return error }
        if let name = location.lastResolvedStateName { return "Found: \(name)" }
        return "Find your state's tax automatically"
    }

    private func detectLocation() {
        location.requestStateFromLocation { code in
            if let code, USStateTax.byCode(code) != nil {
                homeStateCode = code
                store.selectState(code)
            }
        }
    }

    private func homeBanner(for state: USStateTax) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.title2)
                .foregroundStyle(accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("Your state")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(state.name)
                    .font(.title3.weight(.bold))
            }
            Spacer()
            Text(state.hasNoStateSalesTax ? "No tax" : "\(AppFormat.percent(state.rate))%")
                .font(.title3.weight(.bold))
                .foregroundStyle(accentColor)
                .monospacedDigit()
        }
        .padding(16)
        .glassCard(accentColor: accentColor, emphasized: true)
    }
}

#Preview("Tax by State") {
    NavigationStack {
        TaxByStateView()
            .navigationTitle("Tax by State")
            .environment(CalculatorStore())
    }
}
