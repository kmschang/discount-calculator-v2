import SwiftUI
import UIKit

/// The calculator's main workspace. The result stays visible while the editable
/// receipt below it scrolls, so changes always have immediate visual feedback.
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
        AppTheme.accentColor(
            themeColor: themeColor,
            appearanceMode: appearanceMode,
            systemScheme: colorScheme
        )
    }

    private var result: CalculationResult {
        store.result(roundToCents: roundToCents, taxOnOriginal: taxOnOriginal)
    }

    private var positiveColor: Color {
        AppTheme.positiveColor
    }

    private var negativeColor: Color {
        AppTheme.negativeColor
    }

    private var currencyCode: String { AppFormat.currencyCode }

    var body: some View {
        @Bindable var store = store

        ZStack {
            CalculatorBackground(accentColor: accentColor, colorScheme: colorScheme)
                .allowsHitTesting(false)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    resultCard
                    priceCard($store)
                    discountsCard($store)
                    taxCard($store)
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 18)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.clear)
            .animation(.snappy, value: store.discounts)
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

    // MARK: - Result

    private var resultCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("FINAL PRICE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)

                    if result.savings > 0 {
                        Label(
                            "\(AppFormat.percent(result.effectiveDiscountPercent))% saved",
                            systemImage: "arrow.down.right"
                        )
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(positiveColor)
                        .contentTransition(.numericText())
                    } else {
                        Text("Your total updates as you type")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 8)

                resultAction(
                    systemName: justCopied ? "checkmark" : "doc.on.doc",
                    accessibilityLabel: justCopied ? "Copied" : "Copy total",
                    isEnabled: result.total > 0,
                    action: copyTotal
                )

                resultAction(
                    systemName: "arrow.counterclockwise",
                    accessibilityLabel: "Start over",
                    isEnabled: store.hasInput
                ) {
                    withAnimation(.snappy) { store.startOver() }
                    focusedField = nil
                }
            }

            Text(result.total, format: .currency(code: currencyCode))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.42)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: result.total)
                .frame(maxWidth: .infinity, minHeight: 62, maxHeight: 62)

            HStack(spacing: 0) {
                resultMetric(
                    title: "LIST PRICE",
                    value: result.original,
                    strikethrough: result.savings > 0
                )
                metricDivider
                resultMetric(title: "DISCOUNT", value: result.savings, positive: result.savings > 0)
                metricDivider
                resultMetric(
                    title: taxMetricTitle,
                    value: result.taxAmount,
                    negative: result.taxAmount > 0
                )
            }
            .padding(.vertical, 10)
            .background(insetSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassCard(accentColor: accentColor, cornerRadius: 30, emphasized: true)
        .accessibilityElement(children: .contain)
    }

    private func resultAction(
        systemName: String,
        accessibilityLabel: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accentColor)
                .frame(width: 38, height: 38)
                .background(insetSurface, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.35)
        .accessibilityLabel(accessibilityLabel)
    }

    private var taxMetricTitle: String {
        result.taxRatePercent > 0
            ? "TAX · \(AppFormat.percent(result.taxRatePercent))%"
            : "TAX"
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(.primary.opacity(0.09))
            .frame(width: 1, height: 30)
    }

    private func resultMetric(
        title: String,
        value: Double,
        positive: Bool = false,
        negative: Bool = false,
        strikethrough: Bool = false
    ) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.5)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(value, format: .currency(code: currencyCode))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(positive ? positiveColor : (negative ? negativeColor : Color.primary))
                .strikethrough(strikethrough)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Price

    private func priceCard(_ store: Bindable<CalculatorStore>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "cart.fill", title: "Original Price", eyebrow: "START HERE")

            HStack(spacing: 10) {
                Text(AppFormat.currencySymbol)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("0.00", text: store.priceText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .price)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.trailing)
                    .minimumScaleFactor(0.7)
                    .digitLimit(.price, text: store.priceText)
            }
            .padding(.horizontal, 16)
            .frame(height: 62)
            .background(insetSurface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(focusedField == .price ? accentColor.opacity(0.7) : .clear, lineWidth: 1.5)
            }
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .price }
        }
        .sectionCard(accentColor: accentColor)
    }

    // MARK: - Discounts

    private func discountsCard(_ store: Bindable<CalculatorStore>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                sectionHeader(icon: "tag.fill", title: "Discounts", eyebrow: "STACK UP TO FOUR")
                Spacer()
                if result.savings > 0 {
                    Text("−\(AppFormat.percent(result.effectiveDiscountPercent))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(positiveColor)
                        .monospacedDigit()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(positiveColor.opacity(0.11), in: Capsule())
                }
            }

            if self.store.discounts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "tag.slash")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    Text("No discounts added")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            } else {
                VStack(spacing: 8) {
                    ForEach(store.discounts) { $entry in
                        discountRow($entry)
                    }
                }
            }

            if self.store.canAddDiscount {
                Button {
                    withAnimation(.snappy) {
                        if let id = self.store.addDiscountRow() {
                            focusedField = .discount(id)
                        }
                    }
                } label: {
                    Label(
                        self.store.discounts.isEmpty ? "Add a Discount" : "Add Another Discount",
                        systemImage: "plus"
                    )
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accentColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if self.store.discounts.filter({ $0.kind == .percent }).count >= 2 {
                Label(
                    "Percent discounts compound in the order shown.",
                    systemImage: "info.circle.fill"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .sectionCard(accentColor: accentColor)
    }

    private func discountRow(_ entry: Binding<DiscountEntry>) -> some View {
        HStack(spacing: 10) {
            Picker("Discount type", selection: entry.kind) {
                Text("%").tag(DiscountKind.percent)
                Text(AppFormat.currencySymbol).tag(DiscountKind.amount)
            }
            .pickerStyle(.segmented)
            .frame(width: 92)
            .onChange(of: entry.wrappedValue.kind) { _, newKind in
                // A dollar amount can hold more digits than a percent, so trim
                // anything the new kind wouldn't have allowed you to type.
                let limit: AppFormat.NumberLimit = newKind == .percent ? .percentOff : .amountOff
                entry.valueText.wrappedValue = limit.clamped(entry.valueText.wrappedValue)
            }

            HStack(spacing: 5) {
                if entry.wrappedValue.kind == .amount {
                    Text(AppFormat.currencySymbol)
                        .foregroundStyle(.secondary)
                }

                TextField(
                    entry.wrappedValue.kind == .percent ? "20" : "5.00",
                    text: entry.valueText
                )
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .discount(entry.wrappedValue.id))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.trailing)
                .digitLimit(entry.wrappedValue.limit, text: entry.valueText)

                if entry.wrappedValue.kind == .percent {
                    Text("%")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.headline)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(insetSurface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        focusedField == .discount(entry.wrappedValue.id)
                            ? accentColor.opacity(0.7)
                            : .clear,
                        lineWidth: 1.5
                    )
            }

            Button {
                withAnimation(.snappy) { store.removeDiscount(entry.wrappedValue) }
            } label: {
                Image(systemName: "minus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(.primary.opacity(0.07), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove discount")
        }
    }

    // MARK: - Sales tax

    private func taxCard(_ store: Bindable<CalculatorStore>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(
                icon: "building.columns.fill",
                title: "Sales Tax",
                eyebrow: "OPTIONAL"
            )

            Button {
                isStatePickerPresented = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: self.store.taxState == nil ? "map" : "mappin.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tax location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(taxSourceLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .frame(height: 56)
                .background(insetSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Pick a state")

            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    TextField("0", text: store.taxRateText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .tax)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .multilineTextAlignment(.trailing)
                        .digitLimit(.taxRate, text: store.taxRateText)
                    Text("%")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(insetSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(focusedField == .tax ? accentColor.opacity(0.7) : .clear, lineWidth: 1.5)
                }

                Button(action: detectLocation) {
                    HStack(spacing: 7) {
                        if location.isResolving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "location.fill")
                        }
                        Text("Use Local")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 15)
                    .frame(height: 46)
                    .background(accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(location.isResolving)
                .accessibilityLabel("Use my location for sales tax")
            }

            Text(taxStatusLine)
                .font(.caption)
                .foregroundStyle(location.lastError == nil ? Color.secondary : Color.red)
                .fixedSize(horizontal: false, vertical: true)
        }
        .sectionCard(accentColor: accentColor)
    }

    private var taxSourceLabel: String {
        if let state = store.taxState { return state.name }
        return store.taxRatePercent > 0 ? "Custom rate" : "Choose a state"
    }

    private var taxStatusLine: String {
        if location.isResolving { return "Finding your state…" }
        if let error = location.lastError { return error }
        if let state = store.taxState {
            if state.hasNoStateSalesTax { return "\(state.name) has no state sales tax." }
            return "Using the \(state.name) base rate. Local rates may vary."
        }
        if store.taxRatePercent > 0 { return "Using a custom rate. Use Local to restore your state's rate." }
        return "Enter a rate, choose a state, or use your current location."
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

    // MARK: - State picker

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

    // MARK: - Shared presentation

    private var insetSurface: Color {
        colorScheme == .dark ? Color.white.opacity(0.065) : Color.black.opacity(0.045)
    }

    private func sectionHeader(
        icon: String,
        title: String,
        eyebrow: String
    ) -> some View {
        return HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(accentColor)
                .frame(width: 34, height: 34)
                .background(accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(eyebrow)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(.tertiary)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
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

private extension View {
    func sectionCard(accentColor: Color) -> some View {
        self
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard(accentColor: accentColor, cornerRadius: 22)
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
