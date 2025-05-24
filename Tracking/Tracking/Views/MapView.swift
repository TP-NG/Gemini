//
//  MapView.swift
//  Tracking
//

import SwiftUI
import MapKit
import CoreLocation

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
    @State private var showInfoSheet = false
    @State private var calculatedDistance: Double?
    @State private var calculatedDuration: TimeInterval?
    
    init(locationsToDisplay: [SavedLocation] = [], mapTitle: String = "") {
        self.locationsToDisplay = locationsToDisplay
        self.mapTitle = mapTitle
        
        if let firstLocation = locationsToDisplay.first {
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: firstLocation.latitude,
                    longitude: firstLocation.longitude
                ),
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
            let type: MapMarkerItem.MarkerType = {
                if locationsToDisplay.count > 1 {
                    if index == 0 { return .start }
                    if index == locationsToDisplay.count - 1 { return .ziel }
                }
                return .normal
            }()
            
            return MapMarkerItem(
                coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                ),
                type: type
            )
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Kartenansicht
            Map(position: $cameraPosition) {
                // Marker
                ForEach(allMarkers) { item in
                    Marker(
                        item.type == .start ? "Start" : (item.type == .ziel ? "Ziel" : "Punkt"),
                        systemImage: item.type == .start ? "flag.fill" :
                                   (item.type == .ziel ? "flag.checkered" : "mappin"),
                        coordinate: item.coordinate
                    )
                    .tint(markerColor(for: item.type))
                }
                
                // Route (nur bei mehreren Punkten)
                if locationsToDisplay.count > 1 {
                    MapPolyline(
                        coordinates: locationsToDisplay.map {
                            CLLocationCoordinate2D(
                                latitude: $0.latitude,
                                longitude: $0.longitude
                            )
                        }
                    )
                    .stroke(.blue, lineWidth: 3)
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            
            // Info-Button
            Button(action: { showInfoSheet.toggle() }) {
                Image(systemName: "info.circle.fill")
                    .font(.title)
                    .padding(10)
                    .background(Circle().fill(Color.white))
                    .shadow(radius: 5)
            }
            .padding()
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoOverlayContent(
                locations: locationsToDisplay,
                distance: calculatedDistance,
                duration: calculatedDuration
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            calculateMetrics()
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
        
        let minZoomSpan: CLLocationDegrees = 0.001
        let padding = 0.2
        
        let startCoord = CLLocationCoordinate2D(
            latitude: locationsToDisplay.first!.latitude,
            longitude: locationsToDisplay.first!.longitude
        )
        
        // Einzelpunkt
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
        
        // Region berechnen
        let center = CLLocationCoordinate2D(
            latitude: (startCoord.latitude + endCoord.latitude) / 2,
            longitude: (startCoord.longitude + endCoord.longitude) / 2
        )
        
        let latDiff = abs(startCoord.latitude - endCoord.latitude)
        let lonDiff = abs(startCoord.longitude - endCoord.longitude)
        
        cameraPosition = .region(MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: max(latDiff * (1 + padding), minZoomSpan),
                longitudeDelta: max(lonDiff * (1 + padding), minZoomSpan)
            )
        ))
    }
    
    private func calculateMetrics() {
        guard locationsToDisplay.count > 1 else { return }
        
        // Distanz berechnen
        var totalDistance: Double = 0
        for i in 1..<locationsToDisplay.count {
            let prev = locationsToDisplay[i-1]
            let current = locationsToDisplay[i]
            totalDistance += CLLocation(
                latitude: prev.latitude,
                longitude: prev.longitude
            ).distance(from: CLLocation(
                latitude: current.latitude,
                longitude: current.longitude
            ))
        }
        calculatedDistance = totalDistance
        
        // Dauer berechnen
        if let start = locationsToDisplay.first?.timestamp,
           let end = locationsToDisplay.last?.timestamp {
            calculatedDuration = end.timeIntervalSince(start)
        }
    }
    
    private func markerColor(for type: MapMarkerItem.MarkerType) -> Color {
        switch type {
        case .normal: return .red
        case .start: return .green
        case .ziel: return .blue
        }
    }
}

// MARK: - Info Overlay Komponente
struct InfoOverlayContent: View {
    let locations: [SavedLocation]
    let distance: Double?
    let duration: TimeInterval?
    
    var body: some View {
        ZStack {
            // Transparenter Blur-Hintergrund
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial) // WICHTIG: iOS 15+ Feature
                .opacity(0.9) // Deckkraft anpassbar (0.8-1.0)
                .shadow(radius: 5)
            
            // Inhalt
            VStack {
                if locations.count > 1 {
                    RouteInfoView(distance: distance, duration: duration, pointCount: locations.count)
                } else if let point = locations.first {
                    SinglePointInfoView(point: point)
                }
            }
            .padding(20)
        }
        .padding()
        .frame(maxWidth: .infinity)
        
    }
}


struct RouteInfoView: View {
    let distance: Double?
    let duration: TimeInterval?
    let pointCount: Int
    
    // Neuer Zustand für dynamische Deckkraft
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Route Details")
                .font(.title2.bold())
                .padding(.bottom, 5)
            
            InfoRow(
                icon: "point.topleft.down.curvedto.point.bottomright.up",
                label: "Streckenlänge",
                value: distance != nil ? String(format: "%.2f km", distance! / 1000) : "–"
            )
            
            InfoRow(
                icon: "stopwatch",
                label: "Dauer",
                value: duration != nil ? formattedDuration(duration!) : "–"
            )
            
            InfoRow(
                icon: "mappin.and.ellipse",
                label: "Anzahl Punkte",
                value: "\(pointCount)"
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // Transparenter Material-Hintergrund
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ?
                      Material.ultraThinMaterial.opacity(0.1) :
                      Material.regularMaterial.opacity(0.15))
                .shadow(radius: 10)
        )
        .padding()
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

struct SinglePointInfoView: View {
    let point: SavedLocation
    
    
    // Neuer Zustand für dynamische Deckkraft
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Punkt Details")
                    .font(.title2.bold())
                    .padding(.bottom, 5)
                
                InfoRow(
                    icon: "mappin",
                    label: "Koordinaten",
                    value: String(format: "%.6f, %.6f", point.latitude, point.longitude)
                )
                
                InfoRow(
                    icon: "calendar",
                    label: "Datum",
                    value: point.timestamp?.formatted() ?? "Unbekannt"
                )
                
                if let comment = point.comment, !comment.isEmpty {
                    InfoRow(
                        icon: "text.bubble",
                        label: "Kommentar",
                        value: comment
                    )
                }
                
                ImageSection(point: point)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Transparenter Material-Hintergrund
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ?
                          Material.ultraThinMaterial.opacity(0.1) :
                          Material.regularMaterial.opacity(0.15))
                    .shadow(radius: 10)
            )
            .padding()
        }
    }
}

struct ImageSection: View {
    let point: SavedLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bild")
                .font(.headline)
            
            if let imageData = point.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                Text("Kein Bild vorhanden")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
