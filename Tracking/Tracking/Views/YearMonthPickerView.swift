//
//  YearMonthPickerView.swift
//  Tracking
//

import SwiftUI

struct YearMonthPickerView: View {
    @Binding var selectedDate: Date
    
    @Namespace private var animation
    
    @State private var showMonthGrid = true
    @State private var showYearPicker = false
    
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
    ZStack(alignment: .top) {
        VStack {
            // Year Picker
            HStack(spacing: 8) {
                Button(action: {
                    showYearPicker.toggle()
                }) {
                    HStack(spacing: 4) {
                        Text(monthYearString(from: selectedDate))
                            .fontWeight(.bold)
                        Image(systemName: "calendar")
                    }
                    .contentShape(Rectangle())
                }

                Button(action: {
                    withAnimation(.easeInOut) {
                        showMonthGrid.toggle()
                    }
                }) {
                    Image(systemName: showMonthGrid ? "chevron.up" : "chevron.down")
                        .rotationEffect(.degrees(showMonthGrid ? 0 : 180))
                        .animation(.easeInOut(duration: 0.2), value: showMonthGrid)
                }
            }
            .padding(15)
            
            if showMonthGrid {
                GroupBox(label: Label("Monate", systemImage: "calendar")) {
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
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }

        if showYearPicker {
            VStack(spacing: 0) {
                Picker("Jahr", selection: Binding(
                    get: {
                        Calendar.current.component(.year, from: selectedDate)
                    },
                    set: { newYear in
                        var components = Calendar.current.dateComponents([.month], from: selectedDate)
                        components.year = newYear
                        components.day = 1
                        if let newDate = Calendar.current.date(from: components) {
                            selectedDate = newDate
                        }
                        withAnimation {
                            showYearPicker = false
                        }
                    }
                )) {
                    ForEach(2000...2100, id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .labelsHidden()
                .frame(height: 120)
                .clipped()
                .pickerStyle(.wheel)
                .zIndex(1)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 4)
                )
            }
            .padding(.top, 50)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
}
