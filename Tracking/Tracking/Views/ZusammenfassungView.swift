//
//  ZusammenfassungView.swift
//  Tracking
//
//  Created by Administrator on 25.05.25.
//

import SwiftUI
import Charts
import CoreData

// Metriken vor der Anzeige aktualisieren
struct ZusammenfassungView: View {
    let sessions: [TrackingSession]
    
    // Berechnete Werte
    private var totalDistance: Double {
        sessions.reduce(0) { $0 + $1.totalDistance }
    }
    
    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.totalDuration }
    }
    
    // Korrekte Durchschnittsgeschwindigkeit (Gesamtstrecke / Gesamtzeit)
    private var averageSpeed: Double {
        guard totalDuration > 0 else { return 0 }
        return totalDistance / totalDuration
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Zusammenfassung")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Route Details")
                        .font(.title2.bold())
                        .padding(.bottom, 5)
                    
                    InfoRow(
                        icon: "point.topleft.down.curvedto.point.bottomright.up",
                        label: "Streckenlänge",
                        value: totalDistance != nil ? String(format: "%.2f km", totalDistance / 1000) : "–"
                    )
                    
                    InfoRow(
                        icon: "stopwatch",
                        label: "Dauer",
                        value: totalDuration != nil ? formattedDuration(totalDuration) : "–"
                    )
                    
                    
                    InfoRow(
                        icon: "speedometer",
                        label: "Ø Geschwindigkeit",
                        value: formattedSpeed
                    )
                }
                
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Formatierung
    private var formattedDistance: String {
        if totalDistance < 1000 {
            return "\(Int(totalDistance)) m"
        } else {
            return String(format: "%.1f km", totalDistance / 1000)
        }
    }
    
    
    private func formattedDuration(_ duration: TimeInterval) -> String {
        print(duration)
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    private var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        
        if totalDuration >= 3600 {
            // Format: 1h 5m 30s
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .abbreviated
        } else {
            // Format: 1m 10s
            formatter.allowedUnits = [.minute, .second]
            formatter.unitsStyle = .short
        }
        
        print("""
        Test-Ergebnisse:
        - Berechnete Distanz: \(totalDistance)m
        - Erwartete Duration: \(totalDuration)m
        """)
        
        // Spezialfall: Weniger als 1 Minute
        if totalDuration < 60 {
            return "\(Int(totalDuration))s"
        }
        let tmp = String(format: "%.1f km/h", totalDuration * 3.6)
        print(tmp)
        
        return formatter.string(from: totalDuration) ?? "0s"
    }
    
    private var formattedSpeed: String {
        String(format: "%.1f km/h", averageSpeed * 3.6)
    }
}
