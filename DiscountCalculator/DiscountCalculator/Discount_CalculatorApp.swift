import SwiftUI

@main
struct Discount_CalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    guard !AppRuntime.isRunningForPreviews else { return }
                    ICloudSyncManager.shared.start()
                }
        }
    }
}
