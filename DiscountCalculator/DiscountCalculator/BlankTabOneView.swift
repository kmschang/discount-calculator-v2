import SwiftUI

struct BlankTabOneView: View {
    var body: some View {
        VStack {
            Text("Tab 1")
                .font(.title2.weight(.semibold))
            Text("Blank placeholder view")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview("Tab 1") {
    NavigationStack {
        BlankTabOneView()
    }
}
