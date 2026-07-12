import SwiftUI

/// Sheet for adding a discount — either a percentage or a flat dollar amount.
/// Big quick-pick chips add in one tap; a custom field covers everything else.
struct AddDiscountView: View {
    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.dismiss) private var dismiss

    let onAdd: (Discount) -> Void

    @State private var kind: DiscountKind = .percent
    @State private var customText: String = ""

    private let percentPresets: [Double] = [5, 10, 15, 20, 25, 30, 40, 50, 70]
    private let dollarPresets: [Double] = [1, 2, 5, 10, 20, 50]

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: systemScheme)
    }

    private var presets: [Double] { kind == .percent ? percentPresets : dollarPresets }

    private var customValue: Double? {
        let cleaned = customText.replacingOccurrences(of: ",", with: ".")
        guard let v = Double(cleaned), v > 0 else { return nil }
        return v
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CalculatorBackground(accentColor: accentColor, colorScheme: systemScheme)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Picker("Type", selection: $kind) {
                            Text("Percent off").tag(DiscountKind.percent)
                            Text("Dollars off").tag(DiscountKind.amount)
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Quick pick")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                ForEach(presets, id: \.self) { value in
                                    Button {
                                        add(value)
                                    } label: {
                                        Text(label(for: value))
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(accentColor)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 64)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .glassCard(accentColor: accentColor, cornerRadius: 16)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Custom")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                if kind == .amount {
                                    Text("$").font(.title2.weight(.bold)).foregroundStyle(.secondary)
                                }
                                TextField(kind == .percent ? "e.g. 35" : "e.g. 7.50", text: $customText)
                                    .font(.title2.weight(.semibold))
                                    .keyboardType(.decimalPad)
                                if kind == .percent {
                                    Text("%").font(.title2.weight(.bold)).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 60)
                            .glassCard(accentColor: accentColor, cornerRadius: 16)

                            Button {
                                if let v = customValue { add(v) }
                            } label: {
                                Text("Add discount")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(customValue == nil ? Color.secondary : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 58)
                                    .background(customValue == nil ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(accentColor),
                                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(customValue == nil)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add a Discount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(.primary)
                }
            }
        }
        .preferredColorScheme(AppTheme.appColorScheme(appearanceMode: appearanceMode))
    }

    private func label(for value: Double) -> String {
        kind == .percent ? "\(AppFormat.percent(value))%" : "$\(AppFormat.percent(value))"
    }

    private func add(_ value: Double) {
        onAdd(Discount(kind: kind, value: value))
        dismiss()
    }
}

#Preview("Add Discount") {
    AddDiscountView { _ in }
}
