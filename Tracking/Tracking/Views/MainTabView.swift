//
//  MainTabView.swift
//  Tracking
//

import SwiftUI
import CoreData // Da SavedLocation ein Core Data Entity ist

struct MainTabView: View {
    @StateObject var locationManager = LiveLocationManager()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedLocation.timestamp, ascending: false)],
        animation: .default
    ) private var gespeicherteOrte: FetchedResults<SavedLocation>
    
    var body: some View {
        TabView {
            LiveLocationView(locationManager: locationManager) // Zeigt die Live-Position an
                .tabItem {
                    Label("Live", systemImage: "location.fill")
                }
            
            SessionListView() // Live-Tracking
                .tabItem {
                    Label("Verlauf", systemImage: "list.bullet")
                }

            // Übergabe der Locations und des Titels an die MapView
            AuswertungView()
                .tabItem {
                    Label("Auswerung", systemImage: "chart.bar")
                }
            
            DatenView(locations: Array(gespeicherteOrte))
                .tabItem {
                    Label("Rawdaten", systemImage: "square.stack.3d.down.forward")
                }
        }
    }
}
