import SwiftUI
import CoreData

struct LocationDetailView: View {
    var location: SavedLocation
    
    @State private var selectedImage: UIImage?
    @State private var showSaveSuccess: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("📍 Ort-Details")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 8)

                GroupBox(label: Label("Zeitstempel", systemImage: "calendar")) {
                    Text(formattedDate(location.timestamp))
                        .font(.body)
                        .foregroundColor(.primary)
                }

                GroupBox(label: Label("Kommentar", systemImage: "text.bubble")) {
                    if let comment = location.comment, !comment.isEmpty {
                        Text(comment)
                            .font(.body)
                            .foregroundColor(.primary)
                    } else {
                        Text("Kein Kommentar")
                            .italic()
                            .foregroundColor(.gray)
                    }
                }

                GroupBox(label: Label("Koordinaten", systemImage: "location")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Breite: \(location.latitude)")
                        Text("Länge: \(location.longitude)")
                    }
                    .font(.body)
                    .foregroundColor(.primary)
                }

                GroupBox(label:
                    HStack {
                        Label("Bild", systemImage: "photo.artframe")
                        Spacer()
                        Button(action: {
                            if let imageData = location.imageData,
                               let uiImage = UIImage(data: imageData) {
                                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                                showSaveSuccess = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderless)
                        .help("Bild speichern")
                    }
                ) {
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
                    } else {
                        Text("Kein Bild vorhanden")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .sheet(item: $selectedImage) { image in
                    ImageDetailView(image: image)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Ort")
        .alert(isPresented: $showSaveSuccess) {
            Alert(
                title: Text("Gespeichert"),
                message: Text("Das Bild wurde erfolgreich in der Mediathek gespeichert."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Unbekannt" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
