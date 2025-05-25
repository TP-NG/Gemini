//
//  AuswertungView.swift
//  Tracking
//

import SwiftUI
import Charts
import CoreData

import SwiftUI
import Charts
import CoreData

struct AuswertungView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackingSession.startTime, ascending: false)]
    ) var sessions: FetchedResults<TrackingSession>

    @State private var selectedZeitraum: ZeitFilter = .monat

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ZeitraumFilterView(selected: $selectedZeitraum)
                    
                    // Metriken vor der Anzeige aktualisieren
                    ZusammenfassungView(sessions: filteredSessions.map { session in
                        session.updateMetrics()
                        return session
                    })
                    
                    VerlaufDiagrammView(sessions: filteredSessions)
                    
                    SessionListeView(sessions: filteredSessions)
                }
                .padding()
            }
            .navigationTitle("Auswertung")
            .onAppear {
                // Alle Sessions aktualisieren
                sessions.forEach { $0.updateMetrics() }
                try? viewContext.save()
            }
        }
    }

    var filteredSessions: [TrackingSession] {
        let now = Date()
        let calendar = Calendar.current

        switch selectedZeitraum {
        case .monat:
            return sessions.filter {
                calendar.isDate($0.startTime ?? .distantPast, equalTo: now, toGranularity: .month)
            }
        case .woche:
            return sessions.filter {
                calendar.isDate($0.startTime ?? .distantPast, equalTo: now, toGranularity: .weekOfYear)
            }
        case .alle:
            return Array(sessions)
        }
    }
}

enum ZeitFilter: String, CaseIterable, Identifiable {
    case monat = "Monat"
    case woche = "Woche"
    case alle = "Alle"

    var id: String { self.rawValue }
}

struct ZeitraumFilterView: View {
    @Binding var selected: ZeitFilter

    var body: some View {
        Picker("Zeitraum", selection: $selected) {
            ForEach(ZeitFilter.allCases, id: \ .self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct ZusammenfassungView: View {
    let sessions: [TrackingSession]
    
    // Korrekte Berechnung der Gesamtwerte
    var totalDistance: Double {
        sessions.reduce(0) { $0 + $1.totalDistance }
    }
    
    var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.totalDuration }
    }
    
    var averageSpeed: Double {
        let validSessions = sessions.filter { $0.totalDuration > 0 }
        guard !validSessions.isEmpty else { return 0 }
        
        let totalSpeed = validSessions.reduce(0) { $0 + $1.averageSpeed }
        return totalSpeed / Double(validSessions.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zusammenfassung").font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Gesamtstrecke:")
                    Text("\(formattedDistance(totalDistance))")
                        .font(.title2.bold())
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Gesamtdauer:")
                    Text("\(formattedTime(totalDuration))")
                        .font(.title2.bold())
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Ø Geschwindigkeit:")
                    Text("\(formattedSpeed(averageSpeed))")
                        .font(.title2.bold())
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Hilfsfunktionen für Formatierung
    private func formattedDistance(_ meters: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 2
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
    
    private func formattedTime(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? "0s"
    }
    
    private func formattedSpeed(_ metersPerSecond: Double) -> String {
        let kmPerHour = metersPerSecond * 3.6
        return String(format: "%.1f km/h", kmPerHour)
    }
}

struct VerlaufDiagrammView: View {
    let sessions: [TrackingSession]
    var body: some View {
        Chart(sessions, id: \.self) { session in
            if let start = session.startTime, session.totalDistance > 0 {
                BarMark(
                    x: .value("Datum", start),
                    y: .value("Distanz", session.totalDistance / 1000)
                )
            }
        }
        .frame(height: 200)
    }
}

struct SessionListeView: View {
    let sessions: [TrackingSession]
    var body: some View {
        VStack(alignment: .leading) {
            Text("Einzelsessions")
                .font(.headline)
            ForEach(sessions, id: \.self) { session in
                Text(session.name ?? "Unbenannt")
            }
        }
    }
}
