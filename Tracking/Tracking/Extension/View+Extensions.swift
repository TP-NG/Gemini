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


// UIImage-Extension für Skalierung (am Dateiende hinzufügen)
extension UIImage {
    func scaled(to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
