import SwiftUI
import UIKit

/// The single main screen: a receipt-style hero (price in, total out, breakdown),
/// a compact Discounts + Sales Tax tile row, and a big keypad that fills the
/// space the old tab bar used to take.
struct CalculatorView: View {
    @Environment(CalculatorStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("roundToCents") private var roundToCents: Bool = true
    @AppStorage("localTaxRate") private var localTaxRate: Double = 0
    @AppStorage("taxOnOriginal") private var taxOnOriginal: Bool = false
    @AppStorage("homeStateCode") private var homeStateCode: String = ""

    @State private var isAddDiscountPresented = false
    @State private var isTaxSheetPresented = false
    @State private var didApplyHomeState = false
    @State private var justCopied = false

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: colorScheme)
    }

    private var result: CalculationResult {
        store.result(roundToCents: roundToCents, localTaxRate: localTaxRate, taxOnOriginal: taxOnOriginal)
    }

    private var currencyCode: String { AppFormat.currencyCode }

    private let keyRows: [[CalcKey]] = [
        [.digit("1"), .digit("2"), .digit("3")],
        [.digit("4"), .digit("5"), .digit("6")],
        [.digit("7"), .digit("8"), .digit("9")],
        [.clear, .digit("0"), .backspace],
    ]

    var body: some View {
        ZStack {
            CalculatorBackground(accentColor: accentColor, colorScheme: colorScheme)

            VStack(spacing: 12) {
                // Top section is fixed-height (see heroPanel / quickTiles), so nothing
                // the user types can change its size…
                heroPanel

                quickTiles

                if !store.discounts.isEmpty {
                    discountStrip
                }

                // …and the keypad simply fills whatever space is left, as big as
                // possible, and never moves because the section above is constant.
                keypad
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)
            .animation(.snappy, value: store.discounts)
        }
        .onAppear {
            if !didApplyHomeState {
                didApplyHomeState = true
                if store.selectedStateCode == nil, !homeStateCode.isEmpty {
                    store.selectState(homeStateCode)
                }
            }
        }
        .sheet(isPresented: $isAddDiscountPresented) {
            AddDiscountView { discount in
                store.addDiscount(discount)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isTaxSheetPresented) {
            TaxPickerSheet()
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hero (price in → total out → breakdown)

    private var heroPanel: some View {
        VStack(spacing: 12) {
            // Price entry line — this is what the keypad types into.
            HStack(alignment: .firstTextBaseline) {
                Text("Price")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(store.itemAmount, format: .currency(code: currencyCode))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: store.itemAmount)
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(accentColor.opacity(0.85))
                            .frame(height: 3)
                            .offset(y: 5)
                    }
            }

            Divider()
                .overlay(accentColor.opacity(0.25))

            // The big answer.
            HStack {
                Text("You Pay")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    copyTotal()
                } label: {
                    Label(justCopied ? "Copied" : "Copy",
                          systemImage: justCopied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
                .disabled(result.total <= 0)
                .opacity(result.total <= 0 ? 0.4 : 1)
            }

            // Fixed-height box: when a long total scales down, the freed space
            // becomes a gap above the number (bottom alignment) rather than making
            // the whole tile shorter — so the keypad below never shifts.
            Text(result.total, format: .currency(code: currencyCode))
                .font(.system(size: 62, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: result.total)
                .frame(maxWidth: .infinity, minHeight: 74, maxHeight: 74, alignment: .bottom)

            // Always show the breakdown (zeros before any input) so the layout
            // stays put and never surprises the user with a new row.
            breakdownRow
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassCard(accentColor: accentColor, cornerRadius: 28, emphasized: true)
    }

    /// Always-visible one-line breakdown: what it was, what you save, the tax.
    private var breakdownRow: some View {
        HStack(spacing: 8) {
            breakdownItem(label: "Before",
                          value: result.original,
                          tint: .secondary,
                          strikethrough: result.savings > 0)
            breakdownDivider
            breakdownItem(label: savingsLabel,
                          value: result.savings,
                          tint: result.savings > 0 ? .green : .secondary)
            breakdownDivider
            breakdownItem(label: "Tax",
                          value: result.taxAmount,
                          tint: result.taxAmount > 0 ? .primary : .secondary)
        }
    }

    private var savingsLabel: String {
        result.savings > 0 ? "You Save (\(AppFormat.percent(result.effectiveDiscountPercent))%)" : "You Save"
    }

    private var breakdownDivider: some View {
        Rectangle()
            .fill(accentColor.opacity(0.2))
            .frame(width: 1, height: 30)
    }

    private func breakdownItem(label: String, value: Double, tint: Color, strikethrough: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value, format: .currency(code: currencyCode))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .strikethrough(strikethrough)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick tiles (Discounts + Sales Tax, side by side)

    private var quickTiles: some View {
        HStack(spacing: 12) {
            quickTile(icon: "tag.fill",
                      title: "Discounts",
                      subtitle: discountsSubtitle,
                      badge: store.discounts.isEmpty ? nil : "\(store.discounts.count)") {
                isAddDiscountPresented = true
            }

            quickTile(icon: "building.columns.fill",
                      title: "Sales Tax",
                      subtitle: taxSubtitle,
                      badge: store.selectedState != nil ? "\(AppFormat.percent(result.taxRatePercent))%" : nil) {
                isTaxSheetPresented = true
            }
        }
    }

    private func quickTile(icon: String, title: String, subtitle: String, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(accentColor)
                    Spacer()
                    if let badge {
                        Text(badge)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(accentColor)
                            .monospacedDigit()
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(accentColor: accentColor, cornerRadius: 20)
    }

    private var discountsSubtitle: String {
        if store.discounts.isEmpty { return "Tap to add one" }
        return store.discounts.count == 1 ? "1 discount applied" : "\(store.discounts.count) discounts stack"
    }

    private var taxSubtitle: String {
        guard let state = store.selectedState else { return "None — tap to choose" }
        if localTaxRate > 0 { return "\(state.name) + local" }
        return state.name
    }

    // MARK: - Discount chip strip

    private var discountStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.discounts) { discount in
                    discountChip(discount)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    private func discountChip(_ discount: Discount) -> some View {
        HStack(spacing: 6) {
            Text(discount.shortLabel)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
            Button {
                store.removeDiscount(discount)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .glassCard(accentColor: accentColor, cornerRadius: 14, emphasized: true)
    }

    // MARK: - Keypad

    private var keypad: some View {
        VStack(spacing: 10) {
            ForEach(keyRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 10) {
                    ForEach(keyRows[rowIndex], id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
        // Fill all leftover vertical space so the keys are as large as they can be.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func keyButton(_ key: CalcKey) -> some View {
        Button {
            handle(key)
        } label: {
            key.labelView
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(keyForeground(key))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 48)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(accentColor: accentColor, cornerRadius: 18,
                   emphasized: key == .clear || key == .backspace)
    }

    private func handle(_ key: CalcKey) {
        switch key {
        case .digit(let d): store.addDigit(d)
        case .clear: store.clearAmount()
        case .backspace: store.backspace()
        }
    }

    private func keyForeground(_ key: CalcKey) -> Color {
        switch key {
        case .clear: return .red
        case .backspace: return accentColor
        case .digit: return .primary
        }
    }

    // MARK: - Copy

    private func copyTotal() {
        UIPasteboard.general.string = result.total.formatted(.currency(code: currencyCode))
        withAnimation(.snappy) { justCopied = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run { withAnimation(.snappy) { justCopied = false } }
        }
    }
}

// MARK: - Tax sheet (folds in the old Tax by State tab)
// "Use my location" + the full state list, in one sheet.

private struct TaxPickerSheet: View {
    @Environment(CalculatorStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var systemScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("homeStateCode") private var homeStateCode: String = ""

    @ObservedObject private var location = LocationManager.shared

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: systemScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CalculatorBackground(accentColor: accentColor, colorScheme: systemScheme)

                VStack(spacing: 10) {
                    useMyLocationButton
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                    StatePickerView(selectedCode: store.selectedStateCode, showNoTaxOption: true) { code in
                        store.selectState(code)
                        homeStateCode = code ?? ""
                        dismiss()
                    }
                }
            }
            .navigationTitle("Sales Tax")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(.primary)
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
}

// MARK: - Keypad key

private enum CalcKey: Hashable {
    case digit(String)
    case clear
    case backspace

    @ViewBuilder
    var labelView: some View {
        switch self {
        case .digit(let d): Text(d)
        case .clear: Image(systemName: "xmark")
        case .backspace: Image(systemName: "delete.left")
        }
    }
}

#Preview("Calculator") {
    NavigationStack {
        CalculatorView()
            .environment(CalculatorStore())
            .navigationTitle("Discount Calculator")
            .navigationBarTitleDisplayMode(.inline)
    }
}
