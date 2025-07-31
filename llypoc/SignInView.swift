//
//  SignInView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

struct SignInView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showConsentFlow = false
    @State private var showReturningUserFlow = false
    @State private var showForgotPassword = false
    
    // Validation states
    @State private var emailError: String?
    @State private var hasAttemptedValidation = false
    @State private var toastMessage: ToastMessage?
    
    // Password visibility and biometric states
    @State private var isPasswordVisible = false
    @State private var rememberMe = false
    @State private var biometricAuth = BiometricAuthManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 60))
                                .foregroundColor(themeManager.colors.primary)
                            
                            Text("Welcome to Efsitora")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.colors.text)
                            
                            Text("Sign in to manage your diabetes treatment")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Sign In Form
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
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(themeManager.colors.text)
                                
                                HStack(spacing: 12) {
                                    Group {
                                        if isPasswordVisible {
                                            TextField("Enter your password", text: $password)
                                        } else {
                                            SecureField("Enter your password", text: $password)
                                        }
                                    }
                                    .textFieldStyle(CustomTextFieldStyle(
                                        colors: themeManager.colors,
                                        hasError: false
                                    ))
                                    .textContentType(.password)
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isPasswordVisible.toggle()
                                        }
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.colors.textSecondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                

                            }
                            
                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .font(.caption)
                                .foregroundColor(themeManager.colors.primary)
                            }
                            
                            // Remember Me (Hidden for MVP)
                            /*
                            HStack {
                                Button(action: {
                                    rememberMe.toggle()
                                }) {
                                    HStack(spacing: 8) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(rememberMe ? themeManager.colors.primary : Color.clear)
                                                .frame(width: 18, height: 18)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(rememberMe ? themeManager.colors.primary : themeManager.colors.border, lineWidth: 1.5)
                                                )
                                            
                                            if rememberMe {
                                                Image(systemName: "checkmark")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        Text("Remember me")
                                            .font(.caption)
                                            .foregroundColor(themeManager.colors.text)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Spacer()
                                
                                Button("Forgot Password?") {
                                    // Handle forgot password
                                }
                                .font(.caption)
                                .foregroundColor(themeManager.colors.primary)
                            }
                            */
                        }
                        .padding(.horizontal, 24)
                        
                        // Sign In Button
                        VStack(spacing: 16) {
                            // Biometric Authentication Button
                            if biometricAuth.isBiometricAvailable {
                                Button(action: biometricSignIn) {
                                    HStack(spacing: 8) {
                                        Image(systemName: biometricAuth.biometricType == .faceID ? "faceid" : "touchid")
                                            .font(.title2)
                                        
                                        Text("Sign in with \(biometricAuth.biometricType == .faceID ? "Face ID" : "Touch ID")")
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(themeManager.colors.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(themeManager.colors.primary, lineWidth: 1.5)
                                            )
                                    )
                                    .foregroundColor(themeManager.colors.primary)
                                }
                                .disabled(isLoading)
                            }
                            
                            // Divider
                            if biometricAuth.isBiometricAvailable {
                                HStack {
                                    Rectangle()
                                        .fill(themeManager.colors.border)
                                        .frame(height: 1)
                                    
                                    Text("or")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .padding(.horizontal, 16)
                                    
                                    Rectangle()
                                        .fill(themeManager.colors.border)
                                        .frame(height: 1)
                                }
                            }
                            
                            Button(action: signIn) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In")
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
                            
                            // Demo Credentials
                            VStack(spacing: 8) {
                                Text("Demo Credentials")
                                    .font(.caption)
                                    .foregroundColor(themeManager.colors.textSecondary)
                                
                                VStack(spacing: 4) {
                                    Text("Email: demo@glooko.com")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                    Text("Password: Demo123!")
                                        .font(.caption)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .toast($toastMessage, colors: themeManager.colors)
            .fullScreenCover(isPresented: $showConsentFlow) {
                FirstTimeSignInFlow()
            }
            .fullScreenCover(isPresented: $showReturningUserFlow) {
                ReturningUserFlow()
            }
            .fullScreenCover(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private var isFormValid: Bool {
        emailError == nil && !email.isEmpty && !password.isEmpty
    }
    
    private func signIn() {
        // Validate before attempting sign in
        hasAttemptedValidation = true
        
        // Show required field errors if fields are empty
        if email.isEmpty {
            emailError = "Email is required"
        } else {
            validateEmail()
        }
        
        guard isFormValid else {
            return
        }
        
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // Demo validation
            if email.lowercased() == "demo@glooko.com" && password == "Demo123!" {
                // Check if this is first time user
                let isFirstTimeUser = !authManager.hasCompletedConsent
                
                if isFirstTimeUser {
                    showConsentFlow = true
                } else {
                    // Returning user
                    showReturningUserFlow = true
                }
            } else {
                toastMessage = ToastMessage("Invalid email or password. Please try again.", type: .error)
            }
        }
    }
    
    // MARK: - Validation Methods
    private func validateEmail() {
        emailError = nil
        
        if email.isEmpty {
            // Don't show error for empty field until user has interacted
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
    
    // MARK: - Biometric Authentication
    private func biometricSignIn() {
        biometricAuth.authenticate { success in
            if success {
                // Use saved credentials for biometric sign-in
                if let savedCredentials = authManager.getSavedCredentials() {
                    email = savedCredentials.email
                    password = savedCredentials.password
                    signIn()
                } else {
                    toastMessage = ToastMessage("No saved credentials found. Please sign in manually first.", type: .warning)
                }
            } else {
                toastMessage = ToastMessage("Biometric authentication failed. Please try again.", type: .error)
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    let colors: AppColors
    let hasError: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(hasError ? colors.error : colors.border, lineWidth: hasError ? 2 : 1)
                    )
            )
            .foregroundColor(colors.text)
    }
}

