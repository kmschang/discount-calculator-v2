import SwiftUI

/// A searchable list of US states + DC with big, easy-to-tap rows.
/// Reused both as a sheet (from the Calculate tab) and inline (the Tax by State tab).
struct StatePickerView: View {
    @AppStorage("themeColor") private var themeColor: Int = 5
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @Environment(\.colorScheme) private var systemScheme

    let selectedCode: String?
    let showNoTaxOption: Bool
    let onSelect: (String?) -> Void

    @State private var searchText = ""

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: systemScheme)
    }

    private var filteredStates: [USStateTax] {
        guard !searchText.isEmpty else { return USStateTax.all }
        return USStateTax.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            if showNoTaxOption && searchText.isEmpty {
                Section {
                    row(title: "No sales tax",
                        subtitle: "Don't add any tax",
                        trailing: nil,
                        isSelected: selectedCode == nil) {
                        onSelect(nil)
                    }
                }
            }

            Section {
                ForEach(filteredStates) { state in
                    row(title: state.name,
                        subtitle: rateSubtitle(for: state),
                        trailing: "\(AppFormat.percent(state.rate))%",
                        isSelected: selectedCode == state.code) {
                        onSelect(state.code)
                    }
                }
            } header: {
                Text("Choose a state")
            } footer: {
                Text("Rates are approximate state base rates. Many areas add city or county tax on top — after picking, you can edit the rate on the main screen to match your receipt.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search states")
        .tint(accentColor)
    }

    private func rateSubtitle(for state: USStateTax) -> String {
        state.hasNoStateSalesTax ? "No state sales tax" : "State base rate"
    }

    @ViewBuilder
    private func row(title: String, subtitle: String, trailing: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let trailing {
                    Text(trailing)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(isSelected ? accentColor : .primary)
                        .monospacedDigit()
                }
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? accentColor : Color.secondary.opacity(0.4))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("State Picker") {
    NavigationStack {
        StatePickerView(selectedCode: "CA", showNoTaxOption: true) { _ in }
            .navigationTitle("Sales Tax")
    }
}
