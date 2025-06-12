//
//  YearMonthPickerView.swift
//  Tracking
//

import SwiftUI

struct YearMonthPickerView: View {
    @Binding var selectedDate: Date
    
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
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                    Text(month)
                        .font(.headline)
                        .frame(width: 60, height: 33)
                        .bold()
                        .background(
                            index == monthIndex(from: selectedDate)
                                ? Color("AppColor")
                                : Color("buttonBackground")
                        )
                        .cornerRadius(8)
                        .onTapGesture {
                            var components = Calendar.current.dateComponents([.year, .day], from: selectedDate)
                            components.month = index + 1
                            if let newDate = Calendar.current.date(from: components) {
                                selectedDate = newDate
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}
