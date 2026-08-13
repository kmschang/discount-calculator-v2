//
//  DeveloperToolsView.swift
//  Discount Calculator
//
//  Hidden diagnostics panel, reachable from Settings → Developer Tools once
//  unlocked by tapping the version row 8 times (or automatically in DEBUG).
//  Lets you confirm the backend features — iCloud settings sync and location
//  → state resolution — are actually working.
//

import SwiftUI
import CoreLocation

struct DeveloperToolsView: View {
    @ObservedObject private var sync = ICloudSyncManager.shared
    @ObservedObject private var location = LocationManager.shared

    @AppStorage("devModeEnabled") private var devModeEnabled: Bool = false
    @AppStorage("taxStateCode") private var taxStateCode: String = ""
    @AppStorage("savedTaxRate") private var savedTaxRate: Double = -1

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    var body: some View {
        List {
            // MARK: iCloud Sync
            Section {
                statusRow("iCloud Account", sync.iCloudAvailable ? "Signed In" : "Not Signed In",
                          ok: sync.iCloudAvailable)
                statusRow("Sync Enabled", sync.isEnabled ? "Yes" : "No", ok: sync.isEnabled)
                statusRow("Started", sync.isStarted ? "Yes" : "No", ok: sync.isStarted)
                statusRow("Currently Syncing", sync.isSyncing ? "Yes" : "No", ok: nil)
                detailRow("Last Push", sync.lastPushDate.map { timeFormatter.string(from: $0) } ?? "Never")
                detailRow("Last Pull", sync.lastPullDate.map { timeFormatter.string(from: $0) } ?? "Never")
                detailRow("Last Reason", sync.lastChangeReason ?? "—")
                detailRow("This Device", sync.deviceLabel)

                Button {
                    sync.syncNow()
                } label: {
                    Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                }
            } header: {
                Text("iCloud Sync")
            } footer: {
                Text("iCloud key-value sync only works on devices signed into the same Apple Account, and is unreliable in the Simulator. Test on a real device.")
            }

            // MARK: Synced keys
            Section("Synced Settings Keys") {
                ForEach(ICloudSyncManager.syncedSettingKeys, id: \.self) { key in
                    HStack {
                        Text(key)
                            .font(.callout.monospaced())
                        Spacer()
                        Text(currentValueString(for: key))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: Recent sync events
            if !sync.recentEvents.isEmpty {
                Section("Recent Sync Activity") {
                    ForEach(sync.recentEvents.prefix(12)) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(event.kind)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(color(for: event.kind))
                                Spacer()
                                Text(timeFormatter.string(from: event.date))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Text(event.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // MARK: Location
            Section {
                statusRow("Authorization", location.statusDescription,
                          ok: location.authorizationStatus == .authorizedWhenInUse || location.authorizationStatus == .authorizedAlways)
                statusRow("Resolving", location.isResolving ? "Yes" : "No", ok: nil)
                detailRow("Resolved State", location.lastResolvedStateName ?? location.lastResolvedStateCode ?? "—")
                detailRow("Tax State Code", taxStateCode.isEmpty ? "—" : taxStateCode)
                detailRow("Saved Tax Rate", savedTaxRate < 0 ? "unset" : "\(AppFormat.percent(savedTaxRate))%")
                if let fix = location.lastFix {
                    detailRow("Last Fix", String(format: "%.3f, %.3f", fix.coordinate.latitude, fix.coordinate.longitude))
                }
                if let error = location.lastError {
                    detailRow("Last Error", error, valueColor: .red)
                }
                Button {
                    location.requestStateFromLocation { _ in }
                } label: {
                    Label("Test Location Lookup", systemImage: "location.magnifyingglass")
                }
            } header: {
                Text("Location")
            } footer: {
                Text("Resolves your current US state from Core Location + reverse geocoding, then applies that state's sales-tax rate.")
            }

            // MARK: Environment
            Section("Environment") {
                detailRow("Build", isDebugBuild ? "Debug" : "Release")
                Toggle("Developer Mode", isOn: $devModeEnabled)
            }
        }
        .navigationTitle("Developer Tools")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Helpers

    private var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private func currentValueString(for key: String) -> String {
        guard let value = UserDefaults.standard.object(forKey: key) else { return "unset" }
        return String(describing: value)
    }

    private func color(for kind: String) -> Color {
        switch kind {
        case "Push": return .blue
        case "Pull": return .green
        default: return .secondary
        }
    }

    @ViewBuilder
    private func statusRow(_ title: String, _ value: String, ok: Bool?) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let ok {
                Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(ok ? .green : .orange)
            }
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func detailRow(_ title: String, _ value: String, valueColor: Color = .secondary) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview("Developer Tools") {
    NavigationStack {
        DeveloperToolsView()
    }
}
