//
//  SessionDetailView.swift
//  Tracking
//

import SwiftUI
import CoreData

struct SessionDetailView: View {
    var session: TrackingSession

    var imageCount: Int {
        guard let locations = session.locations else { return 0 }

        let savedLocations = locations.compactMap { $0 as? SavedLocation }

        let count = savedLocations.filter { $0.imageData != nil }.count

        return count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Session Details")
                .font(.largeTitle)
                .bold()

            Text("Start: \(formattedDate(session.startTime))")
            Text("Ende: \(formattedDate(session.endTime))")

            Text("Distanz: \(String(format: "%.2f", session.totalDistance)) km")
            Text("Anzahl der Punkte: \(session.locations?.count ?? 0)")
            Text("Anzahl der Bilder: \(imageCount)")

            Spacer()
        }
        .padding()
        .navigationTitle("Session")
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unbekannt" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
