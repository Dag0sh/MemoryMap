import Foundation
import SwiftUI
import CoreLocation

final class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Получаем текущий статус
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = self.manager.authorizationStatus
            print("📍 Initial authorization status: \(self.authorizationStatus.rawValue)")
            
            // Если уже авторизованы - начинаем обновления
            if self.authorizationStatus == .authorizedWhenInUse || 
               self.authorizationStatus == .authorizedAlways {
                self.manager.startUpdatingLocation()
                print("✅ Started location updates")
            } else if self.authorizationStatus == .notDetermined {
                // Запрашиваем разрешение только если еще не определено
                self.manager.requestWhenInUseAuthorization()
                print("🔐 Requesting location authorization")
            }
        }
    }

    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("✅ Location authorized: \(status)")
                manager.startUpdatingLocation()
                
            case .denied, .restricted:
                print("❌ Location denied or restricted")
                
            case .notDetermined:
                print("⏳ Location authorization not determined")
                
            @unknown default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let location = locations.last {
                self.currentLocation = location
                print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("❌ Location error: \(error.localizedDescription)")
        }
    }
}
