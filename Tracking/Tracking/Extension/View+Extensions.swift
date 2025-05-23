//
//  View+Extensions.swift
//  Tracking
//

import SwiftUI

extension View {
    func controlButton(color: Color, isDisabled: Bool) -> some View {
        self.modifier(ControlButtonStyle(color: color, isDisabled: isDisabled))
    }
}

extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
