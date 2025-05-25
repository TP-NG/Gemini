//
//  VerlaufDiagrammView.swift
//  Tracking
//
//  Created by Administrator on 25.05.25.
//

import SwiftUI
import Charts
import CoreData

struct VerlaufDiagrammView: View {
    let sessions: [TrackingSession]
    
    var body: some View {
        Chart {
            ForEach(sessions) { session in
                if let start = session.startTime, session.totalDistance > 0 {
                    BarMark(
                        x: .value("Datum", start, unit: .day),
                        y: .value("Distanz", session.totalDistance / 1000)
                    )
                    .foregroundStyle(by: .value("Session", session.name ?? "Unbenannt"))
                    .annotation(position: .top) {
                        Text("\(session.totalDistance/1000, specifier: "%.1f")km")
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
        .frame(height: 300)
        .padding()
    }
}
