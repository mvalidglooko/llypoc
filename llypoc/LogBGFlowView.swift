//
//  LogBGFlowView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI
import SwiftData

enum ValueSelectionType {
    case specificValue
    case highLow
}

enum HypoHyperType {
    case lowHypo    // < 20 mg/dL
    case highHyper  // > 600 mg/dL
    case normal     // 20-600 mg/dL
    
    var title: String {
        switch self {
        case .lowHypo:
            return "Low Blood Glucose"
        case .highHyper:
            return "High Blood Glucose"
        case .normal:
            return "Normal Range"
        }
    }
    
    var message: String {
        switch self {
        case .lowHypo:
            return "Your blood glucose reading is very low. Please take immediate action to raise your blood glucose levels. Contact your HCP if needed."
        case .highHyper:
            return "Your blood glucose reading is very high. Please contact your healthcare provider for guidance."
        case .normal:
            return "Your blood glucose reading is within the normal range."
        }
    }
    
    var icon: String {
        switch self {
        case .lowHypo:
            return "exclamationmark.triangle.fill"
        case .highHyper:
            return "exclamationmark.triangle.fill"
        case .normal:
            return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .lowHypo:
            return .red
        case .highHyper:
            return .orange
        case .normal:
            return .green
        }
    }
}

struct LogBGFlowView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: LogBGStep = .info
    @State private var selectedReadingType: BGReadingType = .fasting
    @State private var bgValue: String = ""
    @State private var selectedDate = Date()
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var valueSelectionType: ValueSelectionType = .specificValue
    @State private var showHypoHyperAlert = false
    @State private var alertType: HypoHyperType = .normal
    @State private var showCancelAlert = false
    
    enum LogBGStep {
        case info
        case readingType
        case valueSelection
        case value
        case hypoHyperAlert
        case time
        case complete
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Header
                    VStack(spacing: 16) {
                        // Progress Bar
                        ProgressView(value: progressValue, total: Double(totalSteps))
                            .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                            .scaleEffect(y: 2)
                        
                        // Step Counter
                        HStack {
                            Text("Step \(currentStepNumber) of \(totalSteps)")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                            Spacer()
                        }
                        // Step Title
                        Text(stepTitle)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.colors.text)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case .info:
                                BGInfoView(colors: themeManager.colors)
                            case .readingType:
                                ReadingTypeView(
                                    selectedType: $selectedReadingType,
                                    colors: themeManager.colors
                                )
                            case .valueSelection:
                                ValueSelectionView(
                                    selectionType: $valueSelectionType,
                                    colors: themeManager.colors
                                )
                            case .value:
                                BGValueView(
                                    bgValue: $bgValue,
                                    readingType: selectedReadingType,
                                    valueSelectionType: valueSelectionType,
                                    colors: themeManager.colors
                                )
                            case .hypoHyperAlert:
                                HypoHyperAlertView(
                                    alertType: hypoHyperType,
                                    colors: themeManager.colors
                                )
                            case .time:
                                TimeSelectionView(
                                    selectedDate: $selectedDate,
                                    colors: themeManager.colors
                                )
                            case .complete:
                                CompleteView(
                                    reading: BloodGlucoseReading(
                                        patientId: UUID(), // Will be set to actual patient ID
                                        reading: Double(bgValue) ?? 0,
                                        readingType: selectedReadingType,
                                        dateTime: selectedDate,
                                        notes: nil
                                    ),
                                    valueSelectionType: valueSelectionType,
                                    colors: themeManager.colors
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    }
                    // Navigation Buttons
                    VStack(spacing: 12) {
                        // Next/Complete Button
                        Button(action: nextStep) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(currentStep == .complete ? "Save Reading" : "Next")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Image(systemName: "arrow.right")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(canProceed ? themeManager.colors.primary : themeManager.colors.textSecondary)
                            )
                        }
                        .disabled(!canProceed || isLoading)
                        // Back Button
                        Button(action: previousStep) {
                            Text("Back")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.colors.text)
                        }
                        .disabled(currentStep == .readingType)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if currentStep == .value {
                        Button("Cancel") {
                            showCancelAlert = true
                        }
                        .foregroundColor(themeManager.colors.primary)
                    }
                }
            }
            .alert("Unsaved Changes", isPresented: $showCancelAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Continue Editing", role: .cancel) {
                    // Do nothing, just dismiss the alert
                }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .onChange(of: showSuccessMessage) { show in
            if show {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
    }
    
    private var totalSteps: Int {
        // If hypo/hyper alert is needed, we have 6 steps, otherwise 5
        return hypoHyperType != .normal ? 6 : 5
    }
    
    private var progressValue: Double {
        switch currentStep {
        case .info: return 1.0
        case .readingType: return 2.0
        case .valueSelection: return 3.0
        case .value: return 4.0
        case .hypoHyperAlert: return 5.0
        case .time: return totalSteps == 6 ? 6.0 : 5.0
        case .complete: return Double(totalSteps)
        }
    }
    
    private var currentStepNumber: Int {
        switch currentStep {
        case .info: return 1
        case .readingType: return 2
        case .valueSelection: return 3
        case .value: return 4
        case .hypoHyperAlert: return 5
        case .time: return totalSteps == 6 ? 6 : 5
        case .complete: return totalSteps
        }
    }
    
    private var stepTitle: String {
        switch currentStep {
        case .info: return "About Blood Glucose"
        case .readingType: return "Reading Type"
        case .valueSelection: return "Value Selection"
        case .value: return "Blood Glucose Value"
        case .hypoHyperAlert: return hypoHyperType.title
        case .time: return "When was this reading?"
        case .complete: return "Review & Save"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .info:
            return true
        case .readingType:
            return true
        case .valueSelection:
            return true
        case .value:
            if valueSelectionType == .highLow {
                return bgValue == "601" || bgValue == "19"
            } else {
                guard let value = Double(bgValue), !bgValue.isEmpty else { return false }
                return true
            }
        case .hypoHyperAlert:
            return true
        case .time:
            return true
        case .complete:
            return true
        }
    }
    
    private var hypoHyperType: HypoHyperType {
        guard let value = Double(bgValue) else { return .normal }
        
        if value < 20 {
            return .lowHypo
        } else if value > 600 {
            return .highHyper
        } else {
            return .normal
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .info:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .readingType
            }
        case .readingType:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .valueSelection
            }
            
        case .valueSelection:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .value
            }
            
        case .value:
            // Check if we need to show hypo/hyper alert
            if hypoHyperType != .normal {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .hypoHyperAlert
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .time
                }
            }
            
        case .hypoHyperAlert:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .time
            }
            
        case .time:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .complete
            }
            
        case .complete:
            saveReading()
        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .info:
            break
        case .readingType:
            currentStep = .info
        case .valueSelection:
            currentStep = .readingType
        case .value:
            currentStep = .valueSelection
        case .hypoHyperAlert:
            currentStep = .value
        case .time:
            if hypoHyperType != .normal {
                currentStep = .hypoHyperAlert
            } else {
                currentStep = .value
            }
        case .complete:
            currentStep = .time
        }
    }
    
    private func saveReading() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            let readingValue = Double(bgValue) ?? 0
            
            let reading = BloodGlucoseReading(
                patientId: UUID(),
                reading: readingValue,
                readingType: selectedReadingType,
                dateTime: selectedDate,
                notes: nil
            )
            
            modelContext.insert(reading)
            
            // Show success message
            showSuccessMessage = true
        }
    }
}

// MARK: - Reading Type View
struct ReadingTypeView: View {
    @Binding var selectedType: BGReadingType
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Text("What type of blood glucose reading is this?")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                ForEach(BGReadingType.allCases, id: \.self) { type in
                    ReadingTypeCard(
                        type: type,
                        isSelected: selectedType == type,
                        colors: colors
                    ) {
                        selectedType = type
                    }
                }
            }
        }
    }
}

struct ReadingTypeCard: View {
    let type: BGReadingType
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : colors.text)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? colors.primary : colors.surface)
                    .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - BG Value View
struct BGValueView: View {
    @Binding var bgValue: String
    let readingType: BGReadingType
    let valueSelectionType: ValueSelectionType
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            if valueSelectionType == .specificValue {
                // Specific value input
                VStack(spacing: 16) {
                    Text("Enter your blood glucose reading")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    HStack {
                        TextField("120", text: $bgValue)
                            .font(.title)
                            .fontWeight(.bold)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.surface)
                                    .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
                            )
                        
                        Text("mg/dL")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(colors.textSecondary)
                    }
                    

                }
            } else {
                // High/Low selection
                VStack(spacing: 16) {
                    Text("Select your blood glucose reading")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        HighLowCard(
                            title: "High",
                            subtitle: "601+ mg/dL (33.4+ mmol/L)",
                            icon: "arrow.up.circle.fill",
                            color: colors.error,
                            isSelected: bgValue == "601",
                            colors: colors
                        ) {
                            bgValue = "601"
                        }
                        
                        HighLowCard(
                            title: "Low",
                            subtitle: "19 mg/dL or less (1.0 mmol/L or less)",
                            icon: "arrow.down.circle.fill",
                            color: colors.warning,
                            isSelected: bgValue == "19",
                            colors: colors
                        ) {
                            bgValue = "19"
                        }
                    }
                }
            }
        }
    }
}

struct HighLowCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : colors.text)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : colors.surface)
                    .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Time Selection View
struct TimeSelectionView: View {
    @Binding var selectedDate: Date
    let colors: AppColors
    
    // Calculate the minimum allowed date (7 days ago or since last dose, which is more recent)
    private var minimumDate: Date {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sevenDaysAgo
    }
    
    // Calculate the maximum allowed date (today)
    private var maximumDate: Date {
        return Date()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("When did you take this reading?")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                DatePicker(
                    "Reading Time",
                    selection: $selectedDate,
                    in: minimumDate...maximumDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                
                // Quick time options
                VStack(spacing: 8) {
                    Text("Quick Options")
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                    
                    HStack(spacing: 12) {
                        QuickTimeButton(
                            title: "Now",
                            colors: colors
                        ) {
                            selectedDate = Date()
                        }
                        
                        QuickTimeButton(
                            title: "1 hour ago",
                            colors: colors
                        ) {
                            selectedDate = Date().addingTimeInterval(-3600)
                        }
                        
                        QuickTimeButton(
                            title: "2 hours ago",
                            colors: colors
                        ) {
                            selectedDate = Date().addingTimeInterval(-7200)
                        }
                    }
                }
            }
        }
    }
}

struct QuickTimeButton: View {
    let title: String
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(colors.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(colors.primary, lineWidth: 1)
                )
        }
    }
}



// MARK: - Complete View
struct CompleteView: View {
    let reading: BloodGlucoseReading
    let valueSelectionType: ValueSelectionType
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.success)
            
            Text("Review Your Reading")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colors.text)
            
            VStack(spacing: 16) {
                ReviewItem(
                    title: "Reading Type",
                    value: reading.readingType.rawValue,
                    colors: colors
                )
                
                ReviewItem(
                    title: "Blood Glucose",
                    value: valueDisplayText,
                    colors: colors
                )
                
                ReviewItem(
                    title: "Date & Time",
                    value: reading.dateTime.formatted(date: .abbreviated, time: .shortened),
                    colors: colors
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .shadow(color: colors.shadow, radius: 4, x: 0, y: 2)
            )
        }
    }
    
    private var valueDisplayText: String {
        if valueSelectionType == .highLow {
            if reading.reading == 601 {
                return "High (601+ mg/dL)"
            } else if reading.reading == 19 {
                return "Low (≤19 mg/dL)"
            }
        }
        return "\(Int(reading.reading)) mg/dL"
    }
}

struct ReviewItem: View {
    let title: String
    let value: String
    let colors: AppColors
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colors.text)
        }
    }
}

// MARK: - BG Reading Type Extensions
extension BGReadingType {
    var description: String {
        switch self {
        case .fasting:
            return "Taken before eating (morning)"
        case .afterBreakfast:
            return "Taken 1-2 hours after breakfast"
        case .beforeLunch:
            return "Taken before lunch"
        case .afterLunch:
            return "Taken 1-2 hours after lunch"
        case .beforeDinner:
            return "Taken before dinner"
        case .afterDinner:
            return "Taken 1-2 hours after dinner"
        }
    }
    
    var icon: String {
        switch self {
        case .fasting:
            return "sunrise.fill"
        case .afterBreakfast:
            return "sun.max.fill"
        case .beforeLunch:
            return "clock.fill"
        case .afterLunch:
            return "clock.arrow.circlepath"
        case .beforeDinner:
            return "sunset.fill"
        case .afterDinner:
            return "moon.fill"
        }
    }
}

// MARK: - Value Selection View
struct ValueSelectionView: View {
    @Binding var selectionType: ValueSelectionType
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Text("How would you like to enter your blood glucose value?")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                ValueSelectionCard(
                    title: "Enter Specific Value",
                    subtitle: "Type in your exact blood glucose reading",
                    icon: "keyboard",
                    isSelected: selectionType == .specificValue,
                    colors: colors
                ) {
                    selectionType = .specificValue
                }
                
                ValueSelectionCard(
                    title: "Select High/Low Reading",
                    subtitle: "Choose from predefined options",
                    icon: "arrow.up.arrow.down",
                    isSelected: selectionType == .highLow,
                    colors: colors
                ) {
                    selectionType = .highLow
                }
            }
        }
    }
}

struct ValueSelectionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : colors.primary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : colors.text)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? colors.primary : colors.surface)
                    .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Hypo/Hyper Alert View
struct HypoHyperAlertView: View {
    let alertType: HypoHyperType
    let colors: AppColors
    @State private var isNocturnalEvent: Bool = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon and Title
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(alertType.color.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: alertType.icon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(alertType.color)
                }
                
                Text(alertType.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.center)
            }
            
            // Message
            VStack(spacing: 16) {
                Text(alertType.message)
                    .font(.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // Nocturnal Event Selection (hypo/hyper events)
                if alertType == .lowHypo || alertType == .highHyper {
                    VStack(spacing: 16) {
                        Text("Is this a nocturnal event?")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(colors.text)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                isNocturnalEvent = false
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.title2)
                                        .foregroundColor(isNocturnalEvent ? colors.textSecondary : colors.primary)
                                    
                                    Text("Daytime")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(isNocturnalEvent ? colors.textSecondary : colors.text)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isNocturnalEvent ? colors.surface : colors.primary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isNocturnalEvent ? Color.clear : colors.primary, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                isNocturnalEvent = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "moon.fill")
                                        .font(.title2)
                                        .foregroundColor(isNocturnalEvent ? colors.primary : colors.textSecondary)
                                    
                                    Text("Nighttime")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(isNocturnalEvent ? colors.text : colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isNocturnalEvent ? colors.primary.opacity(0.1) : colors.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isNocturnalEvent ? colors.primary : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colors.surface)
                            .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
                    )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - BG Info View
struct BGInfoView: View {
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "drop.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
            
            // Title
            VStack(spacing: 12) {
                Text("What is Fasting Blood Glucose?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                    .multilineTextAlignment(.center)
                
                Text("Fasting Blood Glucose (FBG) is your blood sugar level after not eating for at least 8 hours, typically measured first thing in the morning.")
                    .font(.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Key Points
            VStack(spacing: 16) {
                InfoPointView(
                    icon: "clock.fill",
                    title: "When to Measure",
                    description: "First thing in the morning, before eating or drinking anything except water",
                    colors: colors
                )
                
                InfoPointView(
                    icon: "target",
                    title: "Target Range",
                    description: "80-130 mg/dL for most people with diabetes",
                    colors: colors
                )
                
                InfoPointView(
                    icon: "heart.fill",
                    title: "Why It's Important",
                    description: "Helps track how well your diabetes management plan is working",
                    colors: colors
                )
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Info Point View
struct InfoPointView: View {
    let icon: String
    let title: String
    let description: String
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(colors.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.text)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surface)
                .shadow(color: colors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}
