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
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\TrackingSession.startTime, order: .reverse)])
    private var sessions: FetchedResults<TrackingSession>

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\SavedLocation.timestamp, order: .reverse)],
        predicate: NSPredicate(format: "isStandalone == true")
    )
    private var standaloneLocations: FetchedResults<SavedLocation>

    var body: some View {
        NavigationView {
            List {
                Section("Sessions") {
                    ForEach(sessions) { session in
                        NavigationLink(destination: MapView(
                            locationsToDisplay: session.locationsArray,
                            mapTitle: session.name ?? "Session Details"
                        )) {
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.name ?? "Unbenannte Session")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    if let date = session.startTime {
                                        Text(date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                // NavigationLink transparent über den ganzen Bereich legen
                                NavigationLink("", destination: MapView(
                                    locationsToDisplay: session.locationsArray,
                                    mapTitle: session.name ?? "Session Details"
                                ))
                                .opacity(0) // unsichtbar, aber klickbar
                            }
                            .frame(height: 80)
                            .padding(.horizonta
                            
                        }
                        .frame(maxWidth: .infinity)
                        .swipeActions(edge: .trailing) {
                          
                            Button {
                                selectedSession = session
                                showDetailSheet = true
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }
                            .tint(.blue)
                                
                                Button(role: .destructive) {
                                    // Löschen der Einträge über deleteSessions
                                    if let index = sessions.firstIndex(of: session) {
                                        deleteSessions(offsets: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        
                    }
                    .onDelete(perform: deleteSessions) // Swipe zum Löschen für Sessions
                }

                Section("Einzelne Orte") {
                    ForEach(standaloneLocations) { location in
                        NavigationLink(destination: MapView(
                            locationsToDisplay: [location],
                            mapTitle: location.comment ?? "Gespeicherter Ort"
                        )) {
                            VStack(alignment: .leading) {
                                Text("Breite: \(location.latitude), Länge: \(location.longitude)")
                                    .font(.body)
                                
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
                                        .foregroundColor(.gray)
                                }
                                
                                if let comment = location.comment, !comment.isEmpty {
                                    Text("🗒️ \(comment)")
                                        .font(.subheadline)
                                }
                                
                                if let imageData = location.imageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 150)
                                        .cornerRadius(8)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        .swipeActions(edge: .trailing) {
                            
                            Button {
                                selectedLocation = location
                                showDetailSheet = true
                            } label: {
                                Label("Details", systemImage: "info.circle")
                            }
                            .tint(.blue)
                                
                                Button(role: .destructive) {
                                    if let index = standaloneLocations.firstIndex(of: location) {
                                        deleteStandaloneLocations(offsets: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                        
                    }
                    .onDelete(perform: deleteStandaloneLocations) // Swipe zum Löschen für einzelne Orte
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
            //.navigationTitle("Gespeicherte Orte & Routen")
        }
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
}

extension TrackingSession {
    var locationsArray: [SavedLocation] {
        let set = locations as? Set<SavedLocation> ?? []
        return set.sorted { $0.timestamp ?? Date.distantPast < $1.timestamp ?? Date.distantPast }
    }
}
