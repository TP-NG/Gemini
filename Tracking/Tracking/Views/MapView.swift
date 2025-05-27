//
//  MapView.swift
//  Tracking
//

import SwiftUI
import MapKit

struct MapView: View {
    // MARK: - Existing Properties
        let locationsToDisplay: [SavedLocation]
        let mapTitle: String
        
        @StateObject private var viewModel = MapViewModel()
        @State private var cameraPosition: MapCameraPosition
        @State private var showInfoSheet = false
        
        // MARK: - Image Handling Properties (KORREKTUR HIER)
        @State private var selectedImageData: Data = Data() // Nicht optional, initial leer
        @State private var showImageDetail = false
    
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
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Kartenansicht
            Map(position: $cameraPosition) {
                // Marker / Annotation
                ForEach(viewModel.markers) { item in
                    
                    // Absolute Null-Check-Sicherheit
                    if CLLocationCoordinate2DIsValid(item.coordinate) {
                        // Einzelne Punkte immer anzeigen, auch wenn sie isIntermediate sind
                        if let imageData = item.imageData, let uiImage = loadImage(from: imageData) {
                            // Marker mit Bildvorschau
                            Annotation(item.title, coordinate: item.coordinate) {
                                Button {
                                    if let validData = item.imageData {
                                           print("✅ Daten valid - Größe: \(validData.count) bytes")
                                           selectedImageData = validData // Direkte Zuweisung
                                           showImageDetail = true
                                       } else {
                                           print("❌ Keine Bilddaten vorhanden")
                                       }
                                } label: {
                                    if let imageData = item.imageData,
                                       let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Image(systemName: "photo")
                                            .frame(width: 40, height: 40)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        } else if !item.isIntermediate {
                            // Standard-Marker nur für nicht-intermediäre Punkte ohne Bild
                            Marker(
                                item.title,
                                systemImage: item.icon,
                                coordinate: item.coordinate
                            )
                            .tint(item.color)
                        }
                    }
                }
                
                if viewModel.shouldShowRoute && !viewModel.routeCoordinates.isEmpty {
                    MapPolyline(coordinates: viewModel.routeCoordinates)
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
                    .background(Circle().fill(.ultraThinMaterial))
                    .shadow(radius: 5)
            }
            .padding()
        }
        .sheet(isPresented: $showImageDetail) {
            ImageDetailView(imageData: selectedImageData) // Übergabe der gesicherten Daten
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoOverlayContent(
                locations: locationsToDisplay,
                distance: viewModel.distance,
                duration: viewModel.duration,
                speed: viewModel.averageSpeed,
                totalAscent: viewModel.totalAscent,
                totalDescent: viewModel.totalDescent,
                minAltitude: viewModel.minAltitude,
                maxAltitude: viewModel.maxAltitude
            )
            .presentationDetents([.medium, .large])
        }
        .task(id: locationsToDisplay.hashValue) {
            await viewModel.update(with: locationsToDisplay)
            zoomToDisplayedPoints()
        }
        .navigationTitle(mapTitle.isEmpty ? "Karte" : mapTitle)
    }
    
    private func loadImage(from data: Data?) -> UIImage? {
        guard let data = data else {
            print("Keine Bilddaten vorhanden")
            return nil
        }
        
        guard let image = UIImage(data: data) else {
            print("Bilddaten konnten nicht dekodiert werden")
            return nil
        }
        
        print("Bild erfolgreich geladen. Größe: \(image.size)")
        return image
    }
    
    private func zoomToDisplayedPoints() {
        guard !viewModel.routeCoordinates.isEmpty else { return }
        
        let minZoomSpan: CLLocationDegrees = 0.001
        let padding = 0.2
        
        let coordinates = viewModel.routeCoordinates
        
        // Angepasster Zoom für einzelne Punkte
        if coordinates.count == 1 {
            cameraPosition = .camera(
                MapCamera(
                    centerCoordinate: coordinates[0],
                    distance: 500, // Höhe in Metern
                    heading: 0,
                    pitch: 60
                )
            )
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min()!
        let maxLat = coordinates.map { $0.latitude }.max()!
        let minLon = coordinates.map { $0.longitude }.min()!
        let maxLon = coordinates.map { $0.longitude }.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * (1 + padding), minZoomSpan),
            longitudeDelta: max((maxLon - minLon) * (1 + padding), minZoomSpan)
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

/*
struct ImageDetailView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss
    @State private var scale: CGFloat = 1.0
    
    // Skaliertes Bild für bessere Performance
    private var scaledImage: UIImage {
        let targetSize = CGSize(width: UIScreen.main.bounds.width * 2,
                              height: UIScreen.main.bounds.height * 2)
        return image.scaled(to: targetSize)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView([.horizontal, .vertical]) {
                Image(uiImage: scaledImage)  // ← Verwende skaliertes Bild
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale = $0.magnitude }
                    )
            }
            .background(.black)
            .navigationTitle("Bild")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
*/

struct ImageDetailView: View {
    let imageData: Data // Nicht optional!
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                VStack {
                    ProgressView()
                    Text("Lade \(imageData.count.formatted()) Bytes...")
                        .foregroundColor(.white)
                }
            }
        }
        .task {
            image = await ImageLoader.loadImage(from: imageData)
            print("Bildstatus: \(image != nil ? "Erfolg" : "Fehler")")
        }
    }
}

struct AsyncImageView: View {
    let imageData: Data
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(2)
            } else if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .task {
            await loadImageInBackground()
        }
    }
    
    private func loadImageInBackground() async {
        // Hintergrund-Thread für schwere Operationen
        let task = Task.detached(priority: .userInitiated) {
            // Kleine Verzögerung für flüssigere UI (optional)
            try? await Task.sleep(nanoseconds: 100_000_000)
            return UIImage(data: imageData)?.scaled(to: CGSize(width: 2000, height: 2000))
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        let result = await task.value
        
        await MainActor.run {
            image = result
            isLoading = false
        }
    }
}


struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    @Binding var scale: CGFloat
    @Binding var lastScale: CGFloat
    
    init(scale: Binding<CGFloat>, lastScale: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
        self._scale = scale
        self._lastScale = lastScale
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)
        
        return scrollView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(hostingController: UIHostingController(rootView: content), scale: $scale, lastScale: $lastScale)
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
        uiView.zoomScale = scale
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        @Binding var scale: CGFloat
        @Binding var lastScale: CGFloat
        
        init(hostingController: UIHostingController<Content>, scale: Binding<CGFloat>, lastScale: Binding<CGFloat>) {
            self.hostingController = hostingController
            self._scale = scale
            self._lastScale = lastScale
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            self.scale = scale
            self.lastScale = scale
        }
    }
}

// MARK: - Info Overlay Komponente
struct InfoOverlayContent: View {
    let locations: [SavedLocation]
    let distance: Double?
    let duration: TimeInterval?
    let speed: Double?
    
    let totalAscent: Double?
    let totalDescent: Double?
    let minAltitude: Double?
    let maxAltitude: Double?
    
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
                    RouteInfoView(distance: distance, duration: duration, pointCount: locations.count, speed: speed, totalAscent: totalAscent, totalDescent: totalDescent, minAltitude: minAltitude, maxAltitude: maxAltitude)
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
    let speed: Double?
    
    let totalAscent: Double?
    let totalDescent: Double?
    let minAltitude: Double?
    let maxAltitude: Double?
    
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
            
            if let speed = speed {
                InfoRow(
                    icon: "speedometer",
                    label: "Ø Geschwindigkeit",
                    value: String(format: "%.1f km/h", speed * 3.6)
                )
            }
            
            InfoRow(
                icon: "arrow.up.right",
                label: "Aufstieg",
                value: totalAscent! > 0 ? String(format: "%.0f m", totalAscent!) : "–"
            )
            
            InfoRow(
                icon: "arrow.down.right",
                label: "Abstieg",
                value: totalDescent! > 0 ? String(format: "%.0f m", totalDescent!) : "–"
            )
            
            InfoRow(
                icon: "arrowtriangle.down.circle",
                label: "Min. Höhe",
                value: minAltitude! > 0 ? String(format: "%.0f m", minAltitude!) : "–"
            )
            
            InfoRow(
                icon: "arrowtriangle.up.circle",
                label: "Max. Höhe",
                value: maxAltitude! > 0 ? String(format: "%.0f m", maxAltitude!) : "–"
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
                
                if point.altitude > 0 {
                    InfoRow(icon: "mountain.2.fill", label: "Höhe", value: String(format: "%.0f m", point.altitude))
                }
                
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
