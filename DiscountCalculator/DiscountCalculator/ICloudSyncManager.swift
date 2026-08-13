//
//  ICloudSyncManager.swift
//  Discount Calculator
//
//  Syncs a small set of calculator settings across the user's devices via
//  NSUbiquitousKeyValueStore (iCloud key-value storage). Mirrors the Day
//  Calculator approach: debounced last-writer-wins push, external-change pull,
//  and published diagnostics for the Developer Tools panel.
//
//  Appearance / accent color / app icon are intentionally NOT synced — they
//  stay device-local, matching Day Calculator.
//

import Foundation
import SwiftUI

@MainActor
final class ICloudSyncManager: ObservableObject {
    static let shared = ICloudSyncManager()

    // MARK: Keys

    /// UserDefaults (@AppStorage) keys mirrored into iCloud. Device-local
    /// preferences (appearanceMode, themeColor, selectedAppIconName) are omitted.
    static let syncedSettingKeys: [String] = [
        "taxStateCode",
        "savedTaxRate",
        "roundToCents",
        "taxOnOriginal",
        "autoDetectStateFromLocation"
    ]

    /// User-facing on/off switch (defaults to on when never set).
    static let enabledDefaultsKey = "iCloudSyncEnabled"

    private static let kvsSettingsKey = "icloud_settings"
    private static let updatedAtField = "__updatedAt"
    private static let deviceField = "__device"

    // MARK: Published diagnostics (read by Developer Tools)

    struct SyncEvent: Identifiable, Hashable {
        let id = UUID()
        let date: Date
        let kind: String      // "Push" | "Pull" | "Info"
        let detail: String
    }

    @Published private(set) var isStarted = false
    @Published private(set) var isSyncing = false
    @Published private(set) var lastPushDate: Date?
    @Published private(set) var lastPullDate: Date?
    @Published private(set) var lastChangeReason: String?
    @Published private(set) var recentEvents: [SyncEvent] = []

    // MARK: Internals

    private let store = NSUbiquitousKeyValueStore.default
    private let defaults = UserDefaults.standard
    private var tokens: [NSObjectProtocol] = []
    private var pushWorkItem: DispatchWorkItem?
    private let pushDebounce: TimeInterval = 0.8
    private var isApplyingRemoteChange = false
    private var lastAppliedUpdatedAt: Date?

    private init() {}

    // MARK: Public state

    /// Whether the user has enabled sync (true unless explicitly turned off).
    var isEnabled: Bool {
        get { defaults.object(forKey: Self.enabledDefaultsKey) as? Bool ?? true }
        set {
            defaults.set(newValue, forKey: Self.enabledDefaultsKey)
            if newValue {
                pullFromICloud(reason: "Sync enabled")
                schedulePush(reason: "Sync enabled")
            }
        }
    }

    /// Whether an iCloud account is available on this device.
    var iCloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    /// Short, stable-per-install device label used for diagnostics.
    var deviceLabel: String {
        UIDevice.current.name
    }

    // MARK: Lifecycle

    func start() {
        guard !isStarted else { return }
        isStarted = true
        registerObservers()
        store.synchronize()
        pullFromICloud(reason: "Initial pull")
        log(kind: "Info", detail: iCloudAvailable ? "Started (iCloud available)" : "Started (no iCloud account)")
    }

    private func registerObservers() {
        guard tokens.isEmpty else { return }

        tokens.append(NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.pullFromICloud(reason: "iCloud changed externally") }
        })

        tokens.append(NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handleLocalDefaultsChange() }
        })
    }

    // MARK: Push (local -> iCloud)

    private func handleLocalDefaultsChange() {
        guard isEnabled, !isApplyingRemoteChange else { return }
        schedulePush(reason: "Local settings changed")
    }

    private func schedulePush(reason: String) {
        guard isEnabled else { return }
        pushWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in self?.pushToICloud(reason: reason) }
        }
        pushWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + pushDebounce, execute: work)
    }

    private func pushToICloud(reason: String) {
        guard isEnabled else { return }
        isSyncing = true
        defer { isSyncing = false }

        var payload: [String: Any] = [:]
        for key in Self.syncedSettingKeys {
            if let value = defaults.object(forKey: key) {
                payload[key] = value
            }
        }
        let now = Date()
        payload[Self.updatedAtField] = now.timeIntervalSince1970
        payload[Self.deviceField] = deviceLabel

        store.set(payload, forKey: Self.kvsSettingsKey)
        store.synchronize()

        lastAppliedUpdatedAt = now
        lastPushDate = now
        lastChangeReason = reason
        log(kind: "Push", detail: "\(payload.count - 2) settings → iCloud (\(reason))")
    }

    // MARK: Pull (iCloud -> local)

    private func pullFromICloud(reason: String) {
        guard isEnabled else { return }
        guard let payload = store.dictionary(forKey: Self.kvsSettingsKey) else {
            lastChangeReason = reason
            return
        }

        // Last-writer-wins: only apply if the remote copy is newer than what we
        // last applied (avoids clobbering fresher local edits and echo loops).
        let remoteUpdatedAt = (payload[Self.updatedAtField] as? Double).map { Date(timeIntervalSince1970: $0) }
        if let remote = remoteUpdatedAt, let applied = lastAppliedUpdatedAt, remote <= applied {
            return
        }

        isSyncing = true
        isApplyingRemoteChange = true
        var changedCount = 0
        for key in Self.syncedSettingKeys {
            guard let remoteValue = payload[key] else { continue }
            let localValue = defaults.object(forKey: key)
            if !valuesEqual(localValue, remoteValue) {
                defaults.set(remoteValue, forKey: key)
                changedCount += 1
            }
        }
        // Reset the guard on the next runloop tick so the didChangeNotification
        // triggered by our own writes doesn't schedule an echo push.
        DispatchQueue.main.async { [weak self] in self?.isApplyingRemoteChange = false }

        lastAppliedUpdatedAt = remoteUpdatedAt ?? Date()
        lastPullDate = Date()
        lastChangeReason = reason
        isSyncing = false

        if changedCount > 0 {
            log(kind: "Pull", detail: "\(changedCount) setting(s) ← iCloud (\(reason))")
        }
    }

    // MARK: Manual trigger (Developer Tools "Sync Now")

    func syncNow() {
        store.synchronize()
        pullFromICloud(reason: "Manual sync")
        pushToICloud(reason: "Manual sync")
    }

    // MARK: Helpers

    private func valuesEqual(_ a: Any?, _ b: Any?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (x as NSNumber, y as NSNumber): return x == y
        case let (x as String, y as String): return x == y
        default:
            if let x = a as? NSObject, let y = b as? NSObject { return x.isEqual(y) }
            return false
        }
    }

    private func log(kind: String, detail: String) {
        let event = SyncEvent(date: Date(), kind: kind, detail: detail)
        recentEvents.insert(event, at: 0)
        if recentEvents.count > 50 {
            recentEvents.removeLast(recentEvents.count - 50)
        }
    }
}
