//
//  LiveLocationView.swift
//  Tracking
//

import SwiftUI
import CoreLocation
import MapKit
import CoreData

struct LiveLocationView: View {
    @StateObject var locationManager = LiveLocationManager()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isTrackingActive: Bool = false // Zustand, ob eine Tracking-Session aktiv ist
    @State private var currentSession: TrackingSession?

    @State private var comment: String = ""
    
    @State private var previewImage: UIImage? = nil // Placeholder für später
    
    @State private var showCamera = false
    
    @State private var autoSaveTimer: Timer?
    
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
                Text("Kommentar:")
                TextField("Notiz zum Standort", text: $comment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            
            // MARK: Tracking-Steuerung
            HStack {
                Button(action: {
                    isTrackingActive.toggle()
                    if isTrackingActive {
                        startNewTrackingSession()
                    } else {
                        endCurrentTrackingSession()
                    }
                }) {
                    Text(isTrackingActive ? "Stop Tracking" : "Start Tracking")
                }
                .padding()
                
                if isTrackingActive, let currentLocation = locationManager.currentLocation {
                    Button(action: {
                        saveCurrentLocation(location: currentLocation)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.largeTitle)
                    }
                    .padding()
                }
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

    private func startNewTrackingSession() {
        let newSession = TrackingSession(context: viewContext)
        newSession.id = UUID()
        newSession.startTime = Date()
        currentSession = newSession

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
        
        do {
            try viewContext.save()
        } catch {
            print("Fehler beim Speichern der beendeten Session: \(error)")
        }
    }

    private func saveCurrentLocation(location: CLLocation) {
        let newLocation = SavedLocation(context: viewContext)
        newLocation.id = UUID()
        newLocation.latitude = location.coordinate.latitude
        newLocation.longitude = location.coordinate.longitude
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
            
            if currentSession != nil {
                print("✅ Punkt in Session gespeichert.")
            } else {
                print("✅ Einzelpunkt gespeichert.")
            }
        } catch {
            print("Fehler beim Speichern des Standorts: \(error)")
        }
    }
    
}
