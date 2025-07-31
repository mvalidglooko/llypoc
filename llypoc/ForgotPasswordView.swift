//
//  ForgotPasswordView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var emailError: String?
    @State private var toastMessage: ToastMessage?
    @State private var hasAttemptedValidation = false
    @State private var showSuccessState = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "lock.rotation")
                                .font(.system(size: 60))
                                .foregroundColor(themeManager.colors.primary)
                            
                            Text("Forgot Password?")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.text)
                            
                            Text("Enter your email address and we'll send you a link to reset your password.")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 40)
                        
                        if !showSuccessState {
                            // Email Input Form
                            VStack(spacing: 20) {
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    TextField("Enter your email", text: $email)
                                        .textFieldStyle(CustomTextFieldStyle(
                                            colors: themeManager.colors,
                                            hasError: emailError != nil
                                        ))
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .onChange(of: email) { _ in
                                            validateEmail()
                                        }
                                    
                                    if let emailError = emailError {
                                        HStack(spacing: 4) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .font(.caption)
                                                .foregroundColor(themeManager.colors.error)
                                            
                                            Text(emailError)
                                                .font(.caption)
                                                .foregroundColor(themeManager.colors.error)
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                
                                // Reset Password Button
                                Button(action: resetPassword) {
                                    HStack {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Send Reset Link")
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isFormValid ? themeManager.colors.primary : themeManager.colors.border)
                                    )
                                    .foregroundColor(.white)
                                }
                                .disabled(!isFormValid || isLoading)
                                .animation(.easeInOut(duration: 0.2), value: isFormValid)
                                
                                // Demo Email Hint
                                VStack(spacing: 8) {
                                    Text("Demo Email")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                    
                                    Text("demo@glooko.com")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                }
                                .padding(.top, 8)
                            }
                            .padding(.horizontal, 24)
                        } else {
                            // Success State
                            VStack(spacing: 24) {
                                // Success Icon
                                ZStack {
                                    Circle()
                                        .fill(themeManager.colors.success.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(themeManager.colors.success)
                                }
                                
                                // Success Message
                                VStack(spacing: 12) {
                                    Text("Check Your Email")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Text("We've sent a password reset link to:")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(email)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeManager.colors.primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(themeManager.colors.primary.opacity(0.1))
                                        )
                                    
                                    Text("Click the link in the email to reset your password. The link will expire in 24 hours.")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 8) {
                                        Text("Didn't receive the email?")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.colors.textSecondary)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("• Check your spam or junk folder")
                                            Text("• Verify the email address is correct")
                                            Text("• Wait a few minutes for delivery")
                                        }
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                    }
                                    .padding(.top, 8)
                                }
                                
                                // Action Buttons
                                VStack(spacing: 12) {
                                    Button("Back to Sign In") {
                                        dismiss()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.colors.primary)
                                    )
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    

                                    
                                    Button("Resend Email") {
                                        resendEmail()
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.primary)
                                }
                                .padding(.horizontal, 24)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if showSuccessState {
                        Button("Back") {
                            showSuccessState = false
                            email = ""
                            emailError = nil
                        }
                        .foregroundColor(themeManager.colors.primary)
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(themeManager.colors.primary)
                    }
                }
            }
        }
        .toast($toastMessage, colors: themeManager.colors)
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private var isFormValid: Bool {
        emailError == nil && !email.isEmpty
    }
    
    private func resetPassword() {
        // Validate before attempting reset
        hasAttemptedValidation = true
        validateEmail()
        
        guard isFormValid else {
            return
        }
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isLoading = false
            showSuccessState = true
        }
    }
    
    private func resendEmail() {
        isLoading = true
        
        // Simulate API call for resend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            toastMessage = ToastMessage("Password reset email has been resent successfully.", type: .success)
        }
    }
    
    // MARK: - Validation Methods
    private func validateEmail() {
        emailError = nil
        
        if email.isEmpty {
            return
        } else if !isValidEmail(email) {
            emailError = "Please enter a valid email address"
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
