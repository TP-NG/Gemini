//
//  DatenView.swift
//  Tracking
//


import SwiftUI

struct DatenView: View {
    let locations: [SavedLocation]
    @State private var selectedImage: UIImage?
    
    @State private var nurMitBildAnzeigen = true
    
    @State private var currentPage = 0
    private let itemsPerPage = 20
    
    @State private var feldName: String = "sessionType"
    @State private var newValue: String = "Gehen"
    @State private var whereValue: String = "Hangelar Ost"
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackingSession.startTime, ascending: false)],
        animation: .default
    ) private var sessions: FetchedResults<TrackingSession>
    
    var body: some View {
        NavigationStack {
            
            Toggle("Nur Einträge mit Bild anzeigen", isOn: $nurMitBildAnzeigen)
                .padding()
            
            DisclosureGroup {
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "key.fill")
                        TextField("Feldname", text: $feldName)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Image(systemName: "pencil")
                        TextField("Neuer Wert", text: $newValue)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        TextField("Where-Bedingung", text: $whereValue)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button {
                        aktualisiereAlleDaten()
                    } label: {
                        Label("Aktualisieren", systemImage: "arrow.triangle.2.circlepath.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 6)
                }
                .padding()
            } label: {
                Label("Datensatz aktualisieren", systemImage: "square.and.pencil")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            let filteredLocations = locations.filter { location in
                !nurMitBildAnzeigen || (location.imageData != nil && UIImage(data: location.imageData!) != nil)
            }
            
            let pagedLocations = Array(filteredLocations.dropFirst(currentPage * itemsPerPage).prefix(itemsPerPage))
            
            List {
                ForEach(sessions) { session in
                    Section(header: Text(session.name ?? "Unbenannte Session")) {
                        if let id = session.id {
                            Text(id.uuidString).font(.footnote)
                        } else {
                            Text("Keine ID verfügbar").font(.footnote)
                        }
                        
                        let zugeordneteOrte = pagedLocations.filter { $0.session == session }
                        ForEach(zugeordneteOrte) { location in
                            VStack(alignment: .leading, spacing: 8) {
                                if let id = location.id {
                                    Text(id.uuidString).font(.footnote)
                                } else {
                                    Text("Keine ID verfügbar").font(.footnote)
                                }
                                Text(location.timestamp?.formatted() ?? "Unbekanntes Datum")
                                    .font(.headline)
                                Text(String(format: "%.6f, %.6f", location.latitude, location.longitude))
                                    .font(.subheadline)

                                if let comment = location.comment, !comment.isEmpty {
                                    Text("Kommentar: \(comment)")
                                        .font(.body)
                                }

                                if let imageData = location.imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxHeight: 150)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            selectedImage = uiImage
                                        }
                                    Button("Bild speichern") {
                                        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                    }
                                    .font(.caption)
                                } else {
                                    Text("Kein Bild vorhanden")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            HStack {
                Button("Zurück") {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                }
                .disabled(currentPage == 0)

                Spacer()

                Button("Weiter") {
                    if (currentPage + 1) * itemsPerPage < filteredLocations.count {
                        currentPage += 1
                    }
                }
                .disabled((currentPage + 1) * itemsPerPage >= filteredLocations.count)
            }
            .padding()
            .navigationTitle("Alle Daten")
            .sheet(item: $selectedImage) { image in
                ImageDetailView(image: image)
            }
        }
        .hideKeyboardOnTap()
    }
    
    func aktualisiereAlleDaten() {
        let context = PersistenceController.shared.container.viewContext
        for session in sessions where session.name?.trimmingCharacters(in: .whitespacesAndNewlines) == whereValue {
            switch feldName {
            case "comment":
                session.comment = newValue
            case "sessionType":
                session.sessionType = newValue
            default:
                continue
            }
        }
        do {
            try context.save()
            print("Daten erfolgreich gespeichert.")
        } catch {
            print("Fehler beim Speichern: \(error.localizedDescription)")
        }
    }
}
