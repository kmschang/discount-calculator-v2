import SwiftUI
import Observation

// MARK: - Discount

enum DiscountKind: String, Codable, Hashable {
    case percent
    case amount
}

/// One editable discount row on the main screen (up to 4). The row's text field
/// binds straight to `valueText`; `value` is whatever the text parses to.
struct DiscountEntry: Identifiable, Hashable {
    let id = UUID()
    var kind: DiscountKind = .percent
    var valueText: String = ""

    var value: Double? {
        guard let v = AppFormat.parse(valueText), v > 0 else { return nil }
        return v
    }
}

// MARK: - Result of a calculation

struct CalculationResult: Equatable {
    var original: Double
    var savings: Double            // total dollars saved by discounts
    var subtotal: Double           // after discounts, before tax
    var effectiveDiscountPercent: Double
    var taxRatePercent: Double
    var taxAmount: Double
    var total: Double              // the final "you pay" number

    static let zero = CalculationResult(original: 0, savings: 0, subtotal: 0,
                                        effectiveDiscountPercent: 0, taxRatePercent: 0,
                                        taxAmount: 0, total: 0)
}

// MARK: - Store
// Holds the transient state of the calculator. Persisted settings (round-to-cents,
// tax-on-original) live in @AppStorage and are passed into `result(...)`, so the
// computation stays a pure function of (state + settings).

@Observable
final class CalculatorStore {
    static let maxDiscounts = 4

    /// Everything the user types binds directly to these strings.
    var priceText: String = ""
    var discounts: [DiscountEntry] = []
    var taxRateText: String = ""
    /// The state that produced the current tax rate. nil = custom rate (or none).
    var taxStateCode: String? = nil

    init() {
        // Seed sample data only when launched with -DemoData (for screenshots / UI tests).
        if ProcessInfo.processInfo.arguments.contains("-DemoData") {
            priceText = "49.99"
            discounts = [
                DiscountEntry(kind: .percent, valueText: "25"),
                DiscountEntry(kind: .percent, valueText: "10"),
            ]
            applyState("CA")
        }
    }

    // MARK: Price

    var itemAmount: Double { max(0, AppFormat.parse(priceText) ?? 0) }

    var hasInput: Bool { !priceText.isEmpty || !discounts.isEmpty }

    // MARK: Discounts

    var canAddDiscount: Bool { discounts.count < Self.maxDiscounts }

    /// Adds an empty row and returns its id so the view can focus its field.
    @discardableResult
    func addDiscountRow(kind: DiscountKind = .percent) -> UUID? {
        guard canAddDiscount else { return nil }
        let entry = DiscountEntry(kind: kind)
        discounts.append(entry)
        return entry.id
    }

    func removeDiscount(_ entry: DiscountEntry) {
        discounts.removeAll { $0.id == entry.id }
    }

    func startOver() {
        priceText = ""
        discounts = []
    }

    // MARK: Tax

    var taxRatePercent: Double { max(0, AppFormat.parse(taxRateText) ?? 0) }

    var taxState: USStateTax? {
        taxStateCode.flatMap(USStateTax.byCode)
    }

    /// Sets the tax rate from a state's base rate (location fix or manual pick).
    /// Passing nil clears the tax entirely.
    func applyState(_ code: String?) {
        guard let code, let state = USStateTax.byCode(code) else {
            taxStateCode = nil
            taxRateText = ""
            return
        }
        taxStateCode = state.code
        taxRateText = AppFormat.percent(state.rate)
    }

    /// Call after the user edits the tax field: once the rate no longer matches
    /// the chosen state's base rate, it becomes a custom rate.
    func reconcileTaxSource() {
        guard let state = taxState else { return }
        if taxRatePercent != state.rate { taxStateCode = nil }
    }

    // MARK: Calculation

    func result(roundToCents: Bool, taxOnOriginal: Bool) -> CalculationResult {
        let original = itemAmount

        // Apply discounts in the order they were added.
        // Percent discounts compound (multiplicative); dollar discounts subtract.
        var running = original
        for entry in discounts {
            guard let value = entry.value else { continue }
            switch entry.kind {
            case .percent:
                running *= max(0, 1 - value / 100)
            case .amount:
                running = max(0, running - value)
            }
        }

        var subtotal = running
        let rate = taxRatePercent
        let taxBase = taxOnOriginal ? original : subtotal
        var taxAmount = taxBase * rate / 100

        if roundToCents {
            subtotal = roundCents(subtotal)
            taxAmount = roundCents(taxAmount)
        }

        var total = subtotal + taxAmount
        if roundToCents { total = roundCents(total) }

        let savings = max(0, original - subtotal)
        let effectivePct = original > 0 ? (savings / original) * 100 : 0

        return CalculationResult(
            original: original,
            savings: savings,
            subtotal: subtotal,
            effectiveDiscountPercent: effectivePct,
            taxRatePercent: rate,
            taxAmount: taxAmount,
            total: total
        )
    }

    private func roundCents(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
