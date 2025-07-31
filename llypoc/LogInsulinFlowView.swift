//
//  LogInsulinFlowView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI
import SwiftData

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

struct LogInsulinFlowView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: LogInsulinStep
    @State private var selectedDoseType: DoseType = .weekly
    @State private var doseAmount: String = ""
    @State private var selectedDate = Date()
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var isStarterDose: Bool = false
    @State private var showCancelAlert = false
    
    // Bypass starter dose question
    let bypassStarterDoseQuestion: Bool
    // if this is from onboarding flow
    let isFromOnboarding: Bool
    // Test scenario for Quick Actions
    let testScenario: QuickActionTestScenario?
    
    init(bypassStarterDoseQuestion: Bool = false, isFromOnboarding: Bool = false, testScenario: QuickActionTestScenario? = nil, prePopulatedDose: Double? = nil) {
        self.bypassStarterDoseQuestion = bypassStarterDoseQuestion
        self.isFromOnboarding = isFromOnboarding
        self.testScenario = testScenario
        
        print("🔍 DEBUG: bypassStarterDoseQuestion = \(bypassStarterDoseQuestion)")
        print("🔍 DEBUG: testScenario = \(testScenario?.rawValue ?? "nil")")
        print("🔍 DEBUG: prePopulatedDose = \(prePopulatedDose ?? 0)")
        
        if bypassStarterDoseQuestion {
            print("🔍 DEBUG: Starting at .amount step")
            self._currentStep = State(initialValue: .amount)
        } else {
            print("🔍 DEBUG: Starting at .starterDoseQuestion step")
            self._currentStep = State(initialValue: .starterDoseQuestion)
        }
        self._isStarterDose = State(initialValue: false)
        self._selectedDoseType = State(initialValue: .weekly)
        
        // Pre-populate dose amount
        if let prePopulatedDose = prePopulatedDose {
            self._doseAmount = State(initialValue: String(Int(prePopulatedDose)))
        } else {
            self._doseAmount = State(initialValue: "")
        }
    }
    
    enum LogInsulinStep {
        case starterDoseQuestion
        case starterDoseInfo
        case amount
        case time
        case complete
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Cancel Button
                    HStack {
                        Button(action: {
                            showCancelAlert = true
                        }) {
                            Text("Cancel")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
                    
                    // Progress Header
                    VStack(spacing: 16) {
                        // Progress Bar
                        ProgressView(value: progressValue, total: shouldBypassStarterDose ? 3.0 : 4.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                            .scaleEffect(y: 2)
                        
                        // Step Counter
                        HStack {
                            Text("Step \(currentStepNumber) of \(shouldBypassStarterDose ? 3 : 4)")
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
                            case .starterDoseQuestion:
                                StarterDoseQuestionView(
                                    isStarterDose: $isStarterDose,
                                    colors: themeManager.colors
                                )
                                
                            case .starterDoseInfo:
                                StarterDoseInfoView(
                                    colors: themeManager.colors
                                )
                                
                            case .amount:
                                DoseAmountView(
                                    doseAmount: $doseAmount,
                                    doseType: selectedDoseType,
                                    isStarterDose: isStarterDose,
                                    colors: themeManager.colors
                                )
                                
                            case .time:
                                DoseTimeSelectionView(
                                    selectedDate: $selectedDate,
                                    colors: themeManager.colors
                                )
                                
                            case .complete:
                                CompleteDoseView(
                                    dose: InsulinDose(
                                        patientId: UUID(), // Will be set to actual patient ID
                                        doseAmount: Double(doseAmount) ?? 0,
                                        doseType: selectedDoseType,
                                        dateTime: selectedDate,
                                        notes: nil
                                    ),
                                    colors: themeManager.colors
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    }
                    
                    // Navigation Buttons
                    VStack(spacing: 12) {
                        if currentStep == .starterDoseInfo {
                            // Ok Button for Starter Dose Info
                            Button(action: {
                                if isFromOnboarding {
                                    AuthenticationManager.shared.isAuthenticated = true
                                }
                                dismiss()
                            }) {
                                Text("Ok")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.colors.border)
                                    )
                                    .foregroundColor(themeManager.colors.textSecondary)
                            }
                        } else {
                            // Next/Complete Button
                            Button(action: nextStep) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(currentStep == .complete ? "Save Dose" : "Next")
                                            .fontWeight(.semibold)
                                        
                                        if currentStep != .complete {
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(canProceed ? themeManager.colors.primary : themeManager.colors.border)
                                )
                                .foregroundColor(.white)
                            }
                            .disabled(!canProceed || isLoading)
                            .animation(.easeInOut(duration: 0.2), value: canProceed)
                        }
                        
                        // Back Button
                        if (currentStep != .starterDoseQuestion && !bypassStarterDoseQuestion) ||
                           (bypassStarterDoseQuestion && currentStep != .amount) {
                            Button("Back") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    previousStep()
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(themeManager.colorScheme)
        .alert("Discard Changes?", isPresented: $showCancelAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {
                // Do nothing, just dismiss the alert
            }
        } message: {
            Text("Are you sure you want to discard your changes? This action cannot be undone.")
        }
        .onChange(of: showSuccessMessage) { show in
            if show {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    // Only dismiss if not coming from onboarding
                    if !isFromOnboarding {
                        dismiss()
                    }
                }
            }
        }

    }
    
    private var shouldBypassStarterDose: Bool {
        return bypassStarterDoseQuestion || testScenario == .weeklyDose
    }
    
    private var progressValue: Double {
        if shouldBypassStarterDose {
            switch currentStep {
            case .starterDoseQuestion: return 1.0
            case .starterDoseInfo: return 1.0
            case .amount: return 1.0
            case .time: return 2.0
            case .complete: return 3.0
            }
        } else {
            switch currentStep {
            case .starterDoseQuestion: return 1.0
            case .starterDoseInfo: return 1.0
            case .amount: return 2.0
            case .time: return 3.0
            case .complete: return 4.0
            }
        }
    }
    
    private var currentStepNumber: Int {
        if shouldBypassStarterDose {
            switch currentStep {
            case .starterDoseQuestion: return 1
            case .starterDoseInfo: return 1
            case .amount: return 1
            case .time: return 2
            case .complete: return 3
            }
        } else {
            switch currentStep {
            case .starterDoseQuestion: return 1
            case .starterDoseInfo: return 1
            case .amount: return 2
            case .time: return 3
            case .complete: return 4
            }
        }
    }
    
    private var stepTitle: String {
        switch currentStep {
        case .starterDoseQuestion: return "Starter Dose Details"
        case .starterDoseInfo: return "Starter Dose Required"
        case .amount: return "Insulin Amount"
        case .time: return "When did you take this dose?"
        case .complete: return "Review & Save"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .starterDoseQuestion:
            return true
        case .starterDoseInfo:
            return false
        case .amount:
            return !doseAmount.isEmpty && Double(doseAmount) != nil
        case .time:
            return true
        case .complete:
            return true
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .starterDoseQuestion:
            if isStarterDose {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .amount
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .starterDoseInfo
                }
            }
            
        case .starterDoseInfo:
            break
            
        case .amount:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .time
            }
            
        case .time:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .complete
            }
            
        case .complete:
            saveDose()
        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .starterDoseQuestion:
            break
        case .starterDoseInfo:
            currentStep = .starterDoseQuestion
        case .amount:
            if bypassStarterDoseQuestion {
                break
            } else {
                currentStep = .starterDoseQuestion
            }
        case .time:
            currentStep = .amount
        case .complete:
            currentStep = .time
        }
    }
    
    private func saveDose() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // Create and save the dose
            if let doseAmountDouble = Double(doseAmount) {
                let finalDoseType: DoseType = isStarterDose ? .starting : selectedDoseType
                
                let dose = InsulinDose(
                    patientId: UUID(),
                    doseAmount: doseAmountDouble,
                    doseType: finalDoseType,
                    dateTime: selectedDate,
                    notes: nil
                )
                
                modelContext.insert(dose)
                
                showSuccessMessage = true
                
                if isFromOnboarding {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Set authentication and dismiss the onboarding flow
                        AuthenticationManager.shared.isAuthenticated = true
                        dismiss()
                    }
                }
            }
        }
    }
}



// MARK: - Dose Amount View
struct DoseAmountView: View {
    @Binding var doseAmount: String
    let doseType: DoseType
    let isStarterDose: Bool
    let colors: AppColors
    
    @State private var selectedPickerValue: Int = 300
    
    private var pickerValues: [Int] {
        return Array(stride(from: 0, through: 3000, by: 5))
    }
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("Select your dose amount")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(colors.text)
                
                Picker("Dose Amount", selection: $selectedPickerValue) {
                    ForEach(pickerValues, id: \.self) { value in
                        Text("\(value)")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .tag(value)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(height: 220)
                .onChange(of: selectedPickerValue) { newValue in
                    doseAmount = String(newValue)
                }
            }
            .padding(.vertical, 24)
            
            // Information section
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: isStarterDose ? "syringe" : "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(colors.primary)
                    
                    Text(infoTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.text)
                    
                    Spacer()
                }
                
                Text(infoText)
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
            .padding(20)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Initialize picker with current dose amount
            if let currentValue = Int(doseAmount) {
                selectedPickerValue = currentValue
            }
        }
    }
    

    
    private var infoTitle: String {
        if isStarterDose {
            return "Starting Dose"
        } else {
            return doseType.infoTitle
        }
    }
    
    private var infoText: String {
        if isStarterDose {
            return "This is your initial dose to begin treatment. Your HCP prescribed 300 units to start your titration."
        } else {
            return doseType.infoText
        }
    }
}

// MARK: - Dose Time Selection View
struct DoseTimeSelectionView: View {
    @Binding var selectedDate: Date
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Text("When did you take this dose?")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                DatePicker(
                    "Dose Time",
                    selection: $selectedDate,
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
                        DoseQuickTimeButton(
                            title: "Now",
                            colors: colors
                        ) {
                            selectedDate = Date()
                        }
                        
                        DoseQuickTimeButton(
                            title: "1 hour ago",
                            colors: colors
                        ) {
                            selectedDate = Date().addingTimeInterval(-3600)
                        }
                        
                        DoseQuickTimeButton(
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

struct DoseQuickTimeButton: View {
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



// MARK: - Complete Dose View
struct CompleteDoseView: View {
    let dose: InsulinDose
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.success)
            
            Text("Review Your Dose")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colors.text)
            
            VStack(spacing: 16) {
                DoseReviewItem(
                    title: "Dose Type",
                    value: dose.doseType.rawValue,
                    colors: colors
                )
                
                DoseReviewItem(
                    title: "Insulin Amount",
                    value: "\(Int(dose.doseAmount)) units",
                    colors: colors
                )
                
                DoseReviewItem(
                    title: "Date & Time",
                    value: dose.dateTime.formatted(date: .abbreviated, time: .shortened),
                    colors: colors
                )
                
                if let notes = dose.notes, !notes.isEmpty {
                    DoseReviewItem(
                        title: "Notes",
                        value: notes,
                        colors: colors
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .shadow(color: colors.shadow, radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct DoseReviewItem: View {
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

// MARK: - Dose Type Extensions
extension DoseType {
    var description: String {
        switch self {
        case .starting:
            return "Initial dose when starting treatment"
        case .weekly:
            return "Regular weekly maintenance dose"
        case .correction:
            return "Additional dose to correct high BG"
        }
    }
    
    var icon: String {
        switch self {
        case .starting:
            return "play.circle.fill"
        case .weekly:
            return "calendar.circle.fill"
        case .correction:
            return "plus.circle.fill"
        }
    }
    
    var infoTitle: String {
        switch self {
        case .starting:
            return "Starting Dose"
        case .weekly:
            return "Weekly Dose"
        case .correction:
            return "Correction Dose"
        }
    }
    
    var infoText: String {
        switch self {
        case .starting:
            return "This is your initial dose when starting Efsitora treatment"
        case .weekly:
            return "This is your regular weekly maintenance dose"
        case .correction:
            return "This is an additional dose to correct high blood glucose"
        }
    }
}

// MARK: - Starter Dose Question View
struct StarterDoseQuestionView: View {
    @Binding var isStarterDose: Bool
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Have you taken the starter dose?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colors.text)
                .multilineTextAlignment(.center)
            
            Text("Your HCP prescribed a 300 units Efsitora starter dose to begin your titration. Have you already taken this dose?")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                RadioButtonCard(
                    title: "Yes, I took it",
                    isSelected: isStarterDose,
                    colors: colors
                ) {
                    isStarterDose = true
                }
                
                RadioButtonCard(
                    title: "No, not yet",
                    isSelected: !isStarterDose,
                    colors: colors
                ) {
                    isStarterDose = false
                }
            }
        }
    }
}

struct RadioButtonCard: View {
    let title: String
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(colors.primary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(colors.primary)
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
                
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? colors.primary.opacity(0.1) : colors.surface)
                    .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Starter Dose Info View
struct StarterDoseInfoView: View {
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.warning)
            
            Text("You must take your starter dose before logging any other insulin doses. The starter dose is essential for beginning your treatment safely.")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                InfoItem(
                    icon: "syringe",
                    title: "300 units Efsitora",
                    subtitle: "Prescribed starter dose",
                    colors: colors
                )
                
                InfoItem(
                    icon: "clock",
                    title: "Take as prescribed",
                    subtitle: "Follow your HCP's instructions",
                    colors: colors
                )
                
                InfoItem(
                    icon: "checkmark.circle",
                    title: "Then log your dose",
                    subtitle: "Return here after taking the starter dose",
                    colors: colors
                )
            }
        }
    }
}

struct InfoItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colors.text)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.surface)
        )
    }
}



#Preview {
    LogInsulinFlowView()
}
