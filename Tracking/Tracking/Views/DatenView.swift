
//
//  DatenView.swift
//  Tracking
//
//  Created by Administrator on 28.05.25.
//

import SwiftUI

struct DatenView: View {
    let locations: [SavedLocation]
    @State private var selectedImage: UIImage?
    
    @State private var nurMitBildAnzeigen = true
    
    var body: some View {
        NavigationStack {
            
            Toggle("Nur Einträge mit Bild anzeigen", isOn: $nurMitBildAnzeigen)
                .padding()
            
            List {
                ForEach(locations.filter { location in
                    !nurMitBildAnzeigen || (location.imageData != nil && UIImage(data: location.imageData!) != nil)
                }) { location in
                    VStack(alignment: .leading, spacing: 8) {
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
            .navigationTitle("Alle Daten")
            .sheet(item: $selectedImage) { image in
                ImageDetailView(image: image)
            }
        }
    }
}
