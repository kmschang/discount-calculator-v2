import SwiftUI

struct BlankTabOneView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("themeColor") private var themeColor: Int = 7

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

    var body: some View {
        let isDarkMode = colorScheme == .dark

        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [Color.black, Color(red: 0.05, green: 0.05, blue: 0.10)]
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
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -150, y: -260)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [(isDarkMode ? Color.white : Color.black).opacity(0.25), Color.clear],
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 160, y: 220)

            VStack {
                Text("Tab 1")
                    .font(.title2.weight(.semibold))
                Text("Blank placeholder view")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Tab 1") {
    NavigationStack {
        BlankTabOneView()
    }
}
