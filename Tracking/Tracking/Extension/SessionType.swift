//
//  SessionType.swift
//  Tracking
//

import Foundation

enum SessionType: String, CaseIterable, Identifiable {
    case gehen = "Gehen"
    case motorisiert = "Motorisiert"
    
    var id: String { rawValue }
}

extension SessionType {
    var iconName: String {
        switch self {
        case .gehen: return "figure.walk"
        case .motorisiert: return "car.fill"
        }
    }
}

