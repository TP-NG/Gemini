//
//  YearMonthPickerView.swift
//  Tracking
//

import SwiftUI

struct YearMonthPickerView: View {
    @Binding var selectedDate: Date
    
    @Namespace private var animation
    
    let months: [String] = Calendar.current.shortMonthSymbols
    let columns = [GridItem(.adaptive(minimum: 80))]
    
    // Hilfsfunktion um Jahr aus Date zu extrahieren
    private func yearString(from date: Date) -> String {
        String(Calendar.current.component(.year, from: date))
    }
    
    // Hilfsfunktion um Monatsindex aus Date zu extrahieren
    private func monthIndex(from date: Date) -> Int {
        Calendar.current.component(.month, from: date) - 1
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy" // z. B. „Juni 2025“
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack {
            // Year Picker
            HStack {
                Image(systemName: "chevron.left")
                    .frame(width: 24)
                    .onTapGesture {
                        if let newDate = Calendar.current.date(byAdding: .year, value: -1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }
                
                Text(monthYearString(from: selectedDate))
                    .fontWeight(.bold)
                
                Image(systemName: "chevron.right")
                    .frame(width: 24)
                    .onTapGesture {
                        if let newDate = Calendar.current.date(byAdding: .year, value: 1, to: selectedDate) {
                            selectedDate = newDate
                        }
                    }
            }
            .padding(15)
            
            // Month Picker
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                    ZStack {
                        if index == monthIndex(from: selectedDate) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor)
                                .matchedGeometryEffect(id: "selectedMonth", in: animation)
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentColor.opacity(0.8), lineWidth: 2)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        }

                        Text(month)
                            .font(.headline)
                            .foregroundColor(index == monthIndex(from: selectedDate) ? .white : .primary)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            var components = Calendar.current.dateComponents([.year], from: selectedDate)
                            components.month = index + 1
                            components.day = 1
                            if let newDate = Calendar.current.date(from: components) {
                                selectedDate = newDate
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
