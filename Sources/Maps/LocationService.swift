//
//  LocationService.swift
//  YMapTest
//
//  Created by Eduard Kanevskii on 23.05.2024.
//

import UIKit
import CoreLocation

final class LocationService: NSObject {
    private let locationManager = CLLocationManager()
    /// Координаты на случай, если пользователь не дал разрешения на использование геолокации (стадион Екатеринург Арена)
    let defaultUserLocation = CLLocation(latitude: 56.832508, longitude: 60.573519)
    /// Координаты офиса в Екатеринбурге
    let endLocation = CLLocation(latitude: 56.834195, longitude: 60.635280)
    var userLocation: CLLocation? {
        didSet {
            let location = userLocation ?? defaultUserLocation
            self.locationUpdatedCompletion?(location)
        }
    }
    
    static let shared = LocationService()
    var locationErrorCompletion: (()->())?
    var locationUpdatedCompletion: ((CLLocation)->())?
    
    private override init() {
        super.init()
        getUserLocation()
    }
    
    private func getUserLocation() {
        DispatchQueue.global(qos: .userInteractive).async {
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status != .notDetermined else { return }
        
        let isAuthorized = [.authorizedAlways, .authorizedWhenInUse].contains(status)
        if !isAuthorized {
            locationErrorCompletion?()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        
        guard let loc = locations.last else {
            // TODO: Особая ошибка
            return
        }
        // TODO: отправить запрос на сервер с локацией пользователя
        print(loc.coordinate.latitude, loc.coordinate.longitude, "loc")
       self.userLocation = loc
    }
}
