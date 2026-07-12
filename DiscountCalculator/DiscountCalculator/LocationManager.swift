//
//  LocationManager.swift
//  Discount Calculator
//
//  Resolves the user's US state from their current location so the correct
//  sales-tax rate can be applied without the user knowing their rate. Uses
//  when-in-use authorization and a one-shot location request + reverse geocode.
//  Nothing is stored or transmitted off-device beyond Apple's geocoding request.
//

import CoreLocation
import MapKit
import SwiftUI

@MainActor
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let manager = CLLocationManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var isResolving = false
    @Published private(set) var lastResolvedStateCode: String?
    @Published private(set) var lastResolvedStateName: String?
    @Published private(set) var lastError: String?
    @Published private(set) var lastFix: CLLocation?

    /// Called once when a resolution attempt finishes (state code, or nil on failure).
    private var onResolve: ((String?) -> Void)?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: Public API

    /// Requests permission if needed, gets one location fix, reverse-geocodes it,
    /// and returns the 2-letter US state code (e.g. "CA") or nil.
    func requestStateFromLocation(completion: @escaping (String?) -> Void) {
        onResolve = completion
        lastError = nil

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Resolution continues from the authorization callback.
        case .authorizedWhenInUse, .authorizedAlways:
            startResolving()
        default:
            lastError = "Location access is off. You can turn it on in Settings."
            finish(nil)
        }
    }

    var canUseLocation: Bool {
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways, .notDetermined: return true
        default: return false
        }
    }

    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined: return "Not asked yet"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Allowed (Always)"
        case .authorizedWhenInUse: return "Allowed (When in use)"
        @unknown default: return "Unknown"
        }
    }

    // MARK: Internals

    private func startResolving() {
        isResolving = true
        manager.requestLocation()
    }

    private func finish(_ code: String?) {
        isResolving = false
        let callback = onResolve
        onResolve = nil
        callback?(code)
    }

    private func reverseGeocode(_ location: CLLocation) {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            lastError = "Couldn't determine your location."
            finish(nil)
            return
        }
        // Force US-English formatting so the returned address is predictably
        // "…, Cupertino, CA 95014, United States" — the shape we parse below.
        request.preferredLocale = Locale(identifier: "en_US")
        Task { @MainActor in
            do {
                let mapItems = try await request.mapItems
                guard let item = mapItems.first else {
                    self.lastError = "Couldn't determine your location."
                    self.finish(nil)
                    return
                }
                // iOS 26's MapKit reverse-geocoding only vends display strings — it
                // dropped the structured 2-letter state / ISO country code that the
                // deprecated CLPlacemark gave us — so recover the state code from the
                // formatted address text.
                guard let code = Self.usStateCode(from: item) else {
                    self.lastError = "This app's tax rates only cover the US."
                    self.finish(nil)
                    return
                }
                self.lastResolvedStateCode = code
                self.lastResolvedStateName = USStateTax.byCode(code)?.name
                self.finish(code)
            } catch {
                self.lastError = error.localizedDescription
                self.finish(nil)
            }
        }
    }

    // MARK: State-code extraction (iOS 26 MapKit gives us only text)

    /// Pulls a 2-letter US state code out of a reverse-geocoded map item, trying
    /// the full postal address first and the short "City, ST" context second.
    /// Returns nil for non-US locations (or anything we can't confidently parse).
    private static func usStateCode(from item: MKMapItem) -> String? {
        if let full = item.address?.fullAddress,
           let code = stateCode(inPostalAddress: full) {
            return code
        }
        if let city = item.addressRepresentations?.cityWithContext,
           let code = trailingStateCode(in: city) {
            return code
        }
        return nil
    }

    /// Matches the "ST 12345" fragment of a US postal address (2 uppercase letters
    /// followed by a 5-digit ZIP) and validates it against the known state list.
    private static func stateCode(inPostalAddress text: String) -> String? {
        guard let range = text.range(of: #"\b[A-Z]{2}\s+\d{5}(-\d{4})?\b"#,
                                     options: .regularExpression) else { return nil }
        let code = String(text[range].prefix(2))
        return USStateTax.byCode(code) != nil ? code : nil
    }

    /// Extracts the trailing state code from a "City, ST" style string.
    private static func trailingStateCode(in text: String) -> String? {
        guard let last = text.split(separator: ",").last else { return nil }
        let code = last.trimmingCharacters(in: .whitespaces).uppercased()
        return (code.count == 2 && USStateTax.byCode(code) != nil) ? code : nil
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.onResolve != nil { self.startResolving() }
            case .denied, .restricted:
                if self.onResolve != nil {
                    self.lastError = "Location access denied."
                    self.finish(nil)
                }
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastFix = location
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
            self.finish(nil)
        }
    }
}
