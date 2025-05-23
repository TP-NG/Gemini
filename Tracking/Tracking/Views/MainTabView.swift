//
//  MainTabView.swift
//  Tracking
//
//  Created by Administrator on 22.05.25.
//

import SwiftUI
import CoreData // Da SavedLocation ein Core Data Entity ist

struct MainTabView: View {
    // Angenommen, du hast eine Möglichkeit, diese Locations zu beziehen.
    // Das könnte ein @FetchRequest sein oder eine übergebene Variable.
    // Hier verwenden wir ein einfaches @State für Demonstrationszwecke.
    @State private var sampleLocations: [SavedLocation] = [
        // Hier erstellst du Beispieldaten vom Typ SavedLocation.
        // Da SavedLocation ein Core Data Managed Object ist,
        // müsstest du diese normalerweise aus deinem Managed Object Context holen.
        // Für dieses Beispiel erstellen wir "Dummy"-Daten.

        // *** WICHTIG: Ersetze das hier durch das tatsächliche Erzeugen von SavedLocation Objekten! ***
        // Beispiel (funktioniert so nicht direkt, da Managed Objects spezielle Initialisierung brauchen):
        // SavedLocation(context: PersistenceController.shared.container.viewContext).with { $0.latitude = 52.52; $0.longitude = 13.40; $0.timestamp = Date() },
        // SavedLocation(context: PersistenceController.shared.container.viewContext).with { $0.latitude = 52.53; $0.longitude = 13.41; $0.timestamp = Date() }
    ]

    @State private var mapTitleString: String = "Meine Orte"

    var body: some View {
        TabView {
            LiveLocationView() // Zeigt die Live-Position an
                .tabItem {
                    Label("Live", systemImage: "location.fill")
                }
            
            SessionListView() // Live-Tracking
                .tabItem {
                    Label("Verlauf", systemImage: "list.bullet")
                }

            // Übergabe der Locations und des Titels an die MapView
            MapView(locationsToDisplay: sampleLocations, mapTitle: mapTitleString)
                .tabItem {
                    Label("Karte", systemImage: "map")
                }
        }
        .onAppear {
            // *** Nur für Demonstrationszwecke: Erstelle hier temporäre SavedLocation Objekte ***
            let context = PersistenceController.shared.container.viewContext
            let location1 = SavedLocation(context: context)
            location1.latitude = 52.52
            location1.longitude = 13.40
            location1.timestamp = Date()

            let location2 = SavedLocation(context: context)
            location2.latitude = 52.53
            location2.longitude = 13.41
            location2.timestamp = Date()

            sampleLocations = [location1, location2]

            // Optional: Ändere den Kartentitel dynamisch
            mapTitleString = "Beispiel-Session"
        }
    }
}
