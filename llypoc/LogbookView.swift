//
//  LogbookView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI
import SwiftData

struct LogbookView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var patients: [Patient]
    @Query private var insulinDoses: [InsulinDose]
    @Query private var bgReadings: [BloodGlucoseReading]
    
    @State private var selectedFilter: LogbookFilter = .all
    @State private var searchText = ""
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showFilterSheet = false
    @State private var selectedItem: LogbookItem?
    @State private var showDetailView = false
    @State private var showEditSheet = false
    @State private var itemToEdit: LogbookItem?
    @State private var showLogBGFlow = false
    @State private var showLogInsulinFlow = false
    
    // MARK: - Quick Action Test Scenarios
    enum QuickActionTestScenario: String, CaseIterable {
        case weeklyDose = "Weekly Dose"
        case startingDose = "Starting Dose"
        
        var description: String {
            switch self {
            case .weeklyDose:
                return "Test weekly dose injection flow"
            case .startingDose:
                return "Test starting dose injection flow"
            }
        }
        
        var icon: String {
            switch self {
            case .weeklyDose:
                return "calendar.circle.fill"
            case .startingDose:
                return "play.circle.fill"
            }
        }
    }
    
    enum LogbookFilter: String, CaseIterable {
        case all = "All"
        case bgReadings = "Blood Glucose"
        case insulinDoses = "Insulin Doses"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .bgReadings: return "drop.fill"
            case .insulinDoses: return "syringe.fill"
            }
        }
    }
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
        case all = "All Time"
        
        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            case .all: return nil
            }
        }
    }
    
    private var currentPatient: Patient? {
        patients.first
    }
    
    private var filteredItems: [LogbookItem] {
        let patientId = currentPatient?.id
        
        let startDate: Date?
        if let days = selectedTimeRange.days {
            startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
        } else {
            startDate = nil
        }
        
        var items: [LogbookItem] = []
        
        // Add BG readings
        if selectedFilter == .all || selectedFilter == .bgReadings {
            let filteredReadings = bgReadings.filter { reading in
                reading.patientId == patientId &&
                (startDate == nil || reading.dateTime >= startDate!) &&
                (searchText.isEmpty || String(Int(reading.reading)).contains(searchText))
            }
            
            items.append(contentsOf: filteredReadings.map { LogbookItem.bgReading($0) })
        }
        
        // Add insulin doses
        if selectedFilter == .all || selectedFilter == .insulinDoses {
            let filteredDoses = insulinDoses.filter { dose in
                dose.patientId == patientId &&
                (startDate == nil || dose.dateTime >= startDate!) &&
                (searchText.isEmpty || String(Int(dose.doseAmount)).contains(searchText))
            }
            
            items.append(contentsOf: filteredDoses.map { LogbookItem.insulinDose($0) })
        }
        
        if items.isEmpty {
            items = generateMockData()
        }
        
        // Sort by date
        return items.sorted { $0.date > $1.date }
    }
    
    private func generateMockData() -> [LogbookItem] {
        let mockPatientId = UUID()

        let startDate: Date?
        if let days = selectedTimeRange.days {
            startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())
        } else {
            startDate = nil
        }
        
        // Generate mock BG readings for the past week
        let bgReadings = [
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 125.0,
                readingType: .fasting,
                dateTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                notes: "Before breakfast"
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 142.0,
                readingType: .afterBreakfast,
                dateTime: Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 118.0,
                readingType: .fasting,
                dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 135.0,
                readingType: .afterLunch,
                dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                notes: "Feeling a bit tired"
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 128.0,
                readingType: .fasting,
                dateTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 155.0,
                readingType: .afterDinner,
                dateTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                notes: "Had dessert"
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 122.0,
                readingType: .fasting,
                dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 138.0,
                readingType: .beforeLunch,
                dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 115.0,
                readingType: .fasting,
                dateTime: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 148.0,
                readingType: .afterBreakfast,
                dateTime: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
                notes: "Stressful morning"
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 65.0,
                readingType: .fasting,
                dateTime: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                notes: "Low blood sugar - had juice"
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 45.0,
                readingType: .beforeLunch,
                dateTime: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date(),
                notes: "Severe hypo - emergency treatment"
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 58.0,
                readingType: .afterDinner,
                dateTime: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                notes: "Mild hypo - ate candy"
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 132.0,
                readingType: .fasting,
                dateTime: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 145.0,
                readingType: .afterDinner,
                dateTime: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 119.0,
                readingType: .fasting,
                dateTime: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
            ),
            BloodGlucoseReading(
                patientId: mockPatientId,
                reading: 156.0,
                readingType: .afterLunch,
                dateTime: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date(),
                notes: "Large meal"
            )
        ]
        
        // Generate mock insulin doses
        let insulinDoses = [
            InsulinDose(
                patientId: mockPatientId,
                doseAmount: 300.0,
                doseType: .weekly,
                dateTime: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                notes: "Weekly maintenance dose"
            ),
            InsulinDose(
                patientId: mockPatientId,
                doseAmount: 300.0,
                doseType: .weekly,
                dateTime: Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date()
            ),
            InsulinDose(
                patientId: mockPatientId,
                doseAmount: 350.0,
                doseType: .correction,
                dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                notes: "High BG correction"
            ),
            InsulinDose(
                patientId: mockPatientId,
                doseAmount: 300.0,
                doseType: .weekly,
                dateTime: Calendar.current.date(byAdding: .day, value: -19, to: Date()) ?? Date()
            ),
            InsulinDose(
                patientId: mockPatientId,
                doseAmount: 325.0,
                doseType: .correction,
                dateTime: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date(),
                notes: "Slight adjustment"
            )
        ]
        
        var mockItems: [LogbookItem] = []
        
        // Add BG readings based on filter
        if selectedFilter == .all || selectedFilter == .bgReadings {
            let filteredReadings = bgReadings.filter { reading in
                (startDate == nil || reading.dateTime >= startDate!) &&
                (searchText.isEmpty || String(Int(reading.reading)).contains(searchText))
            }
            mockItems.append(contentsOf: filteredReadings.map { LogbookItem.bgReading($0) })
        }
        
        // Add insulin doses based on filter
        if selectedFilter == .all || selectedFilter == .insulinDoses {
            let filteredDoses = insulinDoses.filter { dose in
                (startDate == nil || dose.dateTime >= startDate!) &&
                (searchText.isEmpty || String(Int(dose.doseAmount)).contains(searchText))
            }
            mockItems.append(contentsOf: filteredDoses.map { LogbookItem.insulinDose($0) })
        }
        
        return mockItems
    }
    
    private var groupedItems: [String: [LogbookItem]] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return Dictionary(grouping: filteredItems) { item in
            formatter.string(from: item.date)
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search and filter
                    VStack(spacing: 16) {
                        // Filter and time range
                        HStack {
                            // Filter button
                            Button(action: {
                                showFilterSheet = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: selectedFilter.icon)
                                        .font(.system(size: 14))
                                    
                                    Text(selectedFilter.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(themeManager.colors.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(themeManager.colors.surface)
                                )
                            }
                            
                            Spacer()
                            
                            // Time range picker
                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(themeManager.colors.text)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    // Content
                    if filteredItems.isEmpty {
                        EmptyStateView(
                            filter: selectedFilter,
                            searchText: searchText,
                            colors: themeManager.colors
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                ForEach(Array(groupedItems.keys.sorted(by: {
                                    let formatter = DateFormatter()
                                    formatter.dateStyle = .medium
                                    return formatter.date(from: $0) ?? Date() > formatter.date(from: $1) ?? Date()
                                })), id: \.self) { dateKey in
                                    VStack(alignment: .leading, spacing: 12) {
                                        // Date header
                                        Text(dateKey)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(themeManager.colors.text)
                                            .padding(.horizontal, 20)
                                        
                                        // Items for this date
                                        VStack(spacing: 8) {
                                            ForEach(groupedItems[dateKey] ?? [], id: \.id) { item in
                                                LogbookItemRow(
                                                    item: item,
                                                    colors: themeManager.colors
                                                ) {
                                                    selectedItem = item
                                                    showDetailView = true
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationTitle("Logbook")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(themeManager.colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView(
                selectedFilter: $selectedFilter,
                selectedTimeRange: $selectedTimeRange,
                colors: themeManager.colors
            )
        }
        .sheet(isPresented: $showDetailView) {
            if let item = selectedItem {
                LogbookDetailView(
                    item: item,
                    colors: themeManager.colors,
                    onEdit: {
                        switch item {
                        case .bgReading:
                            showLogBGFlow = true
                            showDetailView = false
                        case .insulinDose:
                            showLogInsulinFlow = true
                            showDetailView = false
                        }
                    },
                    onDelete: {
                        showDetailView = false
                    }
                )
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let item = itemToEdit {
                LogbookEditView(
                    item: item,
                    colors: themeManager.colors,
                    onSave: { updatedItem in
                        switch updatedItem {
                        case .bgReading(let reading):
                            if let existingReading = bgReadings.first(where: { $0.id == reading.id }) {
                                existingReading.reading = reading.reading
                                existingReading.readingType = reading.readingType
                                existingReading.dateTime = reading.dateTime
                                existingReading.notes = reading.notes
                            }
                        case .insulinDose(let dose):
                            if let existingDose = insulinDoses.first(where: { $0.id == dose.id }) {
                                existingDose.doseAmount = dose.doseAmount
                                existingDose.doseType = dose.doseType
                                existingDose.dateTime = dose.dateTime
                                existingDose.notes = dose.notes
                            }
                        }
                        
                        // Save changes
                        try? modelContext.save()
                        showEditSheet = false
                    },
                    onCancel: {
                        showEditSheet = false
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showLogBGFlow) {
            LogBGFlowView()
        }
        .fullScreenCover(isPresented: $showLogInsulinFlow) {
            LogInsulinFlowView(
                bypassStarterDoseQuestion: true,
                isFromOnboarding: false,
                testScenario: .weeklyDose
            )
        }
    }
}

// MARK: - Logbook Item
enum LogbookItem: Identifiable {
    case bgReading(BloodGlucoseReading)
    case insulinDose(InsulinDose)
    
    var id: String {
        switch self {
        case .bgReading(let reading):
            return "bg_\(reading.id.uuidString)"
        case .insulinDose(let dose):
            return "dose_\(dose.id.uuidString)"
        }
    }
    
    var date: Date {
        switch self {
        case .bgReading(let reading):
            return reading.dateTime
        case .insulinDose(let dose):
            return dose.dateTime
        }
    }
    
    var title: String {
        switch self {
        case .bgReading(let reading):
            return "\(Int(reading.reading)) mg/dL"
        case .insulinDose(let dose):
            return "\(Int(dose.doseAmount)) units"
        }
    }
    
    var subtitle: String {
        switch self {
        case .bgReading(let reading):
            return reading.readingType.rawValue
        case .insulinDose(let dose):
            return dose.doseType.rawValue
        }
    }
    
    var icon: String {
        switch self {
        case .bgReading:
            return "drop.fill"
        case .insulinDose:
            return "syringe.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .bgReading(let reading):
            if reading.reading < 70 {
                return .red // Hypo readings
            } else if reading.reading > 180 {
                return .orange // Hyper readings
            } else {
                return .blue // Normal readings
            }
        case .insulinDose:
            return .green
        }
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Logbook Item Row
struct LogbookItemRow: View {
    let item: LogbookItem
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(item.iconColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .fill(item.iconColor)
                        .frame(width: 16, height: 16)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.text)
                        
                        Spacer()
                        
                        // Time badge
                        Text(item.timeString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colors.textSecondary.opacity(0.1))
                            )
                    }
                    
                    Text(item.subtitle)
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colors.surface)
                    .shadow(color: colors.shadow.opacity(0.1), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colors.border.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let filter: LogbookView.LogbookFilter
    let searchText: String
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: filter.icon)
                .font(.system(size: 60))
                .foregroundColor(colors.textSecondary)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }
        
        switch filter {
        case .all:
            return "No Data Yet"
        case .bgReadings:
            return "No Blood Glucose Readings"
        case .insulinDoses:
            return "No Insulin Doses"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or filters to find what you're looking for."
        }
        
        switch filter {
        case .all:
            return "Start logging your blood glucose readings and insulin doses to see your history here."
        case .bgReadings:
            return "Log your first blood glucose reading to start tracking your progress."
        case .insulinDoses:
            return "Log your first insulin dose to start tracking your treatment."
        }
    }
}

// MARK: - Filter Sheet View
struct FilterSheetView: View {
    @Binding var selectedFilter: LogbookView.LogbookFilter
    @Binding var selectedTimeRange: LogbookView.TimeRange
    let colors: AppColors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Filter options
                        VStack(spacing: 16) {
                            Text("Filter by Type")
                                .font(.headline)
                                .foregroundColor(colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(LogbookView.LogbookFilter.allCases, id: \.self) { filter in
                                FilterOptionRow(
                                    title: filter.rawValue,
                                    icon: filter.icon,
                                    isSelected: selectedFilter == filter,
                                    colors: colors
                                ) {
                                    selectedFilter = filter
                                }
                            }
                        }
                        
                        Divider()
                            .background(colors.border)
                        
                        // Time range options
                        VStack(spacing: 16) {
                            Text("Time Range")
                                .font(.headline)
                                .foregroundColor(colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(LogbookView.TimeRange.allCases, id: \.self) { range in
                                FilterOptionRow(
                                    title: range.rawValue,
                                    icon: "calendar",
                                    isSelected: selectedTimeRange == range,
                                    colors: colors
                                ) {
                                    selectedTimeRange = range
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Filter Option Row
struct FilterOptionRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? colors.primary : colors.textSecondary)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(colors.text)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colors.primary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? colors.primary.opacity(0.1) : colors.surface)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Logbook Detail View
struct LogbookDetailView: View {
    let item: LogbookItem
    let colors: AppColors
    let onEdit: () -> Void
    let onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: item.icon)
                                .font(.system(size: 60))
                                .foregroundColor(item.iconColor)
                            
                            Text(item.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(colors.text)
                            
                            Text(item.subtitle)
                                .font(.headline)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        // Details
                        VStack(spacing: 16) {
                            DetailRow(
                                title: "Date & Time",
                                value: formatDateTime(item.date),
                                icon: "calendar",
                                colors: colors
                            )
                            
                            switch item {
                            case .bgReading(let reading):
                                DetailRow(
                                    title: "Reading Value",
                                    value: "\(Int(reading.reading)) mg/dL",
                                    icon: "drop.fill",
                                    colors: colors
                                )
                                
                                DetailRow(
                                    title: "Reading Type",
                                    value: reading.readingType.rawValue,
                                    icon: "clock.fill",
                                    colors: colors
                                )
                                

                                
                            case .insulinDose(let dose):
                                DetailRow(
                                    title: "Dose Amount",
                                    value: "\(Int(dose.doseAmount)) units",
                                    icon: "syringe.fill",
                                    colors: colors
                                )
                                

                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors.surface)
                                .shadow(color: colors.shadow, radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        // Bottom Action Buttons
                        VStack(spacing: 16) {
                            Button(action: onEdit) {
                                HStack {
                                    Image(systemName: "pencil")
                                        .font(.headline)
                                    Text("Edit")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colors.primary)
                                )
                            }
                            
                            Button(action: onDelete) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.headline)
                                    Text("Delete")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    

    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(colors.textSecondary)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(colors.text)
            }
            
            Spacer()
        }
    }
}

// MARK: - Logbook Edit View
struct LogbookEditView: View {
    let item: LogbookItem
    let colors: AppColors
    let onSave: (LogbookItem) -> Void
    let onCancel: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var editedItem: LogbookItem
    
    init(item: LogbookItem, colors: AppColors, onSave: @escaping (LogbookItem) -> Void, onCancel: @escaping () -> Void) {
        self.item = item
        self.colors = colors
        self.onSave = onSave
        self.onCancel = onCancel
        self._editedItem = State(initialValue: item)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch editedItem {
                        case .bgReading(let reading):
                            EditBGReadingView(
                                reading: reading,
                                colors: colors,
                                onUpdate: { updatedReading in
                                    editedItem = .bgReading(updatedReading)
                                }
                            )
                        case .insulinDose(let dose):
                            EditInsulinDoseView(
                                dose: dose,
                                colors: colors,
                                onUpdate: { updatedDose in
                                    editedItem = .insulinDose(updatedDose)
                                }
                            )
                        }
                    }
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(editedItem)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Edit BG Reading View
struct EditBGReadingView: View {
    let reading: BloodGlucoseReading
    let colors: AppColors
    let onUpdate: (BloodGlucoseReading) -> Void
    
    @State private var readingValue: Double
    @State private var readingType: BGReadingType
    @State private var dateTime: Date
    @State private var notes: String
    
    init(reading: BloodGlucoseReading, colors: AppColors, onUpdate: @escaping (BloodGlucoseReading) -> Void) {
        self.reading = reading
        self.colors = colors
        self.onUpdate = onUpdate
        self._readingValue = State(initialValue: reading.reading)
        self._readingType = State(initialValue: reading.readingType)
        self._dateTime = State(initialValue: reading.dateTime)
        self._notes = State(initialValue: reading.notes ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Reading Value
            VStack(alignment: .leading, spacing: 8) {
                Text("Reading Value")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                HStack {
                    TextField("Enter value", value: $readingValue, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Text("mg/dL")
                        .font(.body)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            // Reading Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Reading Type")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                Picker("Reading Type", selection: $readingType) {
                    ForEach(BGReadingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colors.surface)
                )
            }
            
            // Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Date & Time")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                DatePicker("Date & Time", selection: $dateTime, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.surface)
                    )
            }
            
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                TextField("Add notes...", text: $notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
        .padding(.horizontal, 20)
        .onChange(of: readingValue) { updateReading() }
        .onChange(of: readingType) { updateReading() }
        .onChange(of: dateTime) { updateReading() }
        .onChange(of: notes) { updateReading() }
    }
    
    private func updateReading() {
        let updatedReading = BloodGlucoseReading(
            patientId: reading.patientId,
            reading: readingValue,
            readingType: readingType,
            dateTime: dateTime,
            notes: notes.isEmpty ? nil : notes
        )
        updatedReading.id = reading.id
        onUpdate(updatedReading)
    }
}

// MARK: - Edit Insulin Dose View
struct EditInsulinDoseView: View {
    let dose: InsulinDose
    let colors: AppColors
    let onUpdate: (InsulinDose) -> Void
    
    @State private var doseAmount: Double
    @State private var doseType: DoseType
    @State private var dateTime: Date
    @State private var notes: String
    
    init(dose: InsulinDose, colors: AppColors, onUpdate: @escaping (InsulinDose) -> Void) {
        self.dose = dose
        self.colors = colors
        self.onUpdate = onUpdate
        self._doseAmount = State(initialValue: dose.doseAmount)
        self._doseType = State(initialValue: dose.doseType)
        self._dateTime = State(initialValue: dose.dateTime)
        self._notes = State(initialValue: dose.notes ?? "")
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Dose Amount
            VStack(alignment: .leading, spacing: 8) {
                Text("Dose Amount")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                HStack {
                    TextField("Enter amount", value: $doseAmount, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                    
                    Text("units")
                        .font(.body)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            // Dose Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Dose Type")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                Picker("Dose Type", selection: $doseType) {
                    ForEach(DoseType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colors.surface)
                )
            }
            
            // Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Date & Time")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                DatePicker("Date & Time", selection: $dateTime, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colors.surface)
                    )
            }
            
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (Optional)")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                TextField("Add notes...", text: $notes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
        .padding(.horizontal, 20)
        .onChange(of: doseAmount) { updateDose() }
        .onChange(of: doseType) { updateDose() }
        .onChange(of: dateTime) { updateDose() }
        .onChange(of: notes) { updateDose() }
    }
    
    private func updateDose() {
        let updatedDose = InsulinDose(
            patientId: dose.patientId,
            doseAmount: doseAmount,
            doseType: doseType,
            dateTime: dateTime,
            notes: notes.isEmpty ? nil : notes
        )
        updatedDose.id = dose.id
        onUpdate(updatedDose)
    }
}
