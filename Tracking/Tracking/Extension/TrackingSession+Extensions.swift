//
//  TrackingSession+Extensions.swift
//  Tracking
//

import Foundation
import CoreLocation

extension TrackingSession {
    func optimizedUpdateMetrics() {
            guard let locations = self.locations?.sortedArray(using: [NSSortDescriptor(key: "timestamp", ascending: true)]) as? [SavedLocation],
                  locations.count > 1 else { return }
            
            // Batch-Berechnung mit CoreLocation
            let coordinates = locations.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
            var distance: CLLocationDistance = 0
            
            DispatchQueue.global(qos: .userInitiated).async {
                for i in 1..<coordinates.count {
                    distance += coordinates[i-1].distance(from: coordinates[i])
                }
                
                DispatchQueue.main.async {
                    self.totalDistance = distance
                    self.totalDuration = Double(locations.count - 1)
                    self.averageSpeed = distance / self.totalDuration
                }
            }
        }
    
    func updateMetrics() {
        guard let locations = self.locations?.sortedArray(using: [NSSortDescriptor(key: "timestamp", ascending: true)]) as? [SavedLocation],
              locations.count >= 2,
              let startTime = self.startTime else {
            self.totalDistance = 0
            self.totalDuration = 0
            self.averageSpeed = 0
            return
        }

        // Distanzberechnung
        var totalDistance: CLLocationDistance = 0
        for i in 1..<locations.count {
            let prev = locations[i-1]
            let current = locations[i]
            totalDistance += CLLocation(latitude: prev.latitude, longitude: prev.longitude)
                .distance(from: CLLocation(latitude: current.latitude, longitude: current.longitude))
        }
        
        // Höhenmeter-Berechnung
        let coordinates = locations.map {
            CLLocation(coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                       altitude: $0.altitude,
                       horizontalAccuracy: 1,
                       verticalAccuracy: 1,
                       timestamp: $0.timestamp ?? Date())
        }
        var totalAscent: CLLocationDistance = 0
        var totalDescent: CLLocationDistance = 0
        var minAltitude: CLLocationDistance = coordinates.first?.altitude ?? 0
        var maxAltitude: CLLocationDistance = minAltitude

        for i in 1..<coordinates.count {
            let prevAlt = coordinates[i-1].altitude
            let currAlt = coordinates[i].altitude
            let diff = currAlt - prevAlt

            if diff > 0 {
                totalAscent += diff
            } else {
                totalDescent += abs(diff)
            }

            minAltitude = min(minAltitude, currAlt)
            maxAltitude = max(maxAltitude, currAlt)
        }

        // Dauerberechnung
        let endTime = self.endTime ?? locations.last?.timestamp ?? startTime
        let duration = endTime.timeIntervalSince(startTime)
        let speed = duration > 0 ? totalDistance / duration : 0

        // Werte direkt in CoreData speichern
        self.totalDistance = totalDistance
        self.totalDuration = duration
        self.averageSpeed = speed
        self.totalAscent = totalAscent
        self.totalDescent = totalDescent
        self.minAltitude = minAltitude
        self.maxAltitude = maxAltitude
        
        /*
         
        // DEBUG-Ausgabe
        print("""
        Aktualisierte Metriken für Session \(self.name ?? "Unbenannt"):
        - Distanz: \(totalDistance) m
        - Dauer: \(duration) s
        - Geschwindigkeit: \(speed) m/s
        - Aufstieg: \(totalAscent) m
        - Abstieg: \(totalDescent) m
        - Min. Höhe: \(minAltitude) m
        - Max. Höhe: \(maxAltitude) m
        """)
         
         */
    }
}
