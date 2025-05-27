//
//  ImageLoader.swift
//  Tracking
import Foundation // <-- Diesen Import hinzufügen
import UIKit

struct ImageLoader {
    static func loadImage(from data: Data) async -> UIImage? {
        // 1. Datenvalidierung
        guard !data.isEmpty else {
            print("‼️ Kritischer Fehler: Leere Bilddaten")
            return nil
        }
        
        // 2. Dekodierung im Hintergrund
        return await Task.detached {
            // Sofortige Größenprüfung
            if data.count > 5_000_000 { // >5MB
                print("⚠️ Warnung: Sehr große Bilddaten (\(data.count) bytes)")
            }
            
            guard let image = UIImage(data: data) else {
                print("‼️ Dekodierungsfehler")
                return nil
            }
            
            // Automatische Skalierung
            let maxDimension: CGFloat = 2000
            let scaleRatio = min(maxDimension / image.size.width,
                               maxDimension / image.size.height)
            let newSize = CGSize(
                width: image.size.width * scaleRatio,
                height: image.size.height * scaleRatio
            )
            
            print("🖼️ Erstelle Bild \(newSize)")
            return UIGraphicsImageRenderer(size: newSize).image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }.value
    }
}
