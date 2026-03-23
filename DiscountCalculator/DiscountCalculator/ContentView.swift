import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .tab1
    @State private var isInfoSheetPresented = false
    @State private var isSettingsSheetPresented = false
    @State private var isShowingLoading = true

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @Environment(\.colorScheme) private var systemColorScheme

    enum Tab: String, Hashable {
        case tab1 = "Calculator"
        case tab2 = "Tab 2"
        case tab3 = "Tab 3"
    }

    init(showLoadingInitially: Bool = true) {
        _isShowingLoading = State(initialValue: showLoadingInitially)
    }

    private var currentTabTitle: String { selectedTab.rawValue }

    private var appColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    private var tabAccentColor: Color {
        switch themeColor {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        case 6: return .purple
        case 7:
            let effectiveScheme = appColorScheme ?? systemColorScheme
            return effectiveScheme == .dark ? .white : .black
        default:
            return .accentColor
        }
    }

    private var mainAppView: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                BlankTabOneView()
                    .tabItem { Label("Calculator", systemImage: "plus.forwardslash.minus") }
                    .tag(Tab.tab1)

                BlankTabTwoView()
                    .tabItem { Label("Tab 2", systemImage: "2.circle") }
                    .tag(Tab.tab2)

                BlankTabThreeView()
                    .tabItem { Label("Tab 3", systemImage: "3.circle") }
                    .tag(Tab.tab3)
            }
            .tint(tabAccentColor)
            .navigationTitle(currentTabTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isInfoSheetPresented = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .tint(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isSettingsSheetPresented = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(.primary)
                }
            }
            .sheet(isPresented: $isInfoSheetPresented) {
                InfoView()
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isSettingsSheetPresented) {
                SettingsView()
                    .presentationDragIndicator(.visible)
            }
        }
    }

    var body: some View {
        Group {
            if isShowingLoading {
                LoadingView()
            } else {
                mainAppView
            }
        }
        .preferredColorScheme(appColorScheme)
        .task {
            if isShowingLoading {
                let delaySeconds = Double.random(in: 1...2)
                let delayNanoseconds = UInt64(delaySeconds * 1_000_000_000)
                try? await Task.sleep(nanoseconds: delayNanoseconds)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isShowingLoading = false
                    }
                }
            }
        }
    }
}

#Preview("Context View - Light") {
    ContentView(showLoadingInitially: false)
        .preferredColorScheme(.light)
}

#Preview("Context View - Dark") {
    ContentView(showLoadingInitially: false)
        .preferredColorScheme(.dark)
}

#Preview("Context View - Loading") {
    ContentView(showLoadingInitially: true)
        .preferredColorScheme(.dark)
}
