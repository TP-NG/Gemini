//
//  SessionDetailView.swift
//  Tracking
//

import SwiftUI
import CoreData
import HealthKit // HealthKit importieren

struct SessionDetailView: View {
    var session: TrackingSession
    
    // State für gesammelte Schritte
    @State private var steps: Int?
    // State für Fehlermeldungen
    @State private var healthKitError: String?
    
    // HealthKit Store
    private let healthStore = HKHealthStore()
    
    var imageCount: Int {
        guard let locations = session.locations else { return 0 }
        let savedLocations = locations.compactMap { $0 as? SavedLocation }
        return savedLocations.filter { $0.imageData != nil }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(session.name!)
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)

                GroupBox(label: Label("Zeit", systemImage: "clock")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Start", systemImage: "play.fill")
                        Text(formattedDate(session.startTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Label("Ende", systemImage: "stop.fill")
                        Text(formattedDate(session.endTime))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Label("Dauer", systemImage: "stopwatch")
                        Text(formattedDuration(session.totalDuration))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                GroupBox(label: Label("Aktivität", systemImage: "figure.walk")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Distanz", systemImage: "map")
                        Text("\(String(format: "%.2f", session.totalDistance / 1000)) km")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Label("Punkte", systemImage: "location")
                        Text("\(session.locations?.count ?? 0)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Label("Bilder", systemImage: "photo")
                        Text("\(imageCount)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                }

                // Horizontale ScrollView für Bild-Thumbnails (Ribbon)
                if let locations = session.locations as? Set<SavedLocation> {
                    let imageLocations = locations.filter { $0.imageData != nil }
                    if !imageLocations.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(imageLocations), id: \.self) { location in
                                    if let data = location.imageData,
                                       let uiImage = UIImage(data: data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }

                GroupBox(label: Label("Gesundheit", systemImage: "heart.fill")) {
                    if let steps = steps {
                        Label("Schritte: \(steps)", systemImage: "figure.walk")
                            .font(.subheadline)
                    } else if let error = healthKitError {
                        Label("Fehler: \(error)", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.subheadline)
                    } else {
                        HStack {
                            Label("Schritte: Wird geladen...", systemImage: "hourglass")
                            Spacer()
                            ProgressView()
                        }
                        .font(.subheadline)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Session")
        .onAppear {
            loadHealthKitSteps()
        }
    }
    
    // Schrittdaten aus HealthKit laden
    private func loadHealthKitSteps() {
        // Prüfen, ob HealthKit verfügbar ist
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitError = "HealthKit nicht verfügbar"
            return
        }
        
        // Zeitraum der Session
        guard let start = session.startTime, let end = session.endTime else {
            healthKitError = "Ungültiger Zeitraum"
            return
        }
        
        // Schrittzähler-Datentyp anfordern
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            healthKitError = "Schrittdaten nicht unterstützt"
            return
        }
        
        // Berechtigungen prüfen
        healthStore.requestAuthorization(toShare: nil, read: [stepType]) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.healthKitError = "Fehler: \(error.localizedDescription)"
                    return
                }

                if !success {
                    self.healthKitError = "Berechtigung verweigert"
                    return
                }
                
                // Prädikat für den Zeitraum erstellen
                let predicate = HKQuery.predicateForSamples(
                    withStart: start,
                    end: end,
                    options: .strictStartDate
                )
                
                // Query für Schrittdaten
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, result, error in
                    if let error = error {
                        healthKitError = error.localizedDescription
                        return
                    }
                    
                    // Schritte extrahieren
                    let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    
                    DispatchQueue.main.async {
                        self.steps = Int(steps)
                    }
                }
                
                healthStore.execute(query)
            }
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unbekannt" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}
