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

    /// Builds and writes the snapshot from the tax applied on the main screen —
    /// either a state's rate or a custom typed rate.
    static func update(stateCode: String, ratePercent: Double) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }

        let snapshot: TaxWidgetSnapshot
        if let state = USStateTax.byCode(stateCode) {
            snapshot = TaxWidgetSnapshot(
                stateCode: state.code,
                stateName: state.name,
                totalRatePercent: ratePercent,
                hasTax: ratePercent > 0
            )
        } else if ratePercent > 0 {
            snapshot = TaxWidgetSnapshot(
                stateCode: "Tax",
                stateName: "Custom rate",
                totalRatePercent: ratePercent,
                hasTax: true
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
