//
//  LocationEditView.swift
//  Tracking
//

import SwiftUI

struct LocationEditView: View {
    @ObservedObject var location: SavedLocation
    
    @State private var comment: String = ""
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                if let id = location.id {
                    Text("Id: \(id.uuidString)").font(.footnote)
                } else {
                    Text("Keine ID verfügbar").font(.footnote)
                }
            }
            
            Form {
                Section(header: Text("Kommentar")) {
                    TextField("Kommentar", text: $comment)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        location.comment = comment
                        try? context.save()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
            }
        }
        .hideKeyboardOnTap()
    }
    
    init(location: SavedLocation) {
        self.location = location
        _comment = State(initialValue: location.comment ?? "")
    }
    
}
