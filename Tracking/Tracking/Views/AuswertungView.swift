//  AuswertungView.swift
//  Tracking

import SwiftUI
import Charts
import CoreData

struct AuswertungView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackingSession.startTime, ascending: false)],
        animation: .default
    ) var sessions: FetchedResults<TrackingSession>
    
    @State private var selectedZeitraum: ZeitFilter = .monat
    @State private var diagrammDaten: [ChartDataPoint] = []
    
    private var filteredSessions: [TrackingSession] {
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
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ZeitraumFilterView(selected: $selectedZeitraum)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                
                Section("Verlauf") {
                    VerlaufDiagrammView(daten: diagrammDaten)
                        .frame(height: 250)
                        .padding(.vertical, 8)
                }
                
                Section("Zusammenfassung") {
                    ZusammenfassungView(sessions: filteredSessions)
                }
                
                Section("Einzelsessions") {
                    ForEach(filteredSessions) { session in
                        SessionRow(session: session)
                    }
                }
            }
            .navigationTitle("Auswertung")
            .onAppear {
                sessions.forEach { $0.updateMetrics() }
                try? viewContext.save()
                berechneDiagrammDaten()
            }
            .onChange(of: selectedZeitraum) { _ in
                berechneDiagrammDaten()
            }
        }
    }
    
    private func berechneDiagrammDaten() {
        let gruppierteDaten = Dictionary(
            grouping: filteredSessions,
            by: { Calendar.current.startOfDay(for: $0.startTime ?? Date()) }
        )
        
        diagrammDaten = gruppierteDaten
            .map { key, values in
                ChartDataPoint(
                    datum: key,
                    distanz: values.reduce(0) { $0 + $1.totalDistance }
                )
            }
            .sorted(by: { $0.datum < $1.datum })
    }
}

// MARK: - Hilfsstrukturen
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let datum: Date
    let distanz: Double
    
    var distanzKm: Double { distanz / 1000 }
}

enum ZeitFilter: String, CaseIterable, Identifiable {
    case monat = "Monat"
    case woche = "Woche"
    case alle = "Alle"
    
    var id: String { self.rawValue }
}

// MARK: - Subviews
struct ZeitraumFilterView: View {
    @Binding var selected: ZeitFilter
    
    var body: some View {
        Picker("Zeitraum", selection: $selected) {
            ForEach(ZeitFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.vertical, 8)
    }
}

struct VerlaufDiagrammView: View {
    let daten: [ChartDataPoint]
    
    var body: some View {
        Chart(daten) { punkt in
            LineMark(
                x: .value("Datum", punkt.datum, unit: .day),
                y: .value("Distanz", punkt.distanzKm)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.blue)
            
            PointMark(
                x: .value("Datum", punkt.datum, unit: .day),
                y: .value("Distanz", punkt.distanzKm)
            )
            .symbol(Circle().strokeBorder(lineWidth: 2))
            .foregroundStyle(.white)
            .annotation(position: .top) {
                Text("\(punkt.distanzKm.formatted(.number.precision(.fractionLength(1)))) km")
                    .font(.system(size: 9))
                    .padding(2)
                    .background(.ultraThinMaterial)
                    .cornerRadius(4)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(format: .dateTime.day().month(.narrow))
                }
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

struct ZusammenfassungView: View {
    let sessions: [TrackingSession]
    
    private var totalDistance: Double { sessions.reduce(0) { $0 + $1.totalDistance } }
    private var totalDuration: TimeInterval { sessions.reduce(0) { $0 + $1.totalDuration } }
    private var averageSpeed: Double { totalDuration > 0 ? totalDistance / totalDuration : 0 }
    private var totalAscent: Double { sessions.reduce(0) { $0 + ($1.totalAscent ?? 0) } }
    private var totalDescent: Double { sessions.reduce(0) { $0 + ($1.totalDescent ?? 0) } }
    
    private let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: gridItems, alignment: .leading, spacing: 12) {
            MetricView(
                icon: "point.topleft.down.curvedto.point.bottomright.up",
                title: "Strecke",
                value: totalDistance > 0 ? "\( (totalDistance / 1000).formatted(.number.precision(.fractionLength(2))) ) km" : "-"
            )
            
            MetricView(
                icon: "stopwatch",
                title: "Dauer",
                value: totalDuration > 0 ? formattedDuration(totalDuration) : "-"
            )
            
            MetricView(
                icon: "speedometer",
                title: "Ø Geschw.",
                value: "\((averageSpeed * 3.6).formatted(.number.precision(.fractionLength(1)))) km/h"
            )
            
            MetricView(
                icon: "arrow.up.right",
                title: "Aufstieg",
                value: totalAscent > 0 ? "\(totalAscent.formatted(.number.precision(.fractionLength(0)))) m" : "-"
            )
            
            MetricView(
                icon: "arrow.down.right",
                title: "Abstieg",
                value: totalDescent > 0 ? "\(totalDescent.formatted(.number.precision(.fractionLength(0)))) m" : "-"
            )
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %02dm", hours, minutes)
        } else {
            return String(format: "%dm %02ds", minutes, seconds)
        }
    }
}

struct MetricView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
        }
    }
}

struct SessionRow: View {
    let session: TrackingSession
    
    private var distanceKm: Double { session.totalDistance / 1000 }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.name ?? "Unbenannte Session")
                    .font(.subheadline)
                
                if let start = session.startTime {
                    Text(start.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(distanceKm.formatted(.number.precision(.fractionLength(1)))) km")
                .font(.callout)
        }
        .padding(.vertical, 4)
    }
}
