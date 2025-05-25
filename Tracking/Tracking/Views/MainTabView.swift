//
//  MainTabView.swift
//  Tracking
//
//  Created by Administrator on 22.05.25.
//

import SwiftUI
import CoreData // Da SavedLocation ein Core Data Entity ist

struct MainTabView: View {

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
            AuswertungView()
                .tabItem {
                    Label("Auswerung", systemImage: "chart.bar")
                }
        }
    }
}
