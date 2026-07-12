import SwiftUI
import Observation

// MARK: - Discount

enum DiscountKind: String, Codable, Hashable {
    case percent
    case amount
}

struct Discount: Identifiable, Hashable {
    let id = UUID()
    var kind: DiscountKind
    var value: Double   // percent (e.g. 20 = 20%) or dollars off (e.g. 5 = $5)

    var shortLabel: String {
        switch kind {
        case .percent: return "\(AppFormat.percent(value))% off"
        case .amount:  return "\(value.formatted(.currency(code: AppFormat.currencyCode))) off"
        }
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
// local tax, etc.) live in @AppStorage and are passed into `result(...)`, so the
// computation stays a pure function of (state + settings).

@Observable
final class CalculatorStore {
    /// Digits typed on the keypad, interpreted as cents (e.g. "1299" -> $12.99).
    var rawDigits: String = ""
    var discounts: [Discount] = []
    /// nil means "no sales tax". Otherwise a US state/DC code, e.g. "CA".
    var selectedStateCode: String? = nil

    private let maxDigits = 9

    init() {
        // Seed sample data only when launched with -DemoData (for screenshots / UI tests).
        if ProcessInfo.processInfo.arguments.contains("-DemoData") {
            rawDigits = "4999"
            discounts = [
                Discount(kind: .percent, value: 25),
                Discount(kind: .percent, value: 10),
            ]
            selectedStateCode = "CA"
        }
    }

    // MARK: Input

    var itemAmount: Double {
        guard !rawDigits.isEmpty, let cents = Double(rawDigits) else { return 0 }
        return cents / 100
    }

    var hasInput: Bool { !rawDigits.isEmpty || !discounts.isEmpty }

    func addDigit(_ digit: String) {
        if rawDigits.isEmpty && digit == "0" { return }   // no leading zeros
        guard rawDigits.count < maxDigits else { return }
        rawDigits.append(digit)
    }

    func backspace() {
        guard !rawDigits.isEmpty else { return }
        rawDigits.removeLast()
    }

    func clearAmount() {
        rawDigits = ""
    }

    func startOver() {
        rawDigits = ""
        discounts = []
    }

    // MARK: Discounts

    func addDiscount(_ discount: Discount) {
        discounts.append(discount)
    }

    func removeDiscount(_ discount: Discount) {
        discounts.removeAll { $0.id == discount.id }
    }

    // MARK: Tax

    func selectState(_ code: String?) {
        selectedStateCode = code
    }

    var selectedState: USStateTax? {
        guard let code = selectedStateCode else { return nil }
        return USStateTax.byCode(code)
    }

    /// The combined tax rate applied: state base rate + optional local add-on.
    /// Returns 0 when no state is selected.
    func appliedTaxRate(localTaxRate: Double) -> Double {
        guard let state = selectedState else { return 0 }
        return state.rate + max(0, localTaxRate)
    }

    // MARK: Calculation

    func result(roundToCents: Bool, localTaxRate: Double, taxOnOriginal: Bool) -> CalculationResult {
        let original = itemAmount

        // Apply discounts in the order they were added.
        // Percent discounts compound (multiplicative); dollar discounts subtract.
        var running = original
        for discount in discounts {
            switch discount.kind {
            case .percent:
                running *= max(0, 1 - discount.value / 100)
            case .amount:
                running = max(0, running - discount.value)
            }
        }

        var subtotal = running
        let rate = appliedTaxRate(localTaxRate: localTaxRate)
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
