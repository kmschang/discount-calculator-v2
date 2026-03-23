import SwiftUI

struct BlankTabThreeView: View {
    var body: some View {
        VStack {
            Text("Tab 3")
                .font(.title2.weight(.semibold))
            Text("Blank placeholder view")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview("Tab 3") {
    NavigationStack {
        BlankTabThreeView()
    }
}
