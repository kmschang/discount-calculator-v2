import SwiftUI
import UIKit

/// The single main screen, redesigned around typed input instead of a keypad:
/// a pinned "You Pay" hero card, then Price / Discounts / Sales Tax cards whose
/// number fields use the system decimal keyboard. Everything lives on one page.
struct CalculatorView: View {
    @Environment(CalculatorStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("roundToCents") private var roundToCents: Bool = true
    @AppStorage("taxOnOriginal") private var taxOnOriginal: Bool = false

    // Persisted tax choice (survives launches; synced via iCloud KVS).
    @AppStorage("savedTaxRate") private var savedTaxRate: Double = -1
    @AppStorage("taxStateCode") private var savedTaxStateCode: String = ""
    // Pre-redesign key, read once to migrate an existing user's state choice.
    @AppStorage("homeStateCode") private var legacyHomeStateCode: String = ""

    @ObservedObject private var location = LocationManager.shared

    @FocusState private var focusedField: Field?
    @State private var isStatePickerPresented = false
    @State private var didRestoreTax = false
    @State private var justCopied = false

    private enum Field: Hashable {
        case price
        case discount(UUID)
        case tax
    }

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: colorScheme)
    }

    private var result: CalculationResult {
        store.result(roundToCents: roundToCents, taxOnOriginal: taxOnOriginal)
    }

    private var currencyCode: String { AppFormat.currencyCode }

    var body: some View {
        @Bindable var store = store

        ZStack {
            CalculatorBackground(accentColor: accentColor, colorScheme: colorScheme)

            VStack(spacing: 14) {
                // The answer stays pinned on top; the input cards scroll under it
                // when the keyboard is up.
                heroCard

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        priceCard($store)
                        discountsCard($store)
                        taxCard($store)
                    }
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .animation(.snappy, value: store.discounts)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .font(.headline)
            }
        }
        .onAppear(perform: restoreSavedTax)
        .onChange(of: store.taxRateText) {
            store.reconcileTaxSource()
            persistTax()
        }
        .onChange(of: store.taxStateCode) { persistTax() }
        .sheet(isPresented: $isStatePickerPresented) {
            statePickerSheet
        }
    }

    // MARK: - Hero (the big answer + breakdown)

    private var heroCard: some View {
        VStack(spacing: 10) {
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

                Button {
                    withAnimation(.snappy) { store.startOver() }
                    focusedField = nil
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)
                .disabled(!store.hasInput)
                .opacity(store.hasInput ? 1 : 0.4)
                .accessibilityLabel("Start over")
            }

            // Fixed-height box so a long total scales down instead of moving
            // the cards below.
            Text(result.total, format: .currency(code: currencyCode))
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: result.total)
                .frame(maxWidth: .infinity, minHeight: 66, maxHeight: 66)

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
            breakdownItem(label: taxBreakdownLabel,
                          value: result.taxAmount,
                          tint: result.taxAmount > 0 ? .primary : .secondary)
        }
    }

    private var savingsLabel: String {
        result.savings > 0 ? "You Save (\(AppFormat.percent(result.effectiveDiscountPercent))%)" : "You Save"
    }

    private var taxBreakdownLabel: String {
        result.taxRatePercent > 0 ? "Tax (\(AppFormat.percent(result.taxRatePercent))%)" : "Tax"
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

    // MARK: - Price card

    private func priceCard(_ store: Bindable<CalculatorStore>) -> some View {
        HStack(spacing: 12) {
            cardIcon("cart.fill")
            Text("Price")
                .font(.headline)
            Spacer()
            Text(AppFormat.currencySymbol)
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("0", text: store.priceText)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .price)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 150)
        }
        .padding(16)
        .contentShape(Rectangle())
        .onTapGesture { focusedField = .price }
        .glassCard(accentColor: accentColor, cornerRadius: 20)
    }

    // MARK: - Discounts card

    private func discountsCard(_ store: Bindable<CalculatorStore>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                cardIcon("tag.fill")
                Text("Discounts")
                    .font(.headline)
                Spacer()
                if result.savings > 0 {
                    Text("−\(AppFormat.percent(result.effectiveDiscountPercent))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.green)
                        .monospacedDigit()
                }
            }

            if self.store.discounts.isEmpty {
                Text("Add up to 4 — percent or dollars off.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(store.discounts) { $entry in
                discountRow($entry)
            }

            if self.store.canAddDiscount {
                Button {
                    withAnimation(.snappy) {
                        if let id = self.store.addDiscountRow() {
                            focusedField = .discount(id)
                        }
                    }
                } label: {
                    Label("Add Discount", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(accentColor)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if self.store.discounts.filter({ $0.kind == .percent }).count >= 2 {
                Text("Stacked percents multiply: 20% then 10% takes 28% off, not 30%.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(accentColor: accentColor, cornerRadius: 20)
    }

    private func discountRow(_ entry: Binding<DiscountEntry>) -> some View {
        HStack(spacing: 10) {
            Picker("Discount type", selection: entry.kind) {
                Text("%").tag(DiscountKind.percent)
                Text(AppFormat.currencySymbol).tag(DiscountKind.amount)
            }
            .pickerStyle(.segmented)
            .frame(width: 92)

            if entry.wrappedValue.kind == .amount {
                Text(AppFormat.currencySymbol)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            TextField(entry.wrappedValue.kind == .percent ? "20" : "5.00", text: entry.valueText)
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .discount(entry.wrappedValue.id))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .frame(width: 84)

            if entry.wrappedValue.kind == .percent {
                Text("%")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.snappy) { store.removeDiscount(entry.wrappedValue) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove discount")
        }
    }

    // MARK: - Tax card

    private func taxCard(_ store: Bindable<CalculatorStore>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                cardIcon("building.columns.fill")
                Text("Sales Tax")
                    .font(.headline)
                Spacer()
                Button {
                    isStatePickerPresented = true
                } label: {
                    HStack(spacing: 4) {
                        Text(taxSourceLabel)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(accentColor)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pick a state")
            }

            HStack(spacing: 10) {
                TextField("0", text: store.taxRateText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .tax)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .frame(width: 84)
                Text("%")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    detectLocation()
                } label: {
                    HStack(spacing: 6) {
                        if location.isResolving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text("Local")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .glassCard(accentColor: accentColor, cornerRadius: 16, emphasized: true)
                .disabled(location.isResolving)
                .accessibilityLabel("Use my location for sales tax")
            }

            Text(taxStatusLine)
                .font(.caption)
                .foregroundStyle(location.lastError == nil ? Color.secondary : Color.red)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(accentColor: accentColor, cornerRadius: 20)
    }

    private var taxSourceLabel: String {
        if let state = store.taxState { return state.name }
        return store.taxRatePercent > 0 ? "Custom" : "Pick a state"
    }

    private var taxStatusLine: String {
        if location.isResolving { return "Finding your state…" }
        if let error = location.lastError { return error }
        if let state = store.taxState {
            if state.hasNoStateSalesTax { return "\(state.name) has no state sales tax." }
            return "\(state.name) state rate. Cities can add a bit — edit it to match your receipt."
        }
        if store.taxRatePercent > 0 { return "Custom rate. Tap Local to switch back to your state's rate." }
        return "Type a rate, pick a state, or tap Local to use your location."
    }

    private func detectLocation() {
        focusedField = nil
        location.requestStateFromLocation { code in
            if let code, USStateTax.byCode(code) != nil {
                withAnimation(.snappy) { store.applyState(code) }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    // MARK: - State picker sheet

    private var statePickerSheet: some View {
        NavigationStack {
            ZStack {
                CalculatorBackground(accentColor: accentColor, colorScheme: colorScheme)
                StatePickerView(selectedCode: store.taxStateCode, showNoTaxOption: true) { code in
                    withAnimation(.snappy) { store.applyState(code) }
                    isStatePickerPresented = false
                }
            }
            .navigationTitle("Sales Tax")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isStatePickerPresented = false }
                        .tint(.primary)
                }
            }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: - Shared bits

    private func cardIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.semibold))
            .foregroundStyle(accentColor)
            .frame(width: 24)
    }

    // MARK: - Tax persistence

    /// Restores the last-used tax on first appearance (or migrates the old
    /// home-state setting). Skipped if demo data / auto-detect already set one.
    private func restoreSavedTax() {
        guard !didRestoreTax else { return }
        didRestoreTax = true
        guard store.taxRateText.isEmpty, store.taxStateCode == nil else { return }

        if savedTaxRate >= 0 {
            store.taxStateCode = savedTaxStateCode.isEmpty ? nil : savedTaxStateCode
            if savedTaxRate > 0 || !savedTaxStateCode.isEmpty {
                store.taxRateText = AppFormat.percent(savedTaxRate)
            }
        } else if !legacyHomeStateCode.isEmpty {
            store.applyState(legacyHomeStateCode)
        }
    }

    private func persistTax() {
        savedTaxRate = store.taxRatePercent
        savedTaxStateCode = store.taxStateCode ?? ""
        TaxWidgetSharedStore.update(stateCode: savedTaxStateCode, ratePercent: store.taxRatePercent)
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

#Preview("Calculator") {
    NavigationStack {
        CalculatorView()
            .environment(CalculatorStore())
            .navigationTitle("Discount Calculator")
            .navigationBarTitleDisplayMode(.inline)
    }
}
