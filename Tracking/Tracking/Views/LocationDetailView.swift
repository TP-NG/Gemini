//
//  LocationDetailView.swift
//  Tracking
//

import SwiftUI
import CoreData

struct LocationDetailView: View {
    var location: SavedLocation

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ort-Details")
                .font(.largeTitle)
                .bold()

            Text("Erfasst am: \(formattedDate(location.timestamp))")

            if let comment = location.comment, !comment.isEmpty {
                Text("Kommentar: \(comment)")
            } else {
                Text("Kein Kommentar")
                    .italic()
                    .foregroundColor(.gray)
            }

            Text("Koordinaten:")
            Text("Breite: \(location.latitude), Länge: \(location.longitude)")

            Spacer()
        }
        .padding()
        .navigationTitle("Ort")
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unbekannt" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
