import CoreLocation
import os
import SwiftUI

/// CurrentLocation provides the current GPS location via CLLocationManager as ObservableObject.
/// Meant to be used for 'when the app is in use', NSLocationWhenInUseUsageDescription needs to be
/// set in Info.plist.
public class CurrentLocation: NSObject, ObservableObject {

    private let locationManager = CLLocationManager()

    @Published public var authorizationStatus = CLAuthorizationStatus.notDetermined
    @Published public var location: CLLocation?

    public init(isActive: Bool = false, desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters) {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = desiredAccuracy
        self.isActive = isActive
        self.updateIsActive()
    }

    public var isActive: Bool = false {
        didSet {
            self.updateIsActive()
        }
    }

    private func updateIsActive() {
        os_log("CurrentLocation.isActive: %i", type: .info, self.isActive)
        if self.isActive {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        } else {
            self.locationManager.stopUpdatingLocation()
            self.location = nil
        }
    }

    public var isAuthorized: Bool? {
        switch self.authorizationStatus {
        case .notDetermined:
            return .none
        case .restricted, .denied:
            return false
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        @unknown default:
            os_log("Unknown authorization status: %s", type: .error, String(describing: self.authorizationStatus))
            return .none
        }
    }

}

extension CurrentLocation: CLLocationManagerDelegate {
    public func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
    }

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            os_log("No location in CLLocation", type: .error)
            return
        }
        self.location = location
    }
}
