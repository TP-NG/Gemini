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
                        session.optimizedUpdateMetrics()
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


