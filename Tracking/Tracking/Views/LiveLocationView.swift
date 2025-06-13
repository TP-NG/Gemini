//
//  LiveLocationView.swift
//  Tracking
//

import SwiftUI
import CoreLocation
import MapKit
import CoreData
// Vibration beim Pausieren/Fortsetzen (optional)
import AudioToolbox

struct LiveLocationView: View {

    @StateObject var locationManager = LiveLocationManager()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isTrackingActive: Bool = false // Zustand, ob eine Tracking-Session aktiv ist
    @State private var currentSession: TrackingSession?

    @State private var sessionName: String = ""
    @State private var coment: String = ""
    @State private var selectedSessionType: SessionType = .gehen
    
    @State private var previewImage: UIImage? = nil // Placeholder für später
    
    @State private var showCamera = false
    
    @State private var autoSaveTimer: Timer?
    
    @State private var interval: Double = 10
    
    @State private var elapsedTime: Double = 0
    @State private var progressTimer: Timer? = nil
    
    @State private var isTrackingPaused = false
    
    @State private var lastSavedLocation: CLLocation? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    // MARK: GPS-Werte anzeigen
                    VStack(spacing: 10) {
                        HStack {
                            Text("Breitengrad:")
                            Spacer()
                            Text(String(format: "%.6f", locationManager.currentLocation?.coordinate.latitude ?? 0.0))
                        }
                        HStack {
                            Text("Längengrad:")
                            Spacer()
                            Text(String(format: "%.6f", locationManager.currentLocation?.coordinate.longitude ?? 0.0))
                        }
                        
                        // Single Point
                        Button(action: {
                            if let currentLocation = locationManager.currentLocation {
                                saveCurrentLocation(location: currentLocation)
                            }
                        }) {
                            Text("Aktuelle Position speichern")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Kommentar:")
                            TextField("Notitz zum Standord", text: $coment)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // MARK: Seesion
                    VStack(alignment: .leading) {
                        Text("Session Name:")
                        TextField("Geben Sie einen Namen für Ihre Session ein...", text: $sessionName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aktivitätstyp:")
                            .font(.headline)
                        HStack {
                            ForEach(SessionType.allCases) { type in
                                Button(action: {
                                    selectedSessionType = type
                                }) {
                                    VStack {
                                        Image(systemName: type == .gehen ? "figure.walk" : "car.fill")
                                            .font(.title2)
                                        Text(type.rawValue)
                                            .font(.subheadline)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(selectedSessionType == type ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedSessionType == type ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    
                    // MARK: Tracking-Steuerung
                    // Intervall
                    VStack(alignment: .leading) {
                        Text("Intervall (Sekunden): \(Int(interval))")
                        Slider(value: $interval, in: 5...30, step: 1)
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Button(action: {
                            isTrackingActive.toggle()
                            if isTrackingActive {
                                // Start Timer
                                startProgressTimer()
                                
                                startNewTrackingSession()
                            } else {
                                progressTimer?.invalidate()
                                endCurrentTrackingSession()
                            }
                        }) {
                            Text(isTrackingActive ? "Stop Tracking" : "Start Tracking")
                        }
                        .padding()
                        
                        if isTrackingActive {
                            // Pause / Continue
                            Button(action: {
                                // progressTimer pausieren oder weiter
                                withAnimation(.spring()) {
                                    isTrackingPaused.toggle()
                                }
                                if isTrackingPaused {
                                    progressTimer?.invalidate() // Timer pausieren
                                    locationManager.stopUpdatingLocation() // Standortupdates stoppen
                                } else {
                                    startProgressTimer() // Timer neu starten
                                    locationManager.startUpdatingLocation() // Standortupdates fortsetzen
                                }
                            }) {
                                Image(systemName: isTrackingPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .symbolEffect(.bounce, value: isTrackingPaused)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .padding()
                            
                            // Save
                            Button(action: {
                                if let currentLocation = locationManager.currentLocation {
                                    saveCurrentLocation(location: currentLocation)
                                }
                            }) {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .symbolEffect(.bounce, value: isTrackingPaused)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                            .padding()
                        }
                    }
                    
                    if isTrackingActive {
                        LocationProgressView(current: elapsedTime, total: interval)
                    }
                    
                    Spacer()
                    
                    // Kamera Button + Vorschau
                    VStack(spacing: 10) {
                        // Kamera Button
                        Button(action: { showCamera = true }) {
                            Label("Foto aufnehmen", systemImage: "camera")
                                .frame(maxWidth: .infinity)  // Für bessere Ausrichtung
                        }
                        .controlButton(color: .blue, isDisabled: false)
                        .padding()
                        .cornerRadius(10)
                        
                        // Preview-Bereich mit fester Größe
                        Group {
                            if let image = previewImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Kein Bild ausgewählt")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 300)  // Feste Dimensionen
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                    
                    // Sicherer Abstand am Ende
                    Spacer(minLength: 50)
                }
                .frame(minHeight: geometry.size.height)
            }
            
        }
        .onAppear {
            locationManager.requestLocationUpdatesIfAuthorized()
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(selectedImage: $previewImage)
        }
        .hideKeyboardOnTap()
        
    }
    
    private func startProgressTimer() {
        progressTimer?.invalidate() // Sicherheitshalber vorhandenen Timer stoppen
        elapsedTime = 0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
            if elapsedTime >= interval {
                elapsedTime = 0
            }
        }
    }

    private func saveLocationSession() {
        
           if let currentLocation = locationManager.currentLocation {
                saveCurrentLocation(location: currentLocation)
            }
        
    }
    
    private func startNewTrackingSession() {
        let newSession = TrackingSession(context: viewContext)
        newSession.id = UUID()
        newSession.startTime = Date()
        newSession.sessionType = selectedSessionType.rawValue
        currentSession = newSession

        locationManager.start() // 📍 Damit GPS wirklich startet
        
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            if let currentLocation = locationManager.currentLocation {
                saveCurrentLocation(location: currentLocation)
            }
        }
    }

    private func endCurrentTrackingSession() {
        currentSession?.endTime = Date()
        
        currentSession = nil
        
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        
        locationManager.stop() // ← Wichtig!
        
        do {
            currentSession?.updateMetrics() // ✅ Neue Berechnung
            try viewContext.save()
            print("✅ Session beendet und Daten gespeichert.")
            sessionName = ""
            previewImage = nil
        } catch {
            print("Fehler beim Speichern der beendeten Session: \(error)")
        }
    }

    private func saveCurrentLocation(location: CLLocation) {
        // Prüfen, ob sich die Position merklich verändert hat (z. B. mehr als 2 Meter)
        if let last = lastSavedLocation, location.distance(from: last) < 2 {
            print("⚠️ Position hat sich nicht wesentlich verändert – kein Speichern.")
            return
        }
        
        let newLocation = SavedLocation(context: viewContext)
        newLocation.id = UUID()
        newLocation.latitude = location.coordinate.latitude
        newLocation.longitude = location.coordinate.longitude
        newLocation.altitude = location.altitude
        newLocation.timestamp = Date()
        
        newLocation.comment = coment
        
        if let image = previewImage, let data = image.jpegData(compressionQuality: 0.8) {
            newLocation.imageData = data
        }

        if let session = currentSession {
            newLocation.isStandalone = false
            session.addToLocations(newLocation)
            if currentSession?.name == nil || currentSession?.name?.isEmpty == true {
                currentSession?.name = sessionName
            }
        } else {
            newLocation.isStandalone = true
        }

        do {
            try viewContext.save()
            lastSavedLocation = location // Update letzte gespeicherte Position
            
            if currentSession != nil {
                print("✅ Punkt in Session gespeichert.")
                previewImage = nil
            } else {
                print("✅ Einzelpunkt gespeichert.")
                sessionName = ""
                coment = ""
                previewImage = nil
            }
        } catch {
            print("Fehler beim Speichern des Standorts: \(error)")
        }
    }
    
}
