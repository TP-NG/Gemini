//
//  SessionListView.swift
//  Tracking
//

import SwiftUI
import CoreData

struct SessionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedSession: TrackingSession?
    @State private var selectedLocation: SavedLocation?
    @State private var showDetailSheet = false
    @State private var editSession = false
    @State private var editLocation = false
    @State private var showSessions = false
    @State private var showLocations = false
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\TrackingSession.startTime, order: .reverse)])
    private var sessions: FetchedResults<TrackingSession>

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\SavedLocation.timestamp, order: .reverse)],
        predicate: NSPredicate(format: "isStandalone == true")
    )
    private var standaloneLocations: FetchedResults<SavedLocation>

    @State private var selectedMonth: Date = Date()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gespeicherte Orte & Routen")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.horizontal)
                ScrollView {
                    YearMonthPickerView(selectedDate: $selectedMonth)
                    
                    LazyVStack(alignment: .leading, spacing: 16) {
                        
                        // Sessions Überschrift als Button
                        Button(action: {
                            withAnimation { showSessions.toggle() }
                        }) {
                            HStack {
                                Image(systemName: showSessions ? "chevron.down" : "chevron.right")
                                Text("Sessions")
                                    .font(.title3)
                                    .bold()
                            }
                            .padding(.horizontal)
                            .foregroundColor(.primary)
                        }
                        
                        // Sessions Liste
                        if showSessions {
                            ForEach(filteredGroupedSessions.sorted(by: { $0.key > $1.key }), id: \.key) { month, sessionsInMonth in
                                Text("🗓 \(month)")
                                    .font(.title3)
                                    .bold()
                                    .padding(.horizontal)
                                    .foregroundColor(.primary)
                                
                                ForEach(sessionsInMonth) { session in
                                    NavigationLink(destination: MapView(
                                        locationsToDisplay: session.locationsArray,
                                        mapTitle: session.name ?? "Session Details"
                                    )) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Image(systemName: SessionType.safeFrom(session.sessionType).iconName)
                                                        .font(.title2)

                                                    Text(session.name ?? "Unbenannte Session")
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                }
                                                if let date = session.startTime {
                                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        } // end ZStack
                                        .frame(height: 80)
                                        .padding(.horizontal)
                                    }
                                    .contextMenu {
                                        Button {
                                            selectedSession = session
                                            showDetailSheet = true
                                        } label: {
                                            Label("Details", systemImage: "square.and.pencil")
                                        }
                                        
                                        Button {
                                            selectedSession = session
                                            editSession = true
                                        } label: {
                                            Label("Bearbeiten", systemImage: "square.and.pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            if let index = sessions.firstIndex(of: session) {
                                                deleteSessions(offsets: IndexSet(integer: index))
                                            }
                                        } label: {
                                            Label("Löschen", systemImage: "trash")
                                        }
                                    }
                                } // end ForEach
                            }
                        }
                        
                        // Einzelorte Überschrift als Button
                        Button(action: {
                            withAnimation { showLocations.toggle() }
                        }) {
                            HStack {
                                Image(systemName: showLocations ? "chevron.down" : "chevron.right")
                                Text("Einzelne Orte")
                                    .font(.title3)
                                    .bold()
                            }
                            .padding(.horizontal)
                            .foregroundColor(.primary)
                        }
                        
                        // Einzelorte Liste
                        if showLocations {
                            ForEach(filteredStandaloneLocations) { location in
                                NavigationLink(destination: MapView(
                                    locationsToDisplay: [location],
                                    mapTitle: location.comment ?? "Gespeicherter Ort"
                                )) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text("Breite: \(location.latitude), Länge: \(location.longitude)")
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            
                                            if location.altitude > 0 {
                                                InfoRow(
                                                    icon: "mountain.2.fill",
                                                    label: "Höhe",
                                                    value: String(format: "%.0f m", location.altitude)
                                                )
                                            }
                                            
                                            if let date = location.timestamp {
                                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            if let comment = location.comment, !comment.isEmpty {
                                                Text("🗒️ \(comment)")
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            if let imageData = location.imageData, let uiImage = UIImage(data: imageData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(height: 150)
                                                    .cornerRadius(8)
                                            }
                                        } // end VStack
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    } // end ZStack
                                    .padding(.horizontal)
                                }
                                .contextMenu {
                                    Button {
                                        selectedLocation = location
                                        showDetailSheet = true
                                    } label: {
                                        Label("Details", systemImage: "info.circle")
                                    }
                                    
                                    Button {
                                        selectedLocation = location
                                        editLocation = true
                                    } label: {
                                        Label("Bearbeiten", systemImage: "square.and.pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        if let index = standaloneLocations.firstIndex(of: location) {
                                            deleteStandaloneLocations(offsets: IndexSet(integer: index))
                                        }
                                    } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                }
                            } // end ForEach
                        } // end If
                    } // end LazyVStack
                    .padding(.vertical)
                }
                .sheet(isPresented: $editSession, onDismiss: {
                    selectedSession = nil
                }) {
                    if let session = selectedSession {
                        SessionEditView(session: session)
                    }
                }
                .sheet(isPresented: $editLocation, onDismiss: {
                    selectedSession = nil
                }) {
                    if let location = selectedLocation {
                        LocationEditView(location: location)
                    }
                }
                .sheet(isPresented: $showDetailSheet, onDismiss: {
                    selectedSession = nil
                    selectedLocation = nil
                }) {
                    if let session = selectedSession {
                        SessionDetailView(session: session)
                    } else if let location = selectedLocation {
                        LocationDetailView(location: location)
                    }
                }
                
            }
            
        }
        .navigationBarHidden(true) // Navigation Title ausblenden
    }

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            offsets.map { sessions[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteStandaloneLocations(offsets: IndexSet) {
        withAnimation {
            offsets.map { standaloneLocations[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private var groupedSessions: [String: [TrackingSession]] {
        Dictionary(grouping: sessions) { session in
            let date = session.startTime ?? Date.distantPast
            let formatter = DateFormatter()
            formatter.dateFormat = "LLLL yyyy" // z. B. „Juni 2025“
            return formatter.string(from: date)
        }
    }
    
    private var filteredGroupedSessions: [String: [TrackingSession]] {
        let calendar = Calendar.current
        return Dictionary(grouping: sessions.filter { session in
            guard let date = session.startTime else { return false }
            return calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
        }) { session in
            let date = session.startTime ?? Date.distantPast
            let formatter = DateFormatter()
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: date)
        }
    }
    
    // Filtered Standalone Locations nach selectedMonth
    private var filteredStandaloneLocations: [SavedLocation] {
        let calendar = Calendar.current
        return standaloneLocations.filter { location in
            guard let date = location.timestamp else { return false }
            return calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month)
        }
    }
}

extension TrackingSession {
    var locationsArray: [SavedLocation] {
        let set = locations as? Set<SavedLocation> ?? []
        return set.sorted { $0.timestamp ?? Date.distantPast < $1.timestamp ?? Date.distantPast }
    }
}
