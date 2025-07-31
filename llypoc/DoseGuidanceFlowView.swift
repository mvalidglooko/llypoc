//
//  DoseGuidanceFlowView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI
import SwiftData

struct DoseGuidanceFlowView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: DoseGuidanceStep = .fbgReview
    @State private var isLoading = false
    @State private var showSuccessMessage = false
    @State private var guidanceResult: DoseGuidanceResult?
    @State private var showLogBGFlow = false
    @State private var showLogInsulinFlow = false
    
    // Data for the flow
    let recentFBGReadings: [BloodGlucoseReading]
    let lastDose: InsulinDose?
    let patient: Patient
    let scenario: String?
    
    init(patient: Patient, recentFBGReadings: [BloodGlucoseReading], lastDose: InsulinDose?, scenario: String? = nil) {
        self.patient = patient
        self.recentFBGReadings = recentFBGReadings
        self.lastDose = lastDose
        self.scenario = scenario
    }
    
    enum DoseGuidanceStep {
        case fbgReview
        case calculating
        case results
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
                        ProgressView(value: progressValue, total: 3.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                            .scaleEffect(y: 2)
                        
                        // Step Counter
                        HStack {
                            Text("Step \(currentStepNumber) of 3")
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
                            case .fbgReview:
                                FBGReviewView(
                                    colors: themeManager.colors,
                                    recentFBGReadings: recentFBGReadings,
                                    lastDose: lastDose,
                                    scenario: scenario,
                                    onAddFBG: {
                                        showLogBGFlow = true
                                    }
                                )
                                
                            case .calculating:
                                CalculatingView(
                                    colors: themeManager.colors
                                )
                                
                            case .results:
                                if let result = guidanceResult {
                                    ResultsView(
                                        colors: themeManager.colors,
                                        result: result
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    }
                    
                    // Navigation Buttons
                    VStack(spacing: 12) {
                        if currentStep != .calculating && currentStep != .results {
                            // Next Button
                            Button(action: nextStep) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Next")
                                            .fontWeight(.semibold)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.caption)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.colors.primary)
                                )
                                .foregroundColor(.white)
                            }
                            .disabled(isLoading)
                            .animation(.easeInOut(duration: 0.2), value: isLoading)
                        }
                        
                        if currentStep == .results {
                            // Log Dose Button
                            Button(action: {
                                showLogInsulinFlow = true
                            }) {
                                HStack {
                                    Image(systemName: "syringe.fill")
                                        .font(.headline)
                                    Text("Log Dose")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.colors.primary)
                                )
                            }
                        }
                        

                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(themeManager.colorScheme)
        .fullScreenCover(isPresented: $showLogBGFlow) {
            LogBGFlowView()
        }
        .fullScreenCover(isPresented: $showLogInsulinFlow) {
            LogInsulinFlowView(
                bypassStarterDoseQuestion: true,
                isFromOnboarding: false,
                testScenario: nil,
                prePopulatedDose: guidanceResult?.recommendedDose
            )
        }
        .onAppear {
            print("DoseGuidanceFlowView appeared")
            print("Patient: \(patient.name)")
            print("Recent FBG readings count: \(recentFBGReadings.count)")
            print("Last dose: \(lastDose?.doseAmount ?? 0) units")
        }
    }
    
    private var progressValue: Double {
        switch currentStep {
        case .fbgReview: return 1.0
        case .calculating: return 2.0
        case .results: return 3.0
        }
    }
    
    private var currentStepNumber: Int {
        switch currentStep {
        case .fbgReview: return 1
        case .calculating: return 2
        case .results: return 3
        }
    }
    
    private var stepTitle: String {
        switch currentStep {
        case .fbgReview: return "Fasting Blood Glucose Review"
        case .calculating: return "Calculating Guidance"
        case .results: return "Your Dose Guidance"
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .fbgReview:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .calculating
            }
            calculateGuidance()
            
        case .calculating:
            break
            
        case .results:
            break
        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .fbgReview:
            break
        case .calculating:
            currentStep = .fbgReview
        case .results:
            currentStep = .calculating
        }
    }
    
    private func calculateGuidance() {
        isLoading = true
        
        // Simulate API call for dose guidance calculation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            isLoading = false
            
            let result = calculateDoseGuidance()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                guidanceResult = result
                currentStep = .results
            }
        }
    }
    
    private func calculateDoseGuidance() -> DoseGuidanceResult {
        // Calculate average FBG from recent readings
        let averageFBG = recentFBGReadings.isEmpty ? 0 : recentFBGReadings.map { $0.reading }.reduce(0, +) / Double(recentFBGReadings.count)
        
        let recommendedDose: Double
        let reasoning: String
        let riskLevel: RiskLevel
        
        if averageFBG < 80 {
            recommendedDose = 250 // Lower dose for low FBG
            reasoning = "Your average FBG is below target range. Consider a lower dose to avoid hypoglycemia."
            riskLevel = .low
        } else if averageFBG >= 80 && averageFBG <= 130 {
            recommendedDose = 300 // Standard dose for target range
            reasoning = "Your average FBG is within target range. Continue with your current dose."
            riskLevel = .low
        } else if averageFBG > 130 && averageFBG <= 180 {
            recommendedDose = 350 // Slightly higher dose
            reasoning = "Your average FBG is elevated. Consider a moderate dose increase."
            riskLevel = .medium
        } else {
            recommendedDose = 400 // Higher dose for high FBG
            reasoning = "Your average FBG is significantly elevated. Consider a higher dose and consult your HCP."
            riskLevel = .high
        }
        
        return DoseGuidanceResult(
            recommendedDose: recommendedDose,
            reasoning: reasoning,
            riskLevel: riskLevel,
            averageFBG: averageFBG,
            readingsCount: recentFBGReadings.count,
            lastDoseDate: lastDose?.dateTime
        )
    }
}

// MARK: - Data Models
struct DoseGuidanceResult {
    let recommendedDose: Double
    let reasoning: String
    let riskLevel: RiskLevel
    let averageFBG: Double
    let readingsCount: Int
    let lastDoseDate: Date?
}

enum RiskLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Low risk of complications"
        case .medium: return "Moderate risk - monitor closely"
        case .high: return "High risk - consult your HCP"
        }
    }
}

// MARK: - Step Views
struct ConfirmationView: View {
    let colors: AppColors
    let recentFBGReadings: [BloodGlucoseReading]
    let lastDose: InsulinDose?
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
            
            // Title and Description
            VStack(spacing: 12) {
                Text("Request Dose Guidance")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("We'll analyze your recent FBG readings and treatment history to provide personalized dose guidance.")
                    .font(.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Data Summary
            VStack(spacing: 16) {
                Text("Data Summary")
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                VStack(spacing: 12) {
                    DataSummaryRow(
                        title: "Recent FBG Readings",
                        value: "\(recentFBGReadings.count) readings",
                        icon: "drop.fill",
                        iconColor: .blue,
                        colors: colors
                    )
                    
                    if let lastDose = lastDose {
                        DataSummaryRow(
                            title: "Last Dose",
                            value: lastDose.dateTime.formatted(date: .abbreviated, time: .shortened),
                            icon: "syringe",
                            iconColor: .green,
                            colors: colors
                        )
                    }
                    
                    DataSummaryRow(
                        title: "Analysis Period",
                        value: "Last 7 days",
                        icon: "calendar",
                        iconColor: .orange,
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
            
            // Disclaimer
            VStack(spacing: 8) {
                Text("Important")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.text)
                
                Text("This guidance is based on your data and treatment plan. Always consult with your healthcare provider before making changes to your insulin dose.")
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors.primary.opacity(0.1))
            )
        }
    }
}

struct DataReviewView: View {
    let colors: AppColors
    let recentFBGReadings: [BloodGlucoseReading]
    let lastDose: InsulinDose?
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            VStack(spacing: 8) {
                Text("Review Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("Please review the data that will be used for dose guidance calculation.")
                    .font(.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // FBG Readings
            VStack(spacing: 16) {
                HStack {
                    Text("Recent FBG Readings")
                        .font(.headline)
                        .foregroundColor(colors.text)
                    Spacer()
                    Text("\(recentFBGReadings.count) readings")
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                if recentFBGReadings.isEmpty {
                    Text("No recent FBG readings available")
                        .font(.body)
                        .foregroundColor(colors.textSecondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colors.surface)
                        )
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(recentFBGReadings.prefix(6), id: \.id) { reading in
                            DoseGuidanceFBGReadingCard(
                                reading: reading,
                                colors: colors
                            )
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .shadow(color: colors.shadow, radius: 4, x: 0, y: 2)
            )
            
            // Last Dose Information
            if let lastDose = lastDose {
                VStack(spacing: 16) {
                    HStack {
                        Text("Last Insulin Dose")
                            .font(.headline)
                            .foregroundColor(colors.text)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Dose Amount")
                                .font(.subheadline)
                                .foregroundColor(colors.textSecondary)
                            Spacer()
                            Text("\(Int(lastDose.doseAmount)) units")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colors.text)
                        }
                        
                        HStack {
                            Text("Date & Time")
                                .font(.subheadline)
                                .foregroundColor(colors.textSecondary)
                            Spacer()
                            Text(lastDose.dateTime.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colors.text)
                        }
                        
                        HStack {
                            Text("Dose Type")
                                .font(.subheadline)
                                .foregroundColor(colors.textSecondary)
                            Spacer()
                            Text(lastDose.doseType.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colors.text)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.surface)
                        .shadow(color: colors.shadow, radius: 4, x: 0, y: 2)
                )
            }
        }
    }
}

struct CalculatingView: View {
    let colors: AppColors
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(colors.primary)
                .scaleEffect(1.0 + animationOffset * 0.1)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationOffset)
                .onAppear {
                    animationOffset = 1.0
                }
            
            // Title and Description
            VStack(spacing: 16) {
                Text("Calculating Your Guidance")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("We're analyzing your data to provide personalized dose guidance. This may take a few moments.")
                    .font(.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress Indicators
            VStack(spacing: 16) {
                ProgressStep(
                    title: "Analyzing FBG readings",
                    isCompleted: true,
                    colors: colors
                )
                
                ProgressStep(
                    title: "Reviewing treatment history",
                    isCompleted: true,
                    colors: colors
                )
                
                ProgressStep(
                    title: "Calculating optimal dose",
                    isCompleted: false,
                    colors: colors
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .shadow(color: colors.shadow, radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct ResultsView: View {
    let colors: AppColors
    let result: DoseGuidanceResult
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            // Circular Dose Display
            VStack(spacing: 20) {
                ZStack {
                    // Outer gradient ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colors.primary.opacity(0.3),
                                    colors.primary,
                                    colors.primary.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 200, height: 200)
                    
                    // Inner circle with dose value
                    VStack(spacing: 8) {
                        Text("\(Int(result.recommendedDose))")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(colors.primary)
                        
                        Text("units")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                
                Text("Recommended Dose")
                    .font(.headline)
                    .foregroundColor(colors.text)
            }
            .padding(.vertical, 20)
            

            
            Spacer()
        }
    }
}

// MARK: - Helper Views
struct DataSummaryRow: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(colors.text)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colors.text)
        }
    }
}

struct DoseGuidanceFBGReadingCard: View {
    let reading: BloodGlucoseReading
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(reading.reading))")
                .font(.headline)
                .fontWeight(.semibold)
                    .foregroundColor(colors.text)
            
            Text("mg/dL")
                .font(.caption)
                .foregroundColor(colors.textSecondary)
            
            Text(reading.dateTime.formatted(date: .omitted, time: .shortened))
                .font(.caption2)
                .foregroundColor(colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colors.border, lineWidth: 1)
                )
        )
    }
}

struct ProgressStep: View {
    let title: String
    let isCompleted: Bool
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundColor(isCompleted ? .green : colors.textSecondary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(isCompleted ? colors.text : colors.textSecondary)
            
            Spacer()
        }
    }
}

// MARK: - FBG Review View
struct FBGReviewView: View {
    let colors: AppColors
    let recentFBGReadings: [BloodGlucoseReading]
    let lastDose: InsulinDose?
    let scenario: String?
    let onAddFBG: () -> Void
    
    private var lastDoseDate: Date? {
        lastDose?.dateTime
    }
    
    private var daysSinceLastDose: Int {
        guard let lastDoseDate = lastDoseDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: lastDoseDate, to: Date()).day ?? 0
    }
    
    private var requiredDays: [Date] {
        // Get the last 3 days since last dose
        var days: [Date] = []
        for i in 1...3 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                days.append(date)
            }
        }
        return days.reversed()
    }
    
    private func hasFBGForDate(_ date: Date) -> Bool {
        return recentFBGReadings.contains { reading in
            Calendar.current.isDate(reading.dateTime, inSameDayAs: date)
        }
    }
    
    private func getFBGForDate(_ date: Date) -> BloodGlucoseReading? {
        return recentFBGReadings.first { reading in
            Calendar.current.isDate(reading.dateTime, inSameDayAs: date)
        }
    }
    
    private var completedFBGCount: Int {
        requiredDays.filter { hasFBGForDate($0) }.count
    }
    
    private var isAllFBGCompleted: Bool {
        completedFBGCount == 3
    }
    
    private var fbgStatusMessage: (String, Color) {
        if isAllFBGCompleted {
            return ("Great! You have all 3 FBG readings. You're set for an accurate recommendation.", .green)
        } else {
            return ("It would be good to log all 3 FBG readings first for the most accurate recommendation.", .orange)
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("For accurate dose guidance, we recommend having 3 FBG readings from different days since your last dose.")
                    .font(.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // FBG Status Info
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: isAllFBGCompleted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(fbgStatusMessage.1)
                    
                    Text(fbgStatusMessage.0)
                        .font(.subheadline)
                        .foregroundColor(colors.text)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(fbgStatusMessage.1.opacity(0.1))
                )
            }
            
            // FBG Status
            VStack(spacing: 16) {
                
                VStack(spacing: 12) {
                    ForEach(requiredDays, id: \.self) { date in
                        if let fbgReading = getFBGForDate(date) {
                            // Show existing FBG reading
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(colors.text)
                                    
                                    Text("\(Int(fbgReading.reading)) mg/dL")
                                        .font(.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.surface)
                            )
                        } else {
                            // Show missing FBG with add button
                            HStack(spacing: 12) {
                                Image(systemName: "circle")
                                    .font(.title3)
                                    .foregroundColor(colors.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(colors.text)
                                    
                                    Text("No FBG reading")
                                        .font(.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Button(action: onAddFBG) {
                                    Text("Add FBG")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(colors.primary)
                                        )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.surface.opacity(0.5))
                            )
                        }
                    }
                }
            }
        }
    }
}
