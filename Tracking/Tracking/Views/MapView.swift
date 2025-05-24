//
//  MapView.swift
//  Tracking
//

import SwiftUI
import MapKit

struct MapMarkerItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let type: MarkerType

    enum MarkerType {
        case normal, start, ziel
    }
}

struct MapView: View {
    let locationsToDisplay: [SavedLocation]
    let mapTitle: String
    
    @State private var cameraPosition: MapCameraPosition
    @State private var hasInitialZoom = false
    
    init(locationsToDisplay: [SavedLocation] = [], mapTitle: String = "") {
        self.locationsToDisplay = locationsToDisplay
        self.mapTitle = mapTitle
        
        // Initiale Kameraposition setzen
        if let firstLocation = locationsToDisplay.first {
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: firstLocation.latitude, longitude: firstLocation.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )))
        } else {
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.0, longitude: 10.0),
                span: MKCoordinateSpan(latitudeDelta: 10.0, longitudeDelta: 10.0)
            )))
        }
    }
    
    private var allMarkers: [MapMarkerItem] {
        locationsToDisplay.enumerated().map { index, location in
            let type: MapMarkerItem.MarkerType
            if locationsToDisplay.count > 1 {
                if index == 0 {
                    type = .start
                } else if index == locationsToDisplay.count - 1 {
                    type = .ziel
                } else {
                    type = .normal
                }
            } else {
                type = .normal
            }

            return MapMarkerItem(
                coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                type: type
            )
        }
    }

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(allMarkers) { item in
                Marker(
                    item.type == .start ? "Start" : (item.type == .ziel ? "Ziel" : "Punkt"),
                    systemImage: item.type == .start ? "flag.fill" : (item.type == .ziel ? "flag.checkered" : "mappin"),
                    coordinate: item.coordinate
                )
                .tint(markerColor(for: item.type))
            }

            if locationsToDisplay.count > 1 {
                MapPolyline(coordinates: locationsToDisplay.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                })
                .stroke(.blue, lineWidth: 3)
            }
        }
        .onAppear {
            // Nur beim ersten Erscheinen zoomen
            if !hasInitialZoom {
                zoomToDisplayedPoints()
                hasInitialZoom = true
            }
        }
        .navigationTitle(mapTitle.isEmpty ? "Karte" : mapTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func zoomToDisplayedPoints() {
        guard !locationsToDisplay.isEmpty else { return }
        
        // Starken Zoom-Level hier zentral definieren
        let minZoomSpan: CLLocationDegrees = 0.001 // Hausansicht (stark gezoomt)
        let padding = 0.2 // 20% Padding um die Route
        
        // Start- und Zielpunkte
        let startCoord = CLLocationCoordinate2D(
            latitude: locationsToDisplay.first!.latitude,
            longitude: locationsToDisplay.first!.longitude
        )
        
        // Fallback für einzelne Punkte
        guard locationsToDisplay.count > 1 else {
            cameraPosition = .region(MKCoordinateRegion(
                center: startCoord,
                span: MKCoordinateSpan(latitudeDelta: minZoomSpan, longitudeDelta: minZoomSpan)
            ))
            return
        }
        
        let endCoord = CLLocationCoordinate2D(
            latitude: locationsToDisplay.last!.latitude,
            longitude: locationsToDisplay.last!.longitude
        )
        
        // Mittelpunkt berechnen
        let center = CLLocationCoordinate2D(
            latitude: (startCoord.latitude + endCoord.latitude) / 2,
            longitude: (startCoord.longitude + endCoord.longitude) / 2
        )
        
        // Differenz berechnen
        let latDiff = abs(startCoord.latitude - endCoord.latitude)
        let lonDiff = abs(startCoord.longitude - endCoord.longitude)
        
        // Finale Zoom-Spanne mit Padding
        let spanLat = max(latDiff * (1 + padding), minZoomSpan)
        let spanLon = max(lonDiff * (1 + padding), minZoomSpan)
        
        cameraPosition = .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        ))
    }

    private func markerColor(for type: MapMarkerItem.MarkerType) -> Color {
        switch type {
        case .normal: return .red
        case .start: return .green
        case .ziel: return .blue
        }
    }
}
