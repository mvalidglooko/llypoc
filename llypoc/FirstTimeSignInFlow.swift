//
//  FirstTimeSignInFlow.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

struct FirstTimeSignInFlow: View {
    // MARK: - Helper Functions
    private static func createDefaultFBGTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 0
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }
    
    private static func createDefaultDoseTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 7
        components.minute = 30
        components.second = 0
        return calendar.date(from: components) ?? Date()
    }
    
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: FlowStep = .consent
    @State private var acceptedConsents: Set<ConsentType> = []
    @State private var viewedConsents: Set<ConsentType> = []
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var notificationsEnabled = false
    @State private var bgUnits: BGUnits = .mgdL
    @State private var hmiTime = Self.createDefaultFBGTime()
    @State private var doseTime = Self.createDefaultDoseTime()
    @State private var isLoading = false
    @State private var toastMessage: ToastMessage?
    @State private var showDoseInjectionFlow = false
    
    // Country-based BG units configuration
    @State private var userCountry = "US"
    private let countriesWithUnitSelection = ["US", "UK", "AU", "NZ"] // Countries that can choose units (Canada excluded)
    private let defaultBGUnits: [String: BGUnits] = [
        "US": .mgdL,
        "CA": .mmolL, // Canada uses mmol/L and can't change
        "UK": .mmolL,
        "AU": .mmolL,
        "NZ": .mmolL
    ]
    
    private let consentSteps = ConsentType.allCases
    
    enum FlowStep {
        case consent
        case fbgReminder
        case doseReminder
        case notificationPermissions
        case bgUnits
        case complete
    }
    
    private var canSelectBGUnits: Bool {
        return countriesWithUnitSelection.contains(userCountry)
    }
    
    private var userBGUnits: BGUnits {
        return defaultBGUnits[userCountry] ?? .mgdL
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
        ProgressView(value: progressValue, total: canSelectBGUnits ? 5.0 : 4.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                            .scaleEffect(y: 2)
                        
                        // Step Counter
                        HStack {
                            Text("Step \(currentStepNumber) of \(canSelectBGUnits ? 5 : 4)")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                            
                            Spacer()
                            
                            #if DEBUG
                            Button(action: {
                                userCountry = userCountry == "US" ? "CA" : "US"
                            }) {
                                Text(userCountry)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(themeManager.colors.primary.opacity(0.1))
                                    )
                                    .foregroundColor(themeManager.colors.primary)
                            }
                            #endif
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
                            case .consent:
                                FirstTimeConsentStepView(
                                    acceptedConsents: $acceptedConsents,
                                    viewedConsents: $viewedConsents,
                                    showPrivacyPolicy: $showPrivacyPolicy,
                                    showTermsOfService: $showTermsOfService,
                                    colors: themeManager.colors
                                )
                                
                            case .fbgReminder:
                                FBGReminderView(
                                    fbgTime: $hmiTime,
                                    colors: themeManager.colors
                                )
                                
                            case .doseReminder:
                                DoseReminderView(
                                    doseTime: $doseTime,
                                    fbgTime: hmiTime,
                                    colors: themeManager.colors
                                )
                                
                            case .notificationPermissions:
                                NotificationPermissionsView(
                                    notificationsEnabled: $notificationsEnabled,
                                    colors: themeManager.colors
                                )
                                
                            case .bgUnits:
                                if canSelectBGUnits {
                                    BGUnitsView(
                                        bgUnits: $bgUnits,
                                        colors: themeManager.colors
                                    )
                                } else {
                                    // Show auto-set view for countries that can't choose
                                    BGUnitsAutoSetView(
                                        bgUnits: userBGUnits,
                                        country: userCountry,
                                        colors: themeManager.colors
                                    )
                                }
                                
                            case .complete:
                                CompleteSetupView(
                                    colors: themeManager.colors,
                                    canSelectUnits: canSelectBGUnits
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    }
                    
                    // Navigation Buttons
                    VStack(spacing: 12) {
                        Button(action: nextStep) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(currentStep == .complete ? "Get Started" : "Next")
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
                        
                        // Back Button
                        if currentStep != .consent {
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
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .fullScreenCover(isPresented: $showDoseInjectionFlow) {
            LogInsulinFlowView(bypassStarterDoseQuestion: false, isFromOnboarding: true)
        }
        .toast($toastMessage, colors: themeManager.colors)
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private var progressValue: Double {
        let totalSteps = canSelectBGUnits ? 5.0 : 4.0
        
        switch currentStep {
        case .consent: return 1.0
        case .fbgReminder: return 2.0
        case .doseReminder: return 3.0
        case .notificationPermissions: return canSelectBGUnits ? 4.0 : 4.0
        case .bgUnits: return 5.0
        case .complete: return totalSteps
        }
    }
    
    private var currentStepNumber: Int {
        let totalSteps = canSelectBGUnits ? 5 : 4
        
        switch currentStep {
        case .consent: return 1
        case .fbgReminder: return 2
        case .doseReminder: return 3
        case .notificationPermissions: return canSelectBGUnits ? 4 : 4
        case .bgUnits: return 5
        case .complete: return totalSteps
        }
    }
    
    private var stepTitle: String {
        switch currentStep {
        case .consent: return "Consent & Privacy"
        case .fbgReminder: return "Fasting Blood Glucose Reminder"
        case .doseReminder: return "Dose Reminder"
        case .notificationPermissions: return "Notifications"
        case .bgUnits: return "Blood Glucose Units"
        case .complete: return "Setup Complete"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .consent:
            return acceptedConsents.count == consentSteps.count && viewedConsents.count == consentSteps.count
        case .fbgReminder:
            return true
        case .doseReminder:
            let calendar = Calendar.current
            let fbgComponents = calendar.dateComponents([.hour, .minute], from: hmiTime)
            let doseComponents = calendar.dateComponents([.hour, .minute], from: doseTime)
            
            let fbgMinutes = (fbgComponents.hour ?? 0) * 60 + (fbgComponents.minute ?? 0)
            let doseMinutes = (doseComponents.hour ?? 0) * 60 + (doseComponents.minute ?? 0)
            
            return doseMinutes > fbgMinutes
        case .notificationPermissions:
            return true
        case .bgUnits:
            return true
        case .complete:
            return true
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .consent:
            if acceptedConsents.count == consentSteps.count {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .fbgReminder
                }
            }
            
        case .fbgReminder:
            // Save FBG reminder time
            saveFBGTime()
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .doseReminder
            }
            
        case .doseReminder:
            // Save dose reminder time
            saveDoseTime()
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .notificationPermissions
            }
            
        case .notificationPermissions:
            // Save notification preferences
            saveNotificationPreferences()
            withAnimation(.easeInOut(duration: 0.3)) {
                if canSelectBGUnits {
                    currentStep = .bgUnits
                } else {
                    bgUnits = userBGUnits
                    saveBGUnitsPreference()
                    currentStep = .complete
                }
            }
            
        case .bgUnits:
            saveBGUnitsPreference()
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .complete
            }
            
        case .complete:
            completeSetup()
        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .consent:
            break
        case .fbgReminder:
            currentStep = .consent
        case .doseReminder:
            currentStep = .fbgReminder
        case .notificationPermissions:
            currentStep = .doseReminder
        case .bgUnits:
            currentStep = .notificationPermissions
        case .complete:
            if canSelectBGUnits {
                currentStep = .bgUnits
            } else {
                currentStep = .notificationPermissions
            }
        }
    }
    
    private func saveNotificationPreferences() {
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        
        if notificationsEnabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                DispatchQueue.main.async {
                    if !granted {
                        self.toastMessage = ToastMessage("Notification permission denied. You can enable it later in Settings.", type: .warning)
                    }
                }
            }
        }
    }
    
    private func saveBGUnitsPreference() {
        UserDefaults.standard.set(bgUnits.rawValue, forKey: "bgUnits")
    }
    
    private func saveFBGTime() {
        UserDefaults.standard.set(hmiTime, forKey: "fbgReminderTime")
    }
    
    private func saveDoseTime() {
        UserDefaults.standard.set(doseTime, forKey: "doseReminderTime")
    }
    
    private func completeSetup() {
        isLoading = true
        
        // Simulate API call to complete setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            authManager.completeConsent()
            
            showDoseInjectionFlow = true
        }
    }
}

// MARK: - First Time Consent Step View
struct FirstTimeConsentStepView: View {
    @Binding var acceptedConsents: Set<ConsentType>
    @Binding var viewedConsents: Set<ConsentType>
    @Binding var showPrivacyPolicy: Bool
    @Binding var showTermsOfService: Bool
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Please review and accept the following to use the Efsitora app:")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
                                    VStack(spacing: 16) {
                            ForEach(ConsentType.allCases, id: \.self) { consent in
                                ConsentItemView(
                                    consent: consent,
                                    isAccepted: acceptedConsents.contains(consent),
                                    isViewed: viewedConsents.contains(consent),
                                    colors: colors,
                                    onToggle: { isAccepted in
                                        if isAccepted {
                                            // Only allow acceptance if viewed
                                            if viewedConsents.contains(consent) {
                                                acceptedConsents.insert(consent)
                                            }
                                        } else {
                                            acceptedConsents.remove(consent)
                                        }
                                    },
                                    onViewPolicy: {
                                        // Mark as viewed when PDF is opened
                                        viewedConsents.insert(consent)
                                        if consent == .privacyPolicy {
                                            showPrivacyPolicy = true
                                        } else if consent == .termsOfService {
                                            showTermsOfService = true
                                        }
                                    }
                                )
                            }
                        }
        }
    }
}

struct ConsentItemView: View {
    let consent: ConsentType
    let isAccepted: Bool
    let isViewed: Bool
    let colors: AppColors
    let onToggle: (Bool) -> Void
    let onViewPolicy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: { onToggle(!isAccepted) }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isAccepted ? colors.primary : (isViewed ? colors.border : colors.warning.opacity(0.3)))
                                .frame(width: 24, height: 24)
                            
                            if isAccepted {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else if !isViewed {
                                Image(systemName: "eye.slash")
                                    .font(.caption)
                                    .foregroundColor(colors.warning)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(consent.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(colors.text)
                                
                                if !isViewed {
                                    Text("(Must view first)")
                                        .font(.caption)
                                        .foregroundColor(colors.warning)
                                }
                            }
                            
                            Text(consent.description)
                                .font(.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                if consent.hasPolicy {
                    Button(action: onViewPolicy) {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundColor(colors.primary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surface)
                .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Notification Permissions View
struct NotificationPermissionsView: View {
    @Binding var notificationsEnabled: Bool
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
            
            VStack(spacing: 12) {
                Text("Stay Updated")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("Enable notifications to receive important reminders about your diabetes management, including dose reminders and health tips.")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                NotificationOptionView(
                    title: "Enable Notifications",
                    description: "Receive dose reminders and health updates",
                    icon: "bell.fill",
                    isSelected: notificationsEnabled,
                    colors: colors
                ) {
                    notificationsEnabled = true
                }
                
                NotificationOptionView(
                    title: "Skip for Now",
                    description: "You can enable notifications later in Settings",
                    icon: "bell.slash.fill",
                    isSelected: !notificationsEnabled,
                    colors: colors
                ) {
                    notificationsEnabled = false
                }
            }
        }
    }
}

struct NotificationOptionView: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? colors.primary.opacity(0.1) : colors.border)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? colors.primary : colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colors.text)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(colors.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? colors.primary : colors.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - BG Units View
struct BGUnitsView: View {
    @Binding var bgUnits: BGUnits
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "drop.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
            
            VStack(spacing: 12) {
                Text("Choose your preferred units for blood glucose readings. You can change this later in Settings.")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                UnitsOptionView(
                    title: "mg/dL",
                    description: "Milligrams per deciliter (US standard)",
                    example: "120 mg/dL",
                    isSelected: bgUnits == .mgdL,
                    colors: colors
                ) {
                    bgUnits = .mgdL
                }
                
                UnitsOptionView(
                    title: "mmol/L",
                    description: "Millimoles per liter (International standard)",
                    example: "6.7 mmol/L",
                    isSelected: bgUnits == .mmolL,
                    colors: colors
                ) {
                    bgUnits = .mmolL
                }
            }
        }
    }
}

struct UnitsOptionView: View {
    let title: String
    let description: String
    let example: String
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colors.text)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                    
                    Text(example)
                        .font(.caption)
                        .foregroundColor(colors.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(colors.primary.opacity(0.1))
                        )
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(colors.primary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? colors.primary : colors.border, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - FBG Reminder View
struct FBGReminderView: View {
    @Binding var fbgTime: Date
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "drop.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
            
            VStack(spacing: 12) {
                Text("Set your preferred time to receive reminders for taking your fasting blood glucose readings.")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                TimePickerView(
                    title: "FBG Reminder Time",
                    description: "When you prefer to check your fasting blood glucose",
                    time: $fbgTime,
                    colors: colors
                )
            }
        }
    }
}

// MARK: - Dose Reminder View
struct DoseReminderView: View {
    @Binding var doseTime: Date
    let fbgTime: Date
    let colors: AppColors
    @State private var showValidationError = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "syringe.fill")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
            
            VStack(spacing: 12) {
                Text("Set your preferred time to receive reminders for taking your weekly insulin dose.")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                TimePickerView(
                    title: "Dose Reminder Time",
                    description: "When you typically take your medication",
                    time: $doseTime,
                    colors: colors
                )
                
                // Validation Error Message
                if showValidationError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(colors.error)
                            .font(.caption)
                        
                        Text("Dose reminder must be after FBG reminder. Please adjust the time or go back to change your FBG reminder time.")
                            .font(.caption)
                            .foregroundColor(colors.error)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .onChange(of: doseTime) { _ in
            validateTimes()
        }
        .onAppear {
            validateTimes()
        }
    }
    
    private func validateTimes() {
        let calendar = Calendar.current
        let fbgComponents = calendar.dateComponents([.hour, .minute], from: fbgTime)
        let doseComponents = calendar.dateComponents([.hour, .minute], from: doseTime)
        
        let fbgMinutes = (fbgComponents.hour ?? 0) * 60 + (fbgComponents.minute ?? 0)
        let doseMinutes = (doseComponents.hour ?? 0) * 60 + (doseComponents.minute ?? 0)
        
        showValidationError = doseMinutes <= fbgMinutes
    }
}
    

struct TimePickerView: View {
    let title: String
    let description: String
    @Binding var time: Date
    let colors: AppColors
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colors.text)
            
            Text(description)
                .font(.caption)
                .foregroundColor(colors.textSecondary)
            
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colors.border, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - BG Units Auto-Set View
struct BGUnitsAutoSetView: View {
    let bgUnits: BGUnits
    let country: String
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
            
            VStack(spacing: 12) {
                Text("Blood Glucose Units Set")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("Based on your location (\(country)), your blood glucose units have been automatically set to \(bgUnits.displayName).")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(colors.success)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Units: \(bgUnits.displayName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colors.text)
                        
                        Text("This is the standard unit used in your region")
                            .font(.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colors.border, lineWidth: 1)
                        )
                )
            }
        }
    }
}

// MARK: - Complete Setup View
struct CompleteSetupView: View {
    let colors: AppColors
    let canSelectUnits: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(colors.success.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(colors.success)
            }
            
            VStack(spacing: 12) {
                Text("You're all set to start managing your diabetes with Efsitora. Your preferences have been saved and you can change them anytime in Settings.")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "heart.fill",
                    title: "Personalized Care",
                    description: "Your preferences are saved",
                    colors: colors
                )
                
                FeatureRow(
                    icon: "bell.fill",
                    title: "Smart Reminders",
                    description: "Get notified at your preferred times",
                    colors: colors
                )
                
                if canSelectUnits {
                    FeatureRow(
                        icon: "drop.fill",
                        title: "Your Units",
                        description: "Use familiar measurement units",
                        colors: colors
                    )
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colors.text)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colors.surface)
        )
    }
}

// MARK: - BG Units Enum
enum BGUnits: String, CaseIterable {
    case mgdL = "mg/dL"
    case mmolL = "mmol/L"
    
    var displayName: String {
        switch self {
        case .mgdL: return "mg/dL"
        case .mmolL: return "mmol/L"
        }
    }
}
