import SwiftUI
import UIKit

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
    @State private var isStatePickerPresented = false
    @State private var showDetails = false
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
                heroCard
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        priceCard
                        discountsCard
                        taxCard
                        if result.original > 0 {
                            detailsDisclosure
                        }
                        startOverButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }

                keypad
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
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
        .sheet(isPresented: $isStatePickerPresented) {
            NavigationStack {
                StatePickerView(selectedCode: store.selectedStateCode, showNoTaxOption: true) { code in
                    store.selectState(code)
                    isStatePickerPresented = false
                }
                .navigationTitle("Sales Tax")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 8) {
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

            Text(result.total, format: .currency(code: currencyCode))
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.snappy, value: result.total)
                .frame(maxWidth: .infinity)

            heroSubline
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassCard(accentColor: accentColor, cornerRadius: 26, emphasized: true)
    }

    @ViewBuilder
    private var heroSubline: some View {
        if result.original <= 0 {
            Text("Enter a price below to begin")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if result.savings > 0 {
            HStack(spacing: 6) {
                Text(result.original, format: .currency(code: currencyCode))
                    .strikethrough()
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.secondary)
                Text("You save \(result.savings.formatted(.currency(code: currencyCode)))")
                    .foregroundStyle(.green)
                Text("(\(AppFormat.percent(result.effectiveDiscountPercent))% off)")
                    .foregroundStyle(.green)
            }
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        } else {
            Text("No discounts applied")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Price

    private var priceCard: some View {
        HStack {
            Text("Price")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(store.itemAmount, format: .currency(code: currencyCode))
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
                .animation(.snappy, value: store.itemAmount)
        }
        .padding(16)
        .glassCard(accentColor: accentColor)
    }

    // MARK: - Discounts

    private var discountsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Discounts")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    isAddDiscountPresented = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
            }

            if store.discounts.isEmpty {
                Text("No discounts yet. Tap Add to apply one — or several.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(store.discounts) { discount in
                        discountChip(discount)
                    }
                }

                if store.discounts.count >= 2 {
                    Text("Discounts stack — each one comes off the price left after the one before it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .glassCard(accentColor: accentColor)
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

    // MARK: - Tax

    private var taxCard: some View {
        Button {
            isStatePickerPresented = true
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sales Tax")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(taxSubtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                if store.selectedState != nil {
                    Text("\(AppFormat.percent(result.taxRatePercent))%")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(accentColor)
                        .monospacedDigit()
                }
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(accentColor: accentColor)
    }

    private var taxSubtitle: String {
        guard let state = store.selectedState else { return "No tax — tap to choose a state" }
        if localTaxRate > 0 {
            return "\(state.name) + local tax"
        }
        return state.name
    }

    // MARK: - Details

    private var detailsDisclosure: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) { showDetails.toggle() }
            } label: {
                HStack {
                    Text("Details")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showDetails {
                VStack(spacing: 10) {
                    detailRow("Original price", result.original)
                    detailRow("Discounts", -result.savings, tint: .green)
                    detailRow("Subtotal", result.subtotal)
                    detailRow("Sales tax (\(AppFormat.percent(result.taxRatePercent))%)", result.taxAmount)
                    Divider().overlay(accentColor.opacity(0.3))
                    HStack {
                        Text("Total")
                            .font(.headline.weight(.bold))
                        Spacer()
                        Text(result.total, format: .currency(code: currencyCode))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(accentColor)
                    }
                }
                .padding([.horizontal, .bottom], 16)
            }
        }
        .glassCard(accentColor: accentColor)
    }

    private func detailRow(_ label: String, _ value: Double, tint: Color? = nil) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value, format: .currency(code: currencyCode))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint ?? .primary)
        }
    }

    // MARK: - Start over

    private var startOverButton: some View {
        Button {
            withAnimation(.snappy) {
                store.startOver()
                showDetails = false
            }
        } label: {
            Label("Start Over", systemImage: "arrow.counterclockwise")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(accentColor: accentColor, cornerRadius: 16)
        .opacity(store.hasInput ? 1 : 0.4)
        .disabled(!store.hasInput)
    }

    // MARK: - Keypad

    private var keypad: some View {
        VStack(spacing: 9) {
            ForEach(keyRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 9) {
                    ForEach(keyRows[rowIndex], id: \.self) { key in
                        Button {
                            handle(key)
                        } label: {
                            key.labelView
                                .font(.title2.weight(.bold))
                                .foregroundStyle(keyForeground(key))
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .glassCard(accentColor: accentColor, cornerRadius: 16,
                                   emphasized: key == .clear || key == .backspace)
                    }
                }
            }
        }
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
            .navigationTitle("Calculate")
            .navigationBarTitleDisplayMode(.inline)
    }
}
