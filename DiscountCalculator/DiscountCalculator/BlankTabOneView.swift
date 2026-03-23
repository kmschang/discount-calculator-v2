import SwiftUI

struct BlankTabOneView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeColor") private var themeColor: Int = 7

    @State private var rawDigits: String = ""
    @State private var selectedDiscountPercent: Double = 25
    @State private var selectedTaxPercent: Double = 5.6

    private let discountOptions: [Double] = [0, 5, 10, 15, 20, 25, 30, 40, 50]
    private let taxOptions: [Double] = [0, 4, 5, 5.6, 6.5, 7.25, 8.25, 9.5]

    private var accentColor: Color {
        switch themeColor {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        case 6: return .purple
        case 7: return colorScheme == .dark ? .white : .black
        default: return .accentColor
        }
    }

    private var itemAmount: Double {
        guard let cents = Double(rawDigits), !rawDigits.isEmpty else { return 0 }
        return cents / 100
    }

    private var discountAmount: Double {
        itemAmount * (selectedDiscountPercent / 100)
    }

    private var subtotalAfterDiscount: Double {
        itemAmount - discountAmount
    }

    private var taxAmount: Double {
        subtotalAfterDiscount * (selectedTaxPercent / 100)
    }

    private var finalAmount: Double {
        subtotalAfterDiscount + taxAmount
    }

    private var netChangeAmount: Double {
        finalAmount - itemAmount
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var currencyTextColor: Color {
        colorScheme == .dark ? .white : .primary
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark ? .white.opacity(0.72) : .secondary
    }

    private var keyRows: [[CalculatorKey]] {
        [
            [.digit("1"), .digit("2"), .digit("3")],
            [.digit("4"), .digit("5"), .digit("6")],
            [.digit("7"), .digit("8"), .digit("9")],
            [.clear, .digit("0"), .backspace]
        ]
    }

    var body: some View {
        let isDarkMode = colorScheme == .dark

        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [Color.black, Color(red: 0.04, green: 0.05, blue: 0.09)]
                    : [Color(red: 0.94, green: 0.96, blue: 1.0), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.40), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -130, y: -280)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.22), Color.clear],
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 170, y: 260)

            VStack(spacing: 16) {
                summaryCard

                selectionRow(
                    title: "Discount (-)",
                    selectedValue: selectedDiscountPercent,
                    options: discountOptions
                ) { value in
                    selectedDiscountPercent = value
                }

                selectionRow(
                    title: "Tax (+)",
                    selectedValue: selectedTaxPercent,
                    options: taxOptions
                ) { value in
                    selectedTaxPercent = value
                }

                keypad
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Item Amount")
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryTextColor)

            Text(itemAmount, format: .currency(code: currencyCode))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(currencyTextColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Divider()
                .overlay(accentColor.opacity(0.45))

            Text("Final")
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryTextColor)

            Text(finalAmount, format: .currency(code: currencyCode))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            HStack(spacing: 8) {
                Text("-\(discountAmount, format: .currency(code: currencyCode))")
                Text("•")
                Text("+\(taxAmount, format: .currency(code: currencyCode))")
                Text("•")
                Text("\(netChangeAmount >= 0 ? "+" : "-")\(abs(netChangeAmount), format: .currency(code: currencyCode))")
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(secondaryTextColor)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .calculatorPillGlass(accentColor: accentColor)
    }

    private func selectionRow(
        title: String,
        selectedValue: Double,
        options: [Double],
        action: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(secondaryTextColor)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { value in
                        Button {
                            action(value)
                        } label: {
                            Text("\(formatPercent(value))%")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(value == selectedValue ? accentColor : currencyTextColor)
                                .frame(minWidth: 56)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .calculatorPillGlass(accentColor: accentColor, isEmphasized: value == selectedValue)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var keypad: some View {
        VStack(spacing: 10) {
            ForEach(keyRows.indices, id: \.self) { rowIndex in
                HStack(spacing: 10) {
                    ForEach(keyRows[rowIndex], id: \.self) { key in
                        Button {
                            handle(key)
                        } label: {
                            key.labelView
                                .font(.title3.weight(.bold))
                                .foregroundStyle(currencyTextColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 62)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .calculatorPillGlass(accentColor: accentColor)
                    }
                }
            }
        }
    }

    private func handle(_ key: CalculatorKey) {
        switch key {
        case .digit(let value):
            guard rawDigits.count < 12 else { return }
            rawDigits.append(value)
        case .clear:
            rawDigits = ""
        case .backspace:
            guard !rawDigits.isEmpty else { return }
            rawDigits.removeLast()
        }
    }

    private func formatPercent(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2)))
    }
}

private enum CalculatorKey: Hashable {
    case digit(String)
    case clear
    case backspace

    @ViewBuilder
    var labelView: some View {
        switch self {
        case .digit(let value):
            Text(value)
        case .clear:
            Image(systemName: "xmark")
        case .backspace:
            Image(systemName: "delete.left")
        }
    }
}

private extension View {
    @ViewBuilder
    func calculatorPillGlass(accentColor: Color, isEmphasized: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self
                .glassEffect(
                    .regular
                        .tint(isEmphasized ? accentColor.opacity(0.25) : accentColor.opacity(0.14))
                        .interactive(),
                    in: .rect(cornerRadius: 14)
                )
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(accentColor.opacity(isEmphasized ? 0.45 : 0.22), lineWidth: 1)
                }
        }
    }
}

#Preview("Calculator - Dark") {
    NavigationStack {
        BlankTabOneView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Calculator - Light") {
    NavigationStack {
        BlankTabOneView()
    }
    .preferredColorScheme(.light)
}
