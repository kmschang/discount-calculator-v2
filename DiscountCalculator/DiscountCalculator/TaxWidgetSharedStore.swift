//
//  TaxWidgetSharedStore.swift
//  Discount Calculator
//
//  Writes a tiny snapshot of the user's home state + effective tax rate into the
//  shared App Group container so the home-screen widget can display it. The
//  widget target has its own matching reader (see the widget folder).
//
//  NOTE: for this to actually share data, the WIDGET target must also have the
//  App Group capability `group.com.schang.Discount-Calculator` enabled. Until
//  then this writes to a nil suite and the widget shows a placeholder.
//

import Foundation
import WidgetKit

/// Snapshot shared with the widget. Keep this struct in sync with the copy in
/// the widget target (they live in separate modules, so it is intentionally
/// duplicated rather than shared).
struct TaxWidgetSnapshot: Codable {
    var stateCode: String
    var stateName: String
    var totalRatePercent: Double
    var hasTax: Bool
}

enum TaxWidgetSharedStore {
    static let appGroupID = "group.com.schang.Discount-Calculator"
    static let snapshotKey = "tax_widget_snapshot"

    /// Builds and writes the snapshot from the current home state + local tax add-on.
    static func update(homeStateCode: String, localTaxRate: Double) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let snapshot: TaxWidgetSnapshot
        if !homeStateCode.isEmpty, let state = USStateTax.byCode(homeStateCode) {
            let total = state.hasNoStateSalesTax ? localTaxRate : state.rate + localTaxRate
            snapshot = TaxWidgetSnapshot(
                stateCode: state.code,
                stateName: state.name,
                totalRatePercent: total,
                hasTax: total > 0
            )
        } else {
            snapshot = TaxWidgetSnapshot(stateCode: "", stateName: "", totalRatePercent: 0, hasTax: false)
        }

        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: snapshotKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
