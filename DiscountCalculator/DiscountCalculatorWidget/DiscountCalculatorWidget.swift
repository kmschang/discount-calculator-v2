//
//  DiscountCalculatorWidget.swift
//  DiscountCalculatorWidget
//
//  A small at-a-glance widget showing the user's home state and its current
//  sales-tax rate, tapping through to the app. Reads a snapshot the main app
//  writes into the shared App Group container.
//

import WidgetKit
import SwiftUI

// MARK: - Shared snapshot (mirror of the app target's TaxWidgetSnapshot)

struct TaxSnapshot: Codable {
    var stateCode: String
    var stateName: String
    var totalRatePercent: Double
    var hasTax: Bool
}

enum WidgetSharedReader {
    static let appGroupID = "group.com.schang.Discount-Calculator"
    static let snapshotKey = "tax_widget_snapshot"

    static func read() -> TaxSnapshot? {
        guard let data = UserDefaults(suiteName: appGroupID)?.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(TaxSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}

// MARK: - Timeline

struct TaxEntry: TimelineEntry {
    let date: Date
    let snapshot: TaxSnapshot?
}

struct TaxProvider: TimelineProvider {
    func placeholder(in context: Context) -> TaxEntry {
        TaxEntry(date: Date(), snapshot: TaxSnapshot(stateCode: "CA", stateName: "California", totalRatePercent: 7.25, hasTax: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (TaxEntry) -> Void) {
        completion(TaxEntry(date: Date(), snapshot: WidgetSharedReader.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaxEntry>) -> Void) {
        let entry = TaxEntry(date: Date(), snapshot: WidgetSharedReader.read())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

// MARK: - Formatting

private func formatPercent(_ value: Double) -> String {
    let isWhole = value.truncatingRemainder(dividingBy: 1) == 0
    return String(format: isWhole ? "%.0f%%" : "%.2f%%", value)
}

// MARK: - Views

struct DiscountCalculatorWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: TaxProvider.Entry

    private var hasState: Bool { !(entry.snapshot?.stateCode.isEmpty ?? true) }

    var body: some View {
        switch family {
        case .accessoryInline:
            if let snap = entry.snapshot, hasState {
                Label("\(snap.stateCode) \(formatPercent(snap.totalRatePercent))", systemImage: "percent")
            } else {
                Label("Set your state", systemImage: "percent")
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Sales Tax")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let snap = entry.snapshot, hasState {
                    Text(snap.stateName).font(.headline)
                    Text(snap.hasTax ? formatPercent(snap.totalRatePercent) : "No sales tax")
                        .font(.caption)
                } else {
                    Text("Set your state").font(.headline)
                }
            }

        default:
            mainCard
        }
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "building.columns.fill")
                    .font(.caption)
                Text("Sales Tax")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            if let snap = entry.snapshot, hasState {
                Text(snap.hasTax ? formatPercent(snap.totalRatePercent) : "None")
                    .font(.system(size: family == .systemMedium ? 44 : 34, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.tint)
                Text(snap.stateName)
                    .font(.headline)
                    .lineLimit(1)
            } else {
                Text("—")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.tint)
                Text("Set your state in the app")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Text("Tap to calculate a discount")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Widget

struct DiscountCalculatorWidget: Widget {
    let kind: String = "DiscountCalculatorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaxProvider()) { entry in
            DiscountCalculatorWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sales Tax")
        .description("Your home state's current sales-tax rate, one tap from a fresh discount calculation.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

#Preview(as: .systemSmall) {
    DiscountCalculatorWidget()
} timeline: {
    TaxEntry(date: .now, snapshot: TaxSnapshot(stateCode: "CA", stateName: "California", totalRatePercent: 7.25, hasTax: true))
    TaxEntry(date: .now, snapshot: nil)
}
