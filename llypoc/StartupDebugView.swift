//
//  StartupDebugView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

struct StartupDebugView: View {
    @StateObject private var startupManager = StartupCheckManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedScenario: StartupScenario = .normal
    @State private var selectedUserType: UserType = .firstTime
    @State private var isOverriding = false
    
    enum UserType: String, CaseIterable {
        case firstTime = "First Time User"
        case returning = "Returning User"
        
        var description: String {
            switch self {
            case .firstTime:
                return "New user - will see onboarding flow"
            case .returning:
                return "Existing user - will see sign in flow"
            }
        }
        
        var icon: String {
            switch self {
            case .firstTime: return "person.badge.plus"
            case .returning: return "person.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .firstTime: return .blue
            case .returning: return .green
            }
        }
    }
    
    enum StartupScenario: String, CaseIterable {
        case normal = "Normal Flow"
        case noNetwork = "No Network Connection"
        case backendUnreachable = "Backend Unreachable"
        case appVersionOutdated = "App Version Outdated"
        case deviceIncompatible = "Device Incompatible"
        case success = "Force Success"
        case tpEnded = "Treatment Plan Ended"
        case tpNotSet = "Treatment Plan Not Set"
        
        var description: String {
            switch self {
            case .normal:
                return "Let the app perform real startup checks"
            case .noNetwork:
                return "Simulate no internet connection"
            case .backendUnreachable:
                return "Simulate server unavailable"
            case .appVersionOutdated:
                return "Simulate outdated app version"
            case .deviceIncompatible:
                return "Simulate device compatibility issue"
            case .success:
                return "Skip all checks and proceed to app"
            case .tpEnded:
                return "Simulate treatment plan ended status"
            case .tpNotSet:
                return "Simulate treatment plan not set status"
            }
        }
        
        var icon: String {
            switch self {
            case .normal: return "checkmark.circle"
            case .noNetwork: return "wifi.slash"
            case .backendUnreachable: return "cloud.slash"
            case .appVersionOutdated: return "arrow.up.circle"
            case .deviceIncompatible: return "iphone.slash"
            case .success: return "play.circle"
            case .tpEnded: return "xmark.circle"
            case .tpNotSet: return "exclamationmark.triangle"
            }
        }
        
        var color: Color {
            switch self {
            case .normal, .success: return .green
            case .noNetwork, .backendUnreachable: return .red
            case .appVersionOutdated: return .orange
            case .deviceIncompatible: return .red
            case .tpEnded, .tpNotSet: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "gearshape.2")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.colors.primary)
                        
                        Text("Startup Debug Panel")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.colors.text)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Scrollable Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Scenario Selection
                            VStack(spacing: 16) {
                                Text("Test Scenarios")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.colors.text)
                                
                                VStack(spacing: 12) {
                                    ForEach(StartupScenario.allCases, id: \.self) { scenario in
                                        ScenarioOptionView(
                                            scenario: scenario,
                                            isSelected: selectedScenario == scenario,
                                            colors: themeManager.colors
                                        ) {
                                            selectedScenario = scenario
                                        }
                                    }
                                }
                            }
                            
                            // User Type Selection
                            VStack(spacing: 16) {
                                Text("User Type")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.colors.text)
                                
                                VStack(spacing: 12) {
                                    ForEach(UserType.allCases, id: \.self) { userType in
                                        UserTypeOptionView(
                                            userType: userType,
                                            isSelected: selectedUserType == userType,
                                            colors: themeManager.colors
                                        ) {
                                            selectedUserType = userType
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: applyScenario) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.subheadline)
                                
                                Text("Apply Scenario")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.colors.primary)
                            )
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
    

    
    private func applyScenario() {
        isOverriding = true
        
        switch selectedUserType {
        case .firstTime:
            startupManager.selectedUserType = .firstTime
            // Ensure first time user state
            let authManager = AuthenticationManager.shared
            authManager.isAuthenticated = false
            authManager.hasCompletedConsent = false
            authManager.currentUser = nil
            
        case .returning:
            startupManager.selectedUserType = .returning
            let authManager = AuthenticationManager.shared
            authManager.isAuthenticated = false
            authManager.hasCompletedConsent = true
            authManager.currentUser = nil
        }
        
        switch selectedScenario {
        case .normal:
            // Force success immediately in debug mode
            startupManager.forceSuccess()
            
        case .noNetwork:
            // Simulate no network
            startupManager.simulateNoNetwork()
            
        case .backendUnreachable:
            // Simulate backend unreachable
            startupManager.simulateBackendUnreachable()
            
        case .appVersionOutdated:
            // Simulate app version outdated
            startupManager.simulateAppVersionOutdated()
            
        case .deviceIncompatible:
            // Simulate device incompatible
            startupManager.simulateDeviceIncompatible()
            
        case .success:
            // Force success
            startupManager.forceSuccess()
            
        case .tpEnded:
            // Simulate treatment plan ended
            startupManager.simulateTreatmentPlanEnded()
        case .tpNotSet:
            // Simulate treatment plan not set
            startupManager.simulateTreatmentPlanNotSet()
        }

        // Dismiss the debug panel
        dismiss()
    }
    

}

struct ScenarioOptionView: View {
    let scenario: StartupDebugView.StartupScenario
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: scenario.icon)
                    .font(.title2)
                    .foregroundColor(scenario.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colors.text)
                    
                    Text(scenario.description)
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

struct UserTypeOptionView: View {
    let userType: StartupDebugView.UserType
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: userType.icon)
                    .font(.title2)
                    .foregroundColor(userType.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(userType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colors.text)
                    
                    Text(userType.description)
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
