import Foundation

// MARK: - US state sales tax
//
// Approximate STATE-LEVEL base sales tax rates (percent). Real receipts often
// include additional city/county tax — use the optional "Local tax" add-on in
// Settings to match a specific register total. Rates are approximate and current
// as of early 2025; verify against your local rate when accuracy matters.

struct USStateTax: Identifiable, Hashable {
    var code: String      // e.g. "CA"
    var name: String      // e.g. "California"
    var rate: Double      // base state rate, percent

    var id: String { code }

    var hasNoStateSalesTax: Bool { rate == 0 }

    static func byCode(_ code: String) -> USStateTax? {
        all.first { $0.code == code }
    }

    /// All 50 states + DC, sorted alphabetically by name.
    static let all: [USStateTax] = [
        USStateTax(code: "AL", name: "Alabama", rate: 4.0),
        USStateTax(code: "AK", name: "Alaska", rate: 0.0),
        USStateTax(code: "AZ", name: "Arizona", rate: 5.6),
        USStateTax(code: "AR", name: "Arkansas", rate: 6.5),
        USStateTax(code: "CA", name: "California", rate: 7.25),
        USStateTax(code: "CO", name: "Colorado", rate: 2.9),
        USStateTax(code: "CT", name: "Connecticut", rate: 6.35),
        USStateTax(code: "DE", name: "Delaware", rate: 0.0),
        USStateTax(code: "DC", name: "District of Columbia", rate: 6.0),
        USStateTax(code: "FL", name: "Florida", rate: 6.0),
        USStateTax(code: "GA", name: "Georgia", rate: 4.0),
        USStateTax(code: "HI", name: "Hawaii", rate: 4.0),
        USStateTax(code: "ID", name: "Idaho", rate: 6.0),
        USStateTax(code: "IL", name: "Illinois", rate: 6.25),
        USStateTax(code: "IN", name: "Indiana", rate: 7.0),
        USStateTax(code: "IA", name: "Iowa", rate: 6.0),
        USStateTax(code: "KS", name: "Kansas", rate: 6.5),
        USStateTax(code: "KY", name: "Kentucky", rate: 6.0),
        USStateTax(code: "LA", name: "Louisiana", rate: 5.0),
        USStateTax(code: "ME", name: "Maine", rate: 5.5),
        USStateTax(code: "MD", name: "Maryland", rate: 6.0),
        USStateTax(code: "MA", name: "Massachusetts", rate: 6.25),
        USStateTax(code: "MI", name: "Michigan", rate: 6.0),
        USStateTax(code: "MN", name: "Minnesota", rate: 6.875),
        USStateTax(code: "MS", name: "Mississippi", rate: 7.0),
        USStateTax(code: "MO", name: "Missouri", rate: 4.225),
        USStateTax(code: "MT", name: "Montana", rate: 0.0),
        USStateTax(code: "NE", name: "Nebraska", rate: 5.5),
        USStateTax(code: "NV", name: "Nevada", rate: 6.85),
        USStateTax(code: "NH", name: "New Hampshire", rate: 0.0),
        USStateTax(code: "NJ", name: "New Jersey", rate: 6.625),
        USStateTax(code: "NM", name: "New Mexico", rate: 4.875),
        USStateTax(code: "NY", name: "New York", rate: 4.0),
        USStateTax(code: "NC", name: "North Carolina", rate: 4.75),
        USStateTax(code: "ND", name: "North Dakota", rate: 5.0),
        USStateTax(code: "OH", name: "Ohio", rate: 5.75),
        USStateTax(code: "OK", name: "Oklahoma", rate: 4.5),
        USStateTax(code: "OR", name: "Oregon", rate: 0.0),
        USStateTax(code: "PA", name: "Pennsylvania", rate: 6.0),
        USStateTax(code: "RI", name: "Rhode Island", rate: 7.0),
        USStateTax(code: "SC", name: "South Carolina", rate: 6.0),
        USStateTax(code: "SD", name: "South Dakota", rate: 4.2),
        USStateTax(code: "TN", name: "Tennessee", rate: 7.0),
        USStateTax(code: "TX", name: "Texas", rate: 6.25),
        USStateTax(code: "UT", name: "Utah", rate: 6.1),
        USStateTax(code: "VT", name: "Vermont", rate: 6.0),
        USStateTax(code: "VA", name: "Virginia", rate: 5.3),
        USStateTax(code: "WA", name: "Washington", rate: 6.5),
        USStateTax(code: "WV", name: "West Virginia", rate: 6.0),
        USStateTax(code: "WI", name: "Wisconsin", rate: 5.0),
        USStateTax(code: "WY", name: "Wyoming", rate: 4.0),
    ]
}
