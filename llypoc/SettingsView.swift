//
//  SettingsView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showNotificationsSettings = false
    @State private var showTreatmentPlan = false
    @State private var showReminders = false
    @State private var showMeasurementUnits = false
    @State private var showTermsOfService = false
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            // Patient Name
                            VStack(spacing: 4) {
                                Text("John Doe")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.colors.text)
                                
                                Text("Patient")
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.textSecondary)
                            }
                            .padding(.vertical, 24)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Settings List
                        VStack(spacing: 0) {
                            // Notifications
                            SettingsRow(
                                title: "Notifications",
                                subtitle: "Manage alerts and reminders",
                                icon: "bell",
                                iconColor: themeManager.colors.primary,
                                colors: themeManager.colors
                            ) {
                                showNotificationsSettings = true
                            }
                            
                            Divider()
                                .background(themeManager.colors.border)
                                .padding(.leading, 56)
                            
                            // Treatment Plan
                            SettingsRow(
                                title: "Treatment Plan",
                                subtitle: "View and manage your plan",
                                icon: "heart",
                                iconColor: themeManager.colors.primary,
                                colors: themeManager.colors
                            ) {
                                showTreatmentPlan = true
                            }
                            
                            Divider()
                                .background(themeManager.colors.border)
                                .padding(.leading, 56)
                            
                            // Reminders
                            SettingsRow(
                                title: "Reminders",
                                subtitle: "Set up dose and reading reminders",
                                icon: "clock",
                                iconColor: themeManager.colors.primary,
                                colors: themeManager.colors
                            ) {
                                showReminders = true
                            }
                            
                            Divider()
                                .background(themeManager.colors.border)
                                .padding(.leading, 56)
                            
                            // Measurement Unit Preferences
                            SettingsRow(
                                title: "Measurement Units",
                                subtitle: "mg/dL or mmol/L",
                                icon: "ruler",
                                iconColor: themeManager.colors.primary,
                                colors: themeManager.colors
                            ) {
                                showMeasurementUnits = true
                            }
                            
                            Divider()
                                .background(themeManager.colors.border)
                                .padding(.leading, 56)
                            
                            // Terms and Conditions
                            SettingsRow(
                                title: "Terms and Conditions",
                                subtitle: "Read our terms of service",
                                icon: "doc.text",
                                iconColor: themeManager.colors.primary,
                                colors: themeManager.colors
                            ) {
                                showTermsOfService = true
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(themeManager.colors.surface)
                                .shadow(color: themeManager.colors.shadow, radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Sign Out Button
                        VStack(spacing: 16) {
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18))
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("Sign Out")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeManager.colors.text)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(themeManager.colorScheme)
        }
        .sheet(isPresented: $showNotificationsSettings) {
            NotificationsSettingsView(colors: themeManager.colors)
        }
        .sheet(isPresented: $showTreatmentPlan) {
            TreatmentPlanView(colors: themeManager.colors)
        }
        .sheet(isPresented: $showReminders) {
            RemindersSettingsView(colors: themeManager.colors)
        }
        .sheet(isPresented: $showMeasurementUnits) {
            MeasurementUnitsView(colors: themeManager.colors)
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsAndConditionsSettingsView(colors: themeManager.colors)
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out? You'll need to sign in again to access your data.")
        }
    }
    
    private func signOut() {
        authManager.isAuthenticated = false
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(colors.text)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(colors.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Notifications Settings View
struct NotificationsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let colors: AppColors
    
    @State private var notificationsEnabled = false
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Notification Status Card
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(notificationsEnabled ? .green : .red)
                                    .frame(width: 32, height: 32)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Notifications")
                                        .font(.headline)
                                        .foregroundColor(colors.text)
                                    
                                    Text(notificationsEnabled ? "Enabled" : "Disabled")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(notificationsEnabled ? .green : .red)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colors.surface)
                            )
                            
                            // Description
                            Text(notificationsEnabled ?
                                 "You'll receive reminders for doses, readings, and important updates." :
                                 "Enable notifications to get important reminders and updates about your treatment.")
                                .font(.body)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        
                        // Settings Link
                        VStack(spacing: 16) {
                            Button(action: {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "gear")
                                        .font(.system(size: 18))
                                        .foregroundColor(colors.primary)
                                    
                                    Text("Open Settings")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(colors.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(colors.primary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colors.primary.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Text("Tap to change notification settings in your device settings")
                                .font(.caption)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkNotificationStatus()
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
}

// MARK: - Treatment Plan View
struct TreatmentPlanView: View {
    @Environment(\.dismiss) private var dismiss
    let colors: AppColors
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            InfoCard(
                                title: "Target Range",
                                subtitle: "80-120 mg/dL",
                                description: "Your target blood glucose range for optimal diabetes management.",
                                icon: "target",
                                iconColor: colors.primary,
                                colors: colors
                            )
                            
                            InfoCard(
                                title: "Dose Day",
                                subtitle: "Every Monday",
                                description: "Your weekly insulin dose is scheduled for every Monday at 7:30 AM.",
                                icon: "calendar.circle.fill",
                                iconColor: colors.primary,
                                colors: colors
                            )
                            
                            InfoCard(
                                title: "Treatment Plan Status",
                                subtitle: "Active",
                                description: "Last updated: December 15, 2024 - Dose amount adjusted from 280 to 300 units based on recent FBG readings.",
                                icon: "checkmark.circle.fill",
                                iconColor: .green,
                                colors: colors
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                }
            }
            .navigationTitle("Treatment Plan")
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

// MARK: - Reminders Settings View
struct RemindersSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let colors: AppColors
    
    @State private var fbgReminderTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var doseReminderTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date()
    @State private var currentStep: ReminderStep = .fbg
    @State private var showValidationError = false
    
    enum ReminderStep {
        case fbg, dose
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    switch currentStep {
                    case .fbg:
                        FBGReminderSettingsView(
                            fbgTime: $fbgReminderTime,
                            colors: colors
                        )
                    case .dose:
                        DoseReminderSettingsView(
                            doseTime: $doseReminderTime,
                            fbgTime: fbgReminderTime,
                            colors: colors,
                            showValidationError: $showValidationError
                        )
                    }
                    
                    Spacer()
                    
                    // Navigation Buttons
                    VStack(spacing: 12) {
                        // Next/Save Button
                        Button(currentStep == .fbg ? "Next" : "Save") {
                            if currentStep == .fbg {
                                currentStep = .dose
                            } else {
                                dismiss()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill((currentStep == .dose && showValidationError) ? colors.border : colors.primary)
                        )
                        .foregroundColor(.white)
                        .disabled(currentStep == .dose && showValidationError)
                        .animation(.easeInOut(duration: 0.2), value: currentStep == .dose && showValidationError)
                        
                        // Back Button
                        if currentStep == .dose {
                            Button("Back") {
                                currentStep = .fbg
                            }
                            .font(.subheadline)
                            .foregroundColor(colors.textSecondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - FBG Reminder Settings View
struct FBGReminderSettingsView: View {
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
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }
}

// MARK: - Dose Reminder Settings View
struct DoseReminderSettingsView: View {
    @Binding var doseTime: Date
    let fbgTime: Date
    let colors: AppColors
    @Binding var showValidationError: Bool
    
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
        .padding(.horizontal, 24)
        .padding(.top, 40)
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



// MARK: - Measurement Units View
struct MeasurementUnitsView: View {
    @Environment(\.dismiss) private var dismiss
    let colors: AppColors
    
    @State private var selectedUnit: MeasurementUnit = .mgdL
    
    enum MeasurementUnit: String, CaseIterable {
        case mgdL = "mg/dL"
        case mmolL = "mmol/L"
        
        var description: String {
            switch self {
            case .mgdL:
                return "Milligrams per deciliter (US standard)"
            case .mmolL:
                return "Millimoles per liter (International standard)"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                                Button(action: {
                                    selectedUnit = unit
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(unit.rawValue)
                                                .font(.headline)
                                                .foregroundColor(colors.text)
                                            
                                            Text(unit.description)
                                                .font(.caption)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedUnit == unit {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(colors.primary)
                                        } else {
                                            Circle()
                                                .stroke(colors.border, lineWidth: 2)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedUnit == unit ? colors.primary.opacity(0.1) : colors.surface)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                }
            }
            .navigationTitle("Measurement Units")
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

// MARK: - Helper Views
struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let colors: AppColors
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(colors.text)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surface)
        )
    }
}

struct InfoCard: View {
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let iconColor: Color
    let colors: AppColors
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colors.text)
                
                Text(subtitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colors.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.surface)
        )
    }
}


// MARK: - Terms and Conditions Settings View
struct TermsAndConditionsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let colors: AppColors
    
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        // Privacy Policy
                        ConsentItemSettingsView(
                            title: "Privacy Policy",
                            description: "Learn how we protect and handle your personal information.",
                            colors: colors,
                            onViewPolicy: {
                                showPrivacyPolicy = true
                            }
                        )
                        
                        // Terms of Service
                        ConsentItemSettingsView(
                            title: "Terms of Service",
                            description: "Understand the terms and conditions for using the Efsitora app.",
                            colors: colors,
                            onViewPolicy: {
                                showTermsOfService = true
                            }
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Terms & Conditions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
    }
}

// MARK: - Consent Item Settings View
struct ConsentItemSettingsView: View {
    let title: String
    let description: String
    let colors: AppColors
    let onViewPolicy: () -> Void
    
    var body: some View {
        HStack {
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
            
            Button(action: onViewPolicy) {
                Image(systemName: "doc.text")
                    .font(.caption)
                    .foregroundColor(colors.primary)
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
 

