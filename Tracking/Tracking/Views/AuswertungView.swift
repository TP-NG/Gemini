//
//  AuswertungView.swift
//  Tracking
//

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



// MARK: integrated Views

struct VerlaufDiagrammView: View {
    let sessions: [TrackingSession]
    
    var body: some View {
        Chart {
            ForEach(sessions) { session in
                if let start = session.startTime, session.totalDistance > 0 {
                    BarMark(
                        x: .value("Datum", start, unit: .day),
                        y: .value("Distanz", session.totalDistance / 1000)
                    )
                    .foregroundStyle(by: .value("Session", session.name ?? "Unbenannt"))
                    .annotation(position: .top) {
                        Text("\(session.totalDistance/1000, specifier: "%.1f")km")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .frame(height: 300)
        .padding()
    }
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


// Metriken vor der Anzeige aktualisieren
struct ZusammenfassungView: View {
    let sessions: [TrackingSession]
    
    // Berechnete Werte
    private var totalDistance: Double {
        sessions.reduce(0) { $0 + $1.totalDistance }
    }
    
    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.totalDuration }
    }
    
    // Korrekte Durchschnittsgeschwindigkeit (Gesamtstrecke / Gesamtzeit)
    private var averageSpeed: Double {
        guard totalDuration > 0 else { return 0 }
        return totalDistance / totalDuration
    }
    
    private var totalAscent: Double {
        sessions.reduce(0) { $0 + ($1.totalAscent ?? 0) }
    }

    private var totalDescent: Double {
        sessions.reduce(0) { $0 + ($1.totalDescent ?? 0) }
    }

    private var minAltitude: Double {
        sessions.compactMap { $0.minAltitude }.min() ?? 0
    }

    private var maxAltitude: Double {
        sessions.compactMap { $0.maxAltitude }.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zusammenfassung")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Route Details")
                        .font(.title2.bold())
                        .padding(.bottom, 5)
                    
                    InfoRow(
                        icon: "point.topleft.down.curvedto.point.bottomright.up",
                        label: "Streckenlänge",
                        value: totalDistance != 0 ? String(format: "%.2f km", totalDistance / 1000) : "–"
                    )
                    
                    InfoRow(
                        icon: "stopwatch",
                        label: "Dauer",
                        value: totalDuration != 0 ? formattedDuration(totalDuration) : "–"
                    )
                    
                    InfoRow(
                        icon: "speedometer",
                        label: "Ø Geschwindigkeit",
                        value: formattedSpeed
                    )
                    
                    InfoRow(
                        icon: "arrow.up.right",
                        label: "Aufstieg",
                        value: totalAscent > 0 ? String(format: "%.0f m", totalAscent) : "–"
                    )

                    InfoRow(
                        icon: "arrow.down.right",
                        label: "Abstieg",
                        value: totalDescent > 0 ? String(format: "%.0f m", totalDescent) : "–"
                    )

                    InfoRow(
                        icon: "arrowtriangle.down.circle",
                        label: "Min. Höhe",
                        value: minAltitude > 0 ? String(format: "%.0f m", minAltitude) : "–"
                    )

                    InfoRow(
                        icon: "arrowtriangle.up.circle",
                        label: "Max. Höhe",
                        value: maxAltitude > 0 ? String(format: "%.0f m", maxAltitude) : "–"
                    )
                }
                
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Formatierung
    private var formattedDistance: String {
        if totalDistance < 1000 {
            return "\(Int(totalDistance)) m"
        } else {
            return String(format: "%.1f km", totalDistance / 1000)
        }
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        print(duration)
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute, .second]
      formatter.unitsStyle = .abbreviated
      return formatter.string(from: duration) ?? "0s"
    }
    
    private var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        
        if totalDuration >= 3600 {
            // Format: 1h 5m 30s
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .abbreviated
        } else {
            // Format: 1m 10s
            formatter.allowedUnits = [.minute, .second]
            formatter.unitsStyle = .short
        }
        
        print("""
        Test-Ergebnisse:
        - Berechnete Distanz: \(totalDistance)m
        - Erwartete Duration: \(totalDuration)m
        """)
        
        // Spezialfall: Weniger als 1 Minute
        if totalDuration < 60 {
            return "\(Int(totalDuration))s"
        }
        let tmp = String(format: "%.1f km/h", totalDuration * 3.6)
        print(tmp)
        
        return formatter.string(from: totalDuration) ?? "0s"
    }
    
    private var formattedSpeed: String {
        
        print("""
        Test-Ergebnisse:
        - averageSpeed: \(averageSpeed)m
        """)
        
        return String(format: "%.1f km/h", averageSpeed * 3.6)
    }
}
