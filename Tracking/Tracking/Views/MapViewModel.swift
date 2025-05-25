//
//  MapViewModel.swift
//  Tracking
//

import SwiftUI
import CoreLocation

class MapViewModel: ObservableObject {
    @Published var markers: [MapMarker] = []
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var distance: Double?
    @Published var duration: TimeInterval?
    @Published var averageSpeed: Double?
    
    var shouldShowRoute: Bool {
        routeCoordinates.count > 1
    }
    
    @MainActor
    func update(with locations: [SavedLocation]) async {
        // Marker erstellen
        markers = locations.enumerated().map { index, location in
            let type: MapMarker.MarkerType = {
                if locations.count > 1 {
                    if index == 0 { return .start }
                    if index == locations.count - 1 { return .end }
                }
                return .normal
            }()
            
            return MapMarker(
                coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ),
                type: type
            )
        }
        
        // Route-Koordinaten
        routeCoordinates = locations.map {
            CLLocationCoordinate2D(
                latitude: $0.latitude,
                longitude: $0.longitude
            )
        }
        
        // Metriken berechnen
        calculateMetrics(locations: locations)
        
        
    }
    
    private func calculateMetrics(locations: [SavedLocation]) {
        guard locations.count >= 2,
              let startTime = locations.first?.timestamp else {
            distance = nil
            duration = nil
            averageSpeed = nil
            return
        }
        
        // Distanz berechnen
        var totalDistance: CLLocationDistance = 0
        for i in 1..<locations.count {
            let prev = locations[i-1]
            let current = locations[i]
            totalDistance += CLLocation(
                latitude: prev.latitude,
                longitude: prev.longitude
            ).distance(from: CLLocation(
                latitude: current.latitude,
                longitude: current.longitude
            ))
        }
        distance = totalDistance
        
        // Dauer berechnen
        let endTime = locations.last?.timestamp ?? Date()
        duration = endTime.timeIntervalSince(startTime)
        
        // Geschwindigkeit
        averageSpeed = (duration ?? 0) > 0 ? (distance ?? 0) / (duration ?? 1) : 0
    }
}

// MARK: - Modelle
struct MapMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType
    
    var title: String {
        switch type {
        case .start: return "Start"
        case .end: return "Ziel"
        case .normal: return "Punkt"
        }
    }
    
    var icon: String {
        switch type {
        case .start: return "flag.fill"
        case .end: return "flag.checkered"
        case .normal: return "mappin"
        }
    }
    
    var color: Color {
        switch type {
        case .start: return .green
        case .end: return .blue
        case .normal: return .red
        }
    }
    
    enum MarkerType {
        case start, end, normal
    }
}
