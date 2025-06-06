//
//  LiveLocationManager.swift
//  Tracking
//

import Foundation
import CoreLocation
import MapKit

class LiveLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var region: MKCoordinateRegion?

    private var isUpdating = false
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func requestLocationUpdatesIfAuthorized() {
        let status = locationManager.authorizationStatus
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = latestLocation
            //print("Aktuelle Höhe: \(latestLocation.altitude) m")
            self.region = MKCoordinateRegion(
                center: latestLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Fehler bei der Standortbestimmung: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Standortzugriff verweigert oder eingeschränkt.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func start() {
        guard !isUpdating else { return }
        locationManager.startUpdatingLocation()
        isUpdating = true
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        isUpdating = false
    }
    
    func startUpdatingLocation() {
        self.locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        self.locationManager.stopUpdatingLocation()
    }

}
