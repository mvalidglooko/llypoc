//
//  ConsentFlowView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

struct ConsentFlowView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    let isFirstTimeUser: Bool
    @State private var currentStep = 0
    @State private var acceptedConsents: Set<ConsentType> = []
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    
    private let consentSteps = ConsentType.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress Header
                    VStack(spacing: 16) {
                        // Progress Bar
                        ProgressView(value: Double(currentStep + 1), total: Double(consentSteps.count))
                            .progressViewStyle(LinearProgressViewStyle(tint: themeManager.colors.primary))
                            .scaleEffect(y: 2)
                        
                        // Step Counter
                        HStack {
                            Text("Step \(currentStep + 1) of \(consentSteps.count)")
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                            
                            Spacer()
                            
                            Text("\(Int((Double(currentStep + 1) / Double(consentSteps.count)) * 100))%")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.colors.primary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Current Consent Step
                            if currentStep < consentSteps.count {
                                ConsentStepView(
                                    consent: consentSteps[currentStep],
                                    isAccepted: acceptedConsents.contains(consentSteps[currentStep]),
                                    colors: themeManager.colors,
                                    onToggle: { isAccepted in
                                        if isAccepted {
                                            acceptedConsents.insert(consentSteps[currentStep])
                                        } else {
                                            acceptedConsents.remove(consentSteps[currentStep])
                                        }
                                    },
                                    onViewPolicy: {
                                        if consentSteps[currentStep] == .privacyPolicy {
                                            showPrivacyPolicy = true
                                        } else if consentSteps[currentStep] == .termsOfService {
                                            showTermsOfService = true
                                        }
                                    }
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
                                Text(currentStep == consentSteps.count - 1 ? "Complete Setup" : "Next")
                                    .fontWeight(.semibold)
                                
                                if currentStep < consentSteps.count - 1 {
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
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
                        .disabled(!canProceed)
                        .animation(.easeInOut(duration: 0.2), value: canProceed)
                        
                        // Back Button
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep -= 1
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isFirstTimeUser {
                        Button("Skip") {
                            dismiss()
                        }
                        .foregroundColor(themeManager.colors.primary)
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
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private var canProceed: Bool {
        acceptedConsents.contains(consentSteps[currentStep])
    }
    
    private func nextStep() {
        if currentStep < consentSteps.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            authManager.completeConsent()
            dismiss()
        }
    }
}

struct ConsentStepView: View {
    let consent: ConsentType
    let isAccepted: Bool
    let colors: AppColors
    let onToggle: (Bool) -> Void
    let onViewPolicy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: consent.icon)
                        .font(.title2)
                        .foregroundColor(colors.primary)
                    
                    Text(consent.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                }
                
                Text(consent.description)
                    .font(.subheadline)
                    .foregroundColor(colors.textSecondary)
                    .lineLimit(nil)
            }
            
            // Content
            ScrollView {
                Text(consent.content)
                    .font(.body)
                    .foregroundColor(colors.text)
                    .lineLimit(nil)
            }
            .frame(maxHeight: 200)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(colors.border, lineWidth: 1)
                    )
            )
            
            // Action Buttons
            VStack(spacing: 12) {
                if consent.hasPolicy {
                    Button(action: onViewPolicy) {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.caption)
                            
                            Text("View \(consent.policyTitle)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(colors.primary)
                        .padding(.vertical, 8)
                    }
                }
                
                // Accept Toggle
                HStack {
                    Button(action: { onToggle(!isAccepted) }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isAccepted ? colors.primary : colors.border)
                                    .frame(width: 24, height: 24)
                                
                                if isAccepted {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text("I accept the \(consent.title.lowercased())")
                                .font(.subheadline)
                                .foregroundColor(colors.text)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Consent Types
enum ConsentType: CaseIterable {
    case privacyPolicy
    case termsOfService
    
    var title: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        }
    }
    
    var description: String {
        switch self {
        case .privacyPolicy:
            return "Learn how we protect and handle your personal information."
        case .termsOfService:
            return "Understand the terms and conditions for using the Efsitora app."
        }
    }
    
    var content: String {
        switch self {
        case .privacyPolicy:
            return """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
            
            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.
            
            Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.
            
            Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem.
            """
        case .termsOfService:
            return """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam auctor, nisl eget ultricies tincidunt, nisl nisl aliquam nisl, eget aliquam nisl nisl sit amet nisl. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
            
            Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
            
            Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.
            
            Totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit.
            
            Sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.
            """
        }
    }
    
    var icon: String {
        switch self {
        case .privacyPolicy: return "lock.shield.fill"
        case .termsOfService: return "doc.text.fill"
        }
    }
    
    var hasPolicy: Bool {
        switch self {
        case .privacyPolicy, .termsOfService: return true
        default: return false
        }
    }
    
    var policyTitle: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfService: return "Terms of Service"
        default: return ""
        }
    }
}

// MARK: - Policy Views
struct PrivacyPolicyView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("Last updated: \(Date(), formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                    
                    Group {
                        Text("Lorem Ipsum Dolor")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Sit Amet Consectetur")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Adipiscing Elit Sed")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.")
                            .foregroundColor(themeManager.colors.text)
                    }
                }
                .padding(24)
            }
            .background(themeManager.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.colors.primary)
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

struct TermsOfServiceView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.colors.text)
                    
                    Text("Last updated: \(Date(), formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(themeManager.colors.textSecondary)
                    
                    Group {
                        Text("Lorem Ipsum Dolor")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.")
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Sit Amet Consectetur")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Adipiscing Elit Sed")
                            .font(.headline)
                            .foregroundColor(themeManager.colors.text)
                        
                        Text("Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.")
                            .foregroundColor(themeManager.colors.text)
                    }
                }
                .padding(24)
            }
            .background(themeManager.colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.colors.primary)
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

