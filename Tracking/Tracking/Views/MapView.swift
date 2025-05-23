//
//  MapView.swift
//  Tracking
//

import SwiftUI
import MapKit
// CoreData wird hier nicht mehr direkt für einen FetchRequest benötigt,
// aber die Typen wie SavedLocation schon, wenn sie übergeben werden.

// MapMarkerItem bleibt wie gehabt
struct MapMarkerItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType

    enum MarkerType {
        case normal, start, ziel
    }
}

struct MapView: View {
    // Eingabeparameter: Die Standorte, die angezeigt werden sollen.
    // Diese Liste wird von der aufrufenden View basierend auf der Benutzerauswahl (Session oder Einzelpunkte) vorbereitet.
    let locationsToDisplay: [SavedLocation] // SavedLocation ist dein Core Data Entity Typ

    // Ein optionaler Titel für die Karte, der z.B. den Namen der Session anzeigen könnte.
    let mapTitle: String

    // Zustand für die Kartenregion.
    @State private var region: MKCoordinateRegion

    // Initializer, um die Startregion basierend auf den ersten Daten zu setzen
    // oder eine Standardregion, falls keine Daten vorhanden sind.
    init(locationsToDisplay: [SavedLocation], mapTitle: String) {
        self.locationsToDisplay = locationsToDisplay
        self.mapTitle = mapTitle
        
        if let firstLocation = locationsToDisplay.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: firstLocation.latitude, longitude: firstLocation.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) // Sinnvoller Start-Zoom
            ))
        } else {
            // Standardregion, falls keine Orte vorhanden sind (z.B. Mitte Deutschlands)
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.0, longitude: 10.0),
                span: MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0)
            ))
        }
    }
    
    // Erstellt die MapMarkerItems basierend auf den locationsToDisplay.
    // Die Logik für Start/Ziel-Marker greift nur, wenn es sich um eine Session handelt (mehr als 1 Punkt).
    // Für einzelne Punkte wird nur ein 'normaler' Marker angezeigt.
    private var allMarkers: [MapMarkerItem] {
        locationsToDisplay.enumerated().map { index, location in
            let type: MapMarkerItem.MarkerType
            // Annahme: Wenn locationsToDisplay mehrere Punkte hat, ist es eine Session/Route.
            // Wenn nur ein Punkt, ist es ein Einzelpunkt.
            // Dies könnte man expliziter machen durch einen weiteren Parameter in MapView, z.B. `displayMode: .session` oder `.singlePoint`.
            if locationsToDisplay.count > 1 { // Behandle als Route/Session
                if index == 0 {
                    type = .start
                } else if index == locationsToDisplay.count - 1 {
                    type = .ziel
                } else {
                    type = .normal
                }
            } else { // Behandle als Einzelpunkt
                type = .normal // Oder ein spezieller Typ für Einzelpunkte
            }

            return MapMarkerItem(
                coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                type: type
            )
        }
    }

    var body: some View {
        Map(initialPosition: .region(region)) { // Oder Map(position: $region) für iOS 17+ für dynamische Updates
            ForEach(allMarkers) { item in
                Marker(item.type == .start ? "Start" : (item.type == .ziel ? "Ziel" : ""), coordinate: item.coordinate)
                    .tint(markerColor(for: item.type))
                    // .annotationTitles(.hidden) // Überlege, ob du Titel anzeigen möchtest
            }

            // Polylinie nur zeichnen, wenn es mehr als einen Punkt gibt (also eine Route).
            if locationsToDisplay.count > 1 {
                MapPolyline(coordinates: locationsToDisplay.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                })
                .stroke(.blue, lineWidth: 3)
            }
        }
        .onAppear {
            // Beim Erscheinen auf die übergebenen Punkte zoomen.
            zoomToDisplayedPoints()
        }
        // Setzt den Titel dynamisch basierend auf dem, was angezeigt wird.
        .navigationTitle(mapTitle.isEmpty ? "Karte" : mapTitle)
    }

    // Passt die Kartenregion an, sodass alle `locationsToDisplay` sichtbar sind.
    private func zoomToDisplayedPoints() {
        guard !locationsToDisplay.isEmpty else { return }

        // Die Logik von deiner ursprünglichen zoomToAllPoints-Funktion kann hierher verschoben
        // und angepasst werden, um mit `locationsToDisplay` zu arbeiten.
        let coordinates = locationsToDisplay.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }

        if coordinates.count == 1, let singleCoordinate = coordinates.first {
            // Bei nur einem Punkt zentriere darauf mit einem Standard-Zoomlevel.
            region = MKCoordinateRegion(
                center: singleCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02) // Detailansicht für einen Punkt
            )
            return
        }
        
        // Min/Max-Berechnung wie zuvor
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max() else {
            // Fallback, falls min/max nicht ermittelt werden können (sollte bei !isEmpty nicht passieren)
            if let firstCoord = coordinates.first {
                 region = MKCoordinateRegion(center: firstCoord, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            }
            return
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let spanLat = max((maxLat - minLat) * 1.5, 0.01) // Faktor 1.5 für Padding
        let spanLon = max((maxLon - minLon) * 1.5, 0.01) // Mindestspanne
        
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        )
    }

    // Gibt die Farbe für einen Marker basierend auf seinem Typ zurück.
    private func markerColor(for type: MapMarkerItem.MarkerType) -> Color {
        switch type {
        case .normal: return .red
        case .start: return .green
        case .ziel: return .blue // Beachte, dass 'ziel' im Code oft als 'blue' definiert ist.
        }
    }
}
