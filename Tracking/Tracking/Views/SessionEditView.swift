//
//  SessionEditView.swift
//  Tracking
//

import SwiftUI

struct SessionEditView: View {
    
    @ObservedObject var session: TrackingSession
    
    @State private var name: String = ""
    @State private var comment: String = ""
    @State private var selectedSessionType: SessionType
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                if let id = session.id {
                    Text("Id: \(id.uuidString)").font(.footnote)
                } else {
                    Text("Keine ID verfügbar").font(.footnote)
                }
                
                if let name = session.name, !name.isEmpty {
                    Text("Name: \(name)")
                        .font(.body)
                } else {
                    Text("Keine Name verfügbar").font(.footnote)
                }
                
                if let comment = session.comment, !comment.isEmpty {
                    Text("Kommentar: \(comment)")
                        .font(.body)
                } else {
                    Text("Keine Komentar verfügbar").font(.footnote)
                }
                
                if let sessionType = session.sessionType, !sessionType.isEmpty {
                    Text("Aktivitätstyp: \(sessionType)")
                        .font(.body)
                } else {
                    Text("Keine Aktivitätstyp verfügbar").font(.footnote)
                }
            }
            
            Form {
                Section(header: Text("Name")) {
                    TextField("Name", text: $name)
                }
                Section(header: Text("Kommentar")) {
                    TextField("Kommentar", text: $comment)
                }
                Section(header: Text("Aktivitätstyp")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(SessionType.allCases) { type in
                                Button(action: {
                                    selectedSessionType = type
                                }) {
                                    VStack {
                                        Image(systemName: type.iconName)
                                            .font(.title2)
                                        //Text(type.rawValue)
                                        //    .font(.subheadline)
                                    }
                                    .padding()
                                    .frame(width: 80, height: 80) // feste Breite sorgt für bessere Scrollbarkeit
                                    .background(selectedSessionType == type ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedSessionType == type ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    } // end ScrollView
                    
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        session.name = name
                        session.comment = comment
                        session.sessionType = selectedSessionType.rawValue
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
    
    init(session: TrackingSession) {
        self.session = session
        _name = State(initialValue: session.name ?? "")
        _comment = State(initialValue: session.comment ?? "")
        _selectedSessionType = State(initialValue: SessionType(rawValue: session.sessionType ?? "") ?? .gehen)
    }
    
    
}
