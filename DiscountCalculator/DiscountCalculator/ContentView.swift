import SwiftUI

/// Root of the app: a single calculator screen (no tab bar), with the info and
/// settings sheets hanging off the top toolbar and the launch loading screen.
struct ContentView: View {
    @State private var store = CalculatorStore()
    @State private var isInfoSheetPresented = false
    @State private var isSettingsSheetPresented = false
    @State private var isShowingLoading = true

    @AppStorage("themeColor") private var themeColor: Int = 7
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("autoDetectStateFromLocation") private var autoDetectStateFromLocation: Bool = false
    @Environment(\.colorScheme) private var systemColorScheme

    init(showLoadingInitially: Bool = true) {
        let skipLoading = ProcessInfo.processInfo.arguments.contains("-DemoData")
        _isShowingLoading = State(initialValue: showLoadingInitially && !skipLoading)
    }

    private var appColorScheme: ColorScheme? {
        AppTheme.appColorScheme(appearanceMode: appearanceMode)
    }

    private var accentColor: Color {
        AppTheme.accentColor(themeColor: themeColor, appearanceMode: appearanceMode, systemScheme: systemColorScheme)
    }

    private var mainAppView: some View {
        NavigationStack {
            CalculatorView()
                .tint(accentColor)
                .navigationTitle("Discount Calculator")
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
        }
    }

    private func maybeAutoDetectState() {
        guard autoDetectStateFromLocation else { return }
        LocationManager.shared.requestStateFromLocation { code in
            if let code, USStateTax.byCode(code) != nil {
                store.applyState(code)
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
