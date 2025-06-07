//
//  MapViewModel.swift
//  Tracking
//

import SwiftUI
import CoreLocation

// Diese Klasse verwaltet alle Daten, die für die Anzeige der Karte gebraucht werden.
// Sie enthält Informationen über Markierungen, Routen, Entfernungen usw.
class MapViewModel: ObservableObject {
    // Veröffentlicht Markierungen, die auf der Karte angezeigt werden (z. B. Start, Ziel, Punkte).
    @Published var markers: [MapMarker] = []
    // Veröffentlicht die Koordinaten für die Route, die gezeichnet wird.
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    // Veröffentlicht Metriken wie Distanz, Dauer, Geschwindigkeit.
    @Published var distance: Double?
    @Published var duration: TimeInterval?
    @Published var averageSpeed: Double?
    
    // Veröffentlicht Höheninformationen (Anstieg, Abstieg, Minimum und Maximum).
    @Published var totalAscent: Double?
    @Published var totalDescent: Double?
    @Published var minAltitude: Double?
    @Published var maxAltitude: Double?
    
    // Gibt an, ob eine Route angezeigt werden soll (nur wenn es mehr als 1 Punkt gibt).
    var shouldShowRoute: Bool {
        routeCoordinates.count > 1
    }
    
    @MainActor
    func update(with locations: [SavedLocation]) async {
        // Erstellt Markierungen (Marker) für die Karte, abhängig davon, ob es sich um Start-, End-, Einzel- oder Zwischenpunkte handelt.
        // Dies hilft dabei, verschiedene Positionen visuell auf der Karte zu unterscheiden.
        markers = locations.enumerated().map { index, location in
            let type: MapMarker.MarkerType = {
                if locations.count == 1 {
                    return .single
                } else {
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
        
        // Extrahiert nur die Koordinaten (Latitude und Longitude) aus den gespeicherten Positionen,
        // um eine Route (Linie) auf der Karte anzuzeigen.
        routeCoordinates = locations.map {
            CLLocationCoordinate2D(
                latitude: $0.latitude,
                longitude: $0.longitude
            )
        }
        
        // Berechnet zusätzliche Informationen wie Distanz, Dauer, Geschwindigkeit und Höhenveränderungen auf Basis der Positionen.
        calculateMetrics(locations: locations)
        
    }
    
    // Berechnet verschiedene Metriken basierend auf den gespeicherten Positionen:
    // Distanz, Dauer, Geschwindigkeit sowie Höheninformationen.
    private func calculateMetrics(locations: [SavedLocation]) {
        // Sicherstellen, dass es mindestens zwei Positionen gibt, um sinnvolle Berechnungen zu machen.
        guard locations.count >= 2,
              let startTime = locations.first?.timestamp else {
            distance = nil
            duration = nil
            averageSpeed = nil
            return
        }
        
        // Gehe alle Punkte durch und summiere die Entfernungen zwischen den einzelnen Punkten.
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
        
        // Berechne die Zeitdifferenz zwischen erstem und letztem Punkt.
        let endTime = locations.last?.timestamp ?? Date()
        duration = endTime.timeIntervalSince(startTime)
        
        // Berechne die durchschnittliche Geschwindigkeit (Distanz durch Zeit).
        averageSpeed = (duration ?? 0) > 0 ? (distance ?? 0) / (duration ?? 1) : 0
        
        // Berechne den gesamten Aufstieg und Abstieg sowie minimale und maximale Höhe.
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

// Struktur für Markierungen auf der Karte.
// Jede Markierung hat eine Position, einen Typ (Start, Ziel usw.) und ggf. ein Bild.
struct MapMarker: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType
    let imageData: Data?
    
    // Gibt einen passenden Titel für die Markierung zurück.
    var title: String {
        switch type {
        case .start: return "Start"
        case .end: return "Ziel"
        case .normal: return "Punkt"
        case .single: return "Spot"
        }
    }
    
    // Liefert ein Icon für die Markierung.
    var icon: String {
        switch type {
        case .start: return "flag.fill"
        case .end: return "flag.checkered"
        case .normal: return "mappin"
        case .single: return "circle.fill"
        }
    }
    
    // Gibt eine passende Farbe für die Markierung zurück.
    var color: Color {
        switch type {
        case .start: return .green
        case .end: return .blue
        case .normal: return .red
        case .single: return .purple
        }
    }
    
    // Prüft, ob es sich um einen Zwischenpunkt handelt.
    var isIntermediate: Bool {
        type == .normal
    }
    
    // Definiert die verschiedenen Arten von Markierungen.
    enum MarkerType {
        case start, end, normal, single
    }
}
