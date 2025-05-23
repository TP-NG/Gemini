//
//  ControlButtonStyle.swift
//  Tracking
//

import SwiftUI
import CoreData

struct ControlButtonStyle: ViewModifier {
    var color: Color
    var isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isDisabled ? Color.gray.opacity(0.4) : color)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            .buttonStyle(AnimatedButtonStyle())
    }
}

struct AnimatedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
