//
//  ReturningUserFlow.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

extension Notification.Name {
    static let syncCompleted = Notification.Name("syncCompleted")
}

struct ReturningUserFlow: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var startupManager = StartupCheckManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: ReturningUserStep = .sync
    @State private var hasAcceptedTerms = false
    @State private var showTermsOfService = false
    @State private var showTreatmentPlanUpdate = false
    @State private var showTimezoneChange = false
    @State private var isLoading = false
    
    enum ReturningUserStep {
        case sync
        case termsAndConditions
        case treatmentPlanCheck
        case timezoneChange
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
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
                            case .sync:
                                SyncView(
                                    colors: themeManager.colors
                                )
                                
                            case .termsAndConditions:
                                TermsAndConditionsConsentView(
                                    hasAcceptedTerms: $hasAcceptedTerms,
                                    showTermsOfService: $showTermsOfService,
                                    colors: themeManager.colors
                                )
                                
                                                        case .treatmentPlanCheck:
                                TreatmentPlanCheckView(
                                    treatmentPlanStatus: startupManager.treatmentPlanStatus,
                                    showTreatmentPlanUpdate: $showTreatmentPlanUpdate,
                                    colors: themeManager.colors
                                )
                                
                            case .timezoneChange:
                                TimezoneChangeScreenView(
                                    colors: themeManager.colors
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                    }
                    
                    // Navigation Buttons
                    if currentStep != .sync {
                        VStack(spacing: 12) {
                            Button(action: {
                                if currentStep == .treatmentPlanCheck && startupManager.treatmentPlanStatus == .notSet {
                                    authManager.signOut()
                                    dismiss()
                                } else {
                                    nextStep()
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(buttonText)
                                            .fontWeight(.semibold)
                                        
                                        if currentStep != .timezoneChange && !(currentStep == .treatmentPlanCheck && startupManager.treatmentPlanStatus == .notSet) {
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
                        if currentStep != .termsAndConditions {
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
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showTreatmentPlanUpdate) {
            TreatmentPlanUpdateView(colors: themeManager.colors)
        }


        .preferredColorScheme(themeManager.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .syncCompleted)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = .termsAndConditions
            }
        }
    }
    
    private var progressValue: Double {
        switch currentStep {
        case .sync: return 1.0
        case .termsAndConditions: return 2.0
        case .treatmentPlanCheck: return 3.0
        case .timezoneChange: return 4.0
        }
    }
    
    private var currentStepNumber: Int {
        switch currentStep {
        case .sync: return 1
        case .termsAndConditions: return 2
        case .treatmentPlanCheck: return 3
        case .timezoneChange: return 4
        }
    }
    
    private var stepTitle: String {
        switch currentStep {
        case .sync: return "Syncing Data"
        case .termsAndConditions: return "Terms & Conditions"
        case .treatmentPlanCheck: return "Treatment Plan"
        case .timezoneChange: return "Timezone Change"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .sync:
            return false
        case .termsAndConditions:
            return hasAcceptedTerms
        case .treatmentPlanCheck:
            return true
        case .timezoneChange:
            return true
        }
    }
    
    private var buttonText: String {
        switch currentStep {
        case .sync:
            return "Next"
        case .termsAndConditions:
            return "Next"
        case .treatmentPlanCheck:
            if startupManager.treatmentPlanStatus == .notSet {
                return "Ok"
            } else {
                return "Next"
            }
        case .timezoneChange:
            return "Continue to App"
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .sync:
            break
            
        case .termsAndConditions:
            if hasAcceptedTerms {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .treatmentPlanCheck
                }
            }
            
        case .treatmentPlanCheck:
            if startupManager.treatmentPlanStatus == .ended {
                authManager.signOut()
                dismiss()
            } else if startupManager.treatmentPlanStatus == .notSet {
                // Show treatment plan not set screen
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = .timezoneChange
                }
            }
            
        case .timezoneChange:
            authManager.isAuthenticated = true
            dismiss()
            

        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .sync:
            break
        case .termsAndConditions:
            currentStep = .sync
        case .treatmentPlanCheck:
            currentStep = .termsAndConditions
        case .timezoneChange:
            currentStep = .treatmentPlanCheck
        }
    }
}



// MARK: - Treatment Plan Check View
struct TreatmentPlanCheckView: View {
    let treatmentPlanStatus: StartupCheckManager.TreatmentPlanStatus
    @Binding var showTreatmentPlanUpdate: Bool
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            switch treatmentPlanStatus {
            case .ended:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.error)
                
                VStack(spacing: 12) {
                    Text("Treatment Plan Ended")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                    
                    Text("Your treatment plan has ended. Please contact your healthcare provider to discuss next steps.")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
            case .updated:
                VStack(spacing: 24) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(colors.warning)
                    
                    VStack(spacing: 12) {
                        Text("Treatment Plan Updated")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colors.text)
                        
                        Text("Your healthcare provider has updated your treatment plan. Here are the key changes:")
                            .font(.subheadline)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 16) {
                        UpdateItemView(
                            icon: "syringe.fill",
                            title: "Dose Adjustment",
                            description: "Your weekly dose has been adjusted from 0.5mg to 0.75mg based on recent readings",
                            colors: colors
                        )
                        
                        UpdateItemView(
                            icon: "calendar",
                            title: "Schedule Change",
                            description: "Your dosing schedule has been updated to every 7 days instead of every 5 days",
                            colors: colors
                        )
                        
                        UpdateItemView(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Target Range Update",
                            description: "Your target blood glucose range has been adjusted to 80-140 mg/dL",
                            colors: colors
                        )
                    }
                }
                
            case .active:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.success)
                
                VStack(spacing: 12) {
                    Text("Treatment Plan Active")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                    
                    Text("Your treatment plan is active and up to date.")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
            case .notSet:
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(colors.warning)
                
                VStack(spacing: 12) {
                    Text("Treatment Plan Not Set")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                    
                    Text("Your treatment plan has not been set up yet. Please contact your healthcare provider to establish your treatment plan.")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Timezone Check View
struct TimezoneCheckView: View {
    @Binding var showTimezoneChange: Bool
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(colors.primary)
            
            VStack(spacing: 12) {
                Text("Timezone Check")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("Checking if your timezone has changed since your last visit...")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Complete Returning User View
struct CompleteReturningUserView: View {
    let colors: AppColors
    
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
                Text("Welcome Back!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("You're all set to continue managing your diabetes with Efsitora.")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Treatment Plan Update View
struct TreatmentPlanUpdateView: View {
    let colors: AppColors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(colors.warning)
                
                VStack(spacing: 12) {
                    Text("Treatment Plan Updated")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                    
                    Text("Your healthcare provider has made changes to your treatment plan. Here are the key updates:")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    UpdateItemView(
                        icon: "syringe.fill",
                        title: "Dose Adjustment",
                        description: "Your weekly dose has been adjusted based on recent readings",
                        colors: colors
                    )
                    
                    UpdateItemView(
                        icon: "calendar",
                        title: "Schedule Change",
                        description: "Your dosing schedule has been updated",
                        colors: colors
                    )
                }
                
                Spacer()
                
                Button("Continue") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.primary)
                )
                .foregroundColor(.white)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .navigationTitle("Treatment Plan Update")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
        }
    }
}

// MARK: - Timezone Change View
struct TimezoneChangeView: View {
    let colors: AppColors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(colors.warning)
                
                VStack(spacing: 12) {
                    Text("Timezone Changed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                    
                    Text("We detected that your timezone has changed. This may affect your reminder schedules and dose timing.")
                        .font(.subheadline)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    InfoItemView(
                        icon: "bell.fill",
                        title: "Reminder Times",
                        description: "Your reminder times will be adjusted to match your new timezone",
                        colors: colors
                    )
                    
                    InfoItemView(
                        icon: "clock.fill",
                        title: "Dose Schedule",
                        description: "Your weekly dose schedule will be updated accordingly",
                        colors: colors
                    )
                }
                
                Spacer()
                
                Button("Update Schedule") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colors.primary)
                )
                .foregroundColor(.white)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .navigationTitle("Timezone Change")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(colors.primary)
                }
            }
        }
    }
}

// MARK: - Sync View
struct SyncView: View {
    let colors: AppColors
    @State private var syncProgress: Double = 0.0
    @State private var syncMessage: String = "Connecting to server..."
    
    var body: some View {
        VStack(spacing: 32) {
            // Sync Icon
            ZStack {
                Circle()
                    .fill(colors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 50))
                    .foregroundColor(colors.primary)
            }
            
            VStack(spacing: 16) {
                Text("Syncing Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("Please wait while we sync your treatment data and settings from the server.")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Text(syncMessage)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress Bar
            VStack(spacing: 8) {
                ProgressView(value: syncProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: colors.primary))
                    .scaleEffect(y: 2)
                
                Text("\(Int(syncProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colors.primary)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startSync()
        }
    }
    
    private func startSync() {
        // Simulate sync process
        let syncSteps = [
            ("Connecting to server...", 0.2),
            ("Downloading treatment data...", 0.4),
            ("Syncing settings...", 0.6),
            ("Updating local data...", 0.8),
            ("Sync complete!", 1.0)
        ]
        
        for (index, step) in syncSteps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.0) {
                syncMessage = step.0
                syncProgress = step.1
                
                if step.1 == 1.0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: .syncCompleted, object: nil)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Views
struct UpdateItemView: View {
    let icon: String
    let title: String
    let description: String
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(colors.primary)
                .frame(width: 24)
            
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

struct InfoItemView: View {
    let icon: String
    let title: String
    let description: String
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(colors.warning)
                .frame(width: 24)
            
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

// MARK: - Terms and Conditions Consent View
struct TermsAndConditionsConsentView: View {
    @Binding var hasAcceptedTerms: Bool
    @Binding var showTermsOfService: Bool
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Please review and accept the following to use the Efsitora app:")
                .font(.subheadline)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                // Privacy Policy
                ConsentItemView(
                    consent: .privacyPolicy,
                    isAccepted: hasAcceptedTerms,
                    isViewed: true,
                    colors: colors,
                    onToggle: { isAccepted in
                        hasAcceptedTerms = isAccepted
                    },
                    onViewPolicy: {
                        // Show Privacy policy
                    }
                )
                
                // Terms of Service
                ConsentItemView(
                    consent: .termsOfService,
                    isAccepted: hasAcceptedTerms,
                    isViewed: true,
                    colors: colors,
                    onToggle: { isAccepted in
                        hasAcceptedTerms = isAccepted
                    },
                    onViewPolicy: {
                        showTermsOfService = true
                    }
                )
            }
        }
    }
}


// MARK: - Timezone Change Screen View
struct TimezoneChangeScreenView: View {
    let colors: AppColors
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(colors.warning)
            
            VStack(spacing: 12) {
                Text("Timezone Has Changed")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colors.text)
                
                Text("We detected that your timezone has changed since your last visit. This may affect your treatment schedule and reminders.")
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                InfoItemView(
                    icon: "clock.arrow.circlepath",
                    title: "Timezone Change",
                    description: "From Eastern Time (ET) to Pacific Time (PT)",
                    colors: colors
                )
                
                InfoItemView(
                    icon: "calendar.badge.clock",
                    title: "Treatment Schedule Impact",
                    description: "Your weekly dose schedule will be automatically adjusted to match your new timezone",
                    colors: colors
                )
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                            .foregroundColor(colors.warning)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reminders Impact")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(colors.text)
                            
                            Text("Your reminder times will be adjusted to match your new timezone.")
                                .font(.caption)
                                .foregroundColor(colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("You can adjust your reminder times in Settings if needed.")
                                .font(.caption)
                                .foregroundColor(colors.textSecondary)
                                .padding(.top, 4)
                                .fixedSize(horizontal: false, vertical: true)
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
}
