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

    @State private var comment: String = ""
    
    @State private var previewImage: UIImage? = nil // Placeholder für später
    
    @State private var showCamera = false
    
    @State private var autoSaveTimer: Timer?
    
    @State private var interval: Double = 10
    
    @State private var elapsedTime: Double = 0
    @State private var progressTimer: Timer? = nil
    
    @State private var isTrackingPaused = false
    
    @State private var lastSavedLocation: CLLocation? = nil
    
    var body: some View {
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
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // MARK: Einzel-Speichern
            // Kommentar
            VStack(alignment: .leading) {
                Text("Kommentar/Session Name:")
                TextField("Notiz zum Standort", text: $comment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
                }
            }
            
            if isTrackingActive {
                LocationProgressView(current: elapsedTime, total: interval)
            }
            
            // Kamera Button + Vorschau
            VStack(spacing: 10) {
                Button(action: {
                    showCamera = true
                }) {
                    Label("Foto aufnehmen", systemImage: "camera")
                }
                .controlButton(color: .blue, isDisabled: false)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .controlButton(color: .blue, isDisabled: false)
                
                if let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                }
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

    private func startNewTrackingSession() {
        let newSession = TrackingSession(context: viewContext)
        newSession.id = UUID()
        newSession.startTime = Date()
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
            comment = ""
            previewImage = nil
        } catch {
            print("Fehler beim Speichern der beendeten Session: \(error)")
        }
    }

    private func saveCurrentLocation(location: CLLocation) {
        // Prüfen, ob sich die Position merklich verändert hat (z. B. mehr als 5 Meter)
        if let last = lastSavedLocation, location.distance(from: last) < 5 {
            print("⚠️ Position hat sich nicht wesentlich verändert – kein Speichern.")
            return
        }
        
        let newLocation = SavedLocation(context: viewContext)
        newLocation.id = UUID()
        newLocation.latitude = location.coordinate.latitude
        newLocation.longitude = location.coordinate.longitude
        newLocation.altitude = location.altitude
        newLocation.timestamp = Date()
        
        newLocation.comment = comment
        if let image = previewImage, let data = image.jpegData(compressionQuality: 0.8) {
            newLocation.imageData = data
        }

        if let session = currentSession {
            newLocation.isStandalone = false
            session.addToLocations(newLocation)
            if currentSession?.name == nil || currentSession?.name?.isEmpty == true {
                currentSession?.name = comment
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
                comment = ""
                previewImage = nil
            }
        } catch {
            print("Fehler beim Speichern des Standorts: \(error)")
        }
    }
    
}
