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
    
    @Published var totalAscent: Double?
    @Published var totalDescent: Double?
    @Published var minAltitude: Double?
    @Published var maxAltitude: Double?
    
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
                type: type,
                imageData: location.imageData
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
        
        // Höhenmetriken berechnen
        var ascent: CLLocationDistance = 0
        var descent: CLLocationDistance = 0
        var minAlt = locations.first?.altitude ?? 0
        var maxAlt = minAlt

        for i in 1..<locations.count {
            let prevAlt = locations[i - 1].altitude
            let currAlt = locations[i].altitude
            let delta = currAlt - prevAlt

            if delta > 0 {
                ascent += delta
            } else {
                descent += abs(delta)
            }

            minAlt = min(minAlt, currAlt)
            maxAlt = max(maxAlt, currAlt)
        }

        totalAscent = ascent
        totalDescent = descent
        minAltitude = minAlt
        maxAltitude = maxAlt
    }
}

// MARK: - Modelle
struct MapMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType
    let imageData: Data?
    
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
    
    var isIntermediate: Bool {
        type == .normal
    }
    
    enum MarkerType {
        case start, end, normal
    }
}
