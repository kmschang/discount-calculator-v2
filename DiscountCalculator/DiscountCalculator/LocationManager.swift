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
import SwiftUI

@MainActor
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

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
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.lastError = error.localizedDescription
                    self.finish(nil)
                    return
                }
                guard let placemark = placemarks?.first else {
                    self.lastError = "Couldn't determine your location."
                    self.finish(nil)
                    return
                }
                guard placemark.isoCountryCode == "US" else {
                    self.lastError = "This app's tax rates only cover the US."
                    self.finish(nil)
                    return
                }
                // In US placemarks, administrativeArea is the 2-letter state code.
                let code = placemark.administrativeArea
                self.lastResolvedStateCode = code
                self.lastResolvedStateName = code.flatMap { USStateTax.byCode($0)?.name }
                self.finish(code)
            }
        }
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
