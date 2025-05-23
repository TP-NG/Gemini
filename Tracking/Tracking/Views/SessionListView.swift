//
//  SessionListView.swift
//  Tracking
//

import SwiftUI
import CoreData

struct SessionListView: View {
    @Environment(\.managedObjectContext) private var viewContext

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
                            Text(session.name ?? "Unbenannte Session")
                        }
                    }
                    .onDelete(perform: deleteSessions) // Swipe zum Löschen für Sessions
                }

                Section("Einzelne Orte") {
                    ForEach(standaloneLocations) { location in
                        NavigationLink(destination: MapView(
                            locationsToDisplay: [location],
                            mapTitle: "Gespeicherter Ort"
                        )) {
                            VStack(alignment: .leading) {
                                Text("Breite: \(location.latitude), Länge: \(location.longitude)")
                                    .font(.body)
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
                        }
                    }
                    .onDelete(perform: deleteStandaloneLocations) // Swipe zum Löschen für einzelne Orte
                }
            }
            .navigationTitle("Gespeicherte Orte & Routen")
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
