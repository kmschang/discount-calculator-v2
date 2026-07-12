import SwiftUI

struct ContentView: View {
    @State private var store = CalculatorStore()
    @State private var selectedTab: Tab = .calculate
    @State private var isInfoSheetPresented = false
    @State private var isSettingsSheetPresented = false
    @State private var isShowingLoading = true

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("autoDetectStateFromLocation") private var autoDetectStateFromLocation: Bool = false
    @AppStorage("homeStateCode") private var homeStateCode: String = ""
    @AppStorage("localTaxRate") private var localTaxRate: Double = 0
    @Environment(\.colorScheme) private var systemColorScheme

    enum Tab: String, Hashable {
        case calculate = "Calculate"
        case taxByState = "Tax by State"
    }

    init(showLoadingInitially: Bool = true) {
        let args = ProcessInfo.processInfo.arguments
        let skipLoading = args.contains("-DemoData")
        _isShowingLoading = State(initialValue: showLoadingInitially && !skipLoading)
        if args.contains("-StartTaxTab") {
            _selectedTab = State(initialValue: .taxByState)
        }
    }

    private var currentTabTitle: String { selectedTab.rawValue }

    private var appColorScheme: ColorScheme? {
        AppTheme.appColorScheme(appearanceMode: appearanceMode)
    }

    private var tabAccentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: systemColorScheme)
    }

    private var mainAppView: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                CalculatorView()
                    .tabItem { Label("Calculate", systemImage: "percent") }
                    .tag(Tab.calculate)

                TaxByStateView()
                    .tabItem { Label("Tax by State", systemImage: "building.columns") }
                    .tag(Tab.taxByState)
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
        .environment(store)
        .task {
            maybeAutoDetectState()
            TaxWidgetSharedStore.update(homeStateCode: homeStateCode, localTaxRate: localTaxRate)
        }
        .onChange(of: homeStateCode) { _, _ in
            TaxWidgetSharedStore.update(homeStateCode: homeStateCode, localTaxRate: localTaxRate)
        }
        .onChange(of: localTaxRate) { _, _ in
            TaxWidgetSharedStore.update(homeStateCode: homeStateCode, localTaxRate: localTaxRate)
        }
    }

    private func maybeAutoDetectState() {
        guard autoDetectStateFromLocation else { return }
        LocationManager.shared.requestStateFromLocation { code in
            if let code, USStateTax.byCode(code) != nil {
                homeStateCode = code
                store.selectState(code)
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

#Preview("Content - Light") {
    ContentView(showLoadingInitially: false)
        .preferredColorScheme(.light)
}

#Preview("Content - Dark") {
    ContentView(showLoadingInitially: false)
        .preferredColorScheme(.dark)
}
