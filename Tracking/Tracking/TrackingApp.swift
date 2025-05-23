//
//  TrackingApp.swift
//  Tracking
//
//  Created by Administrator on 22.05.25.
//

import SwiftUI

@main
struct TrackingApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
