//
//  LocationProgressView.swift
//  Tracking
//
//  Created by Administrator on 25.05.25.
//

import SwiftUI
import CoreData

struct LocationProgressView: View {
    var current: Double
    var total: Double
    
    var body: some View {
        VStack {
            ProgressView(value: current, total: total)
                .progressViewStyle(.linear)
                .accentColor(.orange)
                .padding(.horizontal)
            
            Text("Nächste Speicherung in \(Int(total - current)) Sekunden")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
}
