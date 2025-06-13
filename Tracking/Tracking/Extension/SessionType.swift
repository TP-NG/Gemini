//
//  SessionType.swift
//  Tracking
//

import Foundation

enum SessionType: String, CaseIterable, Identifiable {
    case gehen = "Gehen"
    case laufen = "Laufen"
    case bahn = "Bahn"
    case bus = "Bus"
    case fahrad = "Fahrad"
    case fliegen = "Fliegen"
    case auto = "Auto"
    case unknown = "Unknown" // Neuer Fall für undefinierte Werte
    
    var id: String { rawValue }
    
    static func safeFrom(_ string: String?) -> SessionType {
        guard let string = string else { return .unknown }
        return SessionType(rawValue: string) ?? .unknown
    }
    
}

extension SessionType {
    var iconName: String {
        switch self {
        case .gehen: return "figure.walk"
        case .laufen: return "figure.run"
        case .bahn: return "tram.fill"
        case .bus: return "bus.fill"
        case .auto: return "car.fill"
        case .fahrad: return "bicycle"
        case .fliegen: return "airplane"
        case .unknown: return "questionmark" // Icon für unbekannte Werte
        }
    }
}

