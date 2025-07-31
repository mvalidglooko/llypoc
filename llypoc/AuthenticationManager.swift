//
//  AuthenticationManager.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var hasCompletedConsent = false
    @Published var currentUser: User?
    
    private let userDefaults = UserDefaults.standard
    private let isAuthenticatedKey = "isAuthenticated"
    private let hasCompletedConsentKey = "hasCompletedConsent"
    private let userDataKey = "userData"
    private let savedCredentialsKey = "savedCredentials"
    private let rememberMeKey = "rememberMe"
    
    private init() {
        // Always start with fresh authentication state
        clearAuthenticationState()
    }
    
    // MARK: - Authentication Methods
    func signIn(email: String, password: String) async throws -> User {
        // Simulate API call to backend
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Demo validation
        guard email.lowercased() == "demo@glooko.com" && password == "demo123" else {
            throw AuthError.invalidCredentials
        }
        
        // Create demo user
        let user = User(
            id: UUID(),
            email: email,
            name: "Demo User",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date()) ?? Date(),
            phoneNumber: "+1 (555) 123-4567"
        )
        
        await MainActor.run {
            self.currentUser = user
            self.isAuthenticated = true
            self.saveAuthenticationState()
        }
        
        return user
    }
    
    func signOut() {
        isAuthenticated = false
        currentUser = nil
        
        // Clear saved credentials
        if !userDefaults.bool(forKey: rememberMeKey) {
            clearSavedCredentials()
        }
        
        saveAuthenticationState()
    }
    

    
    // MARK: - Consent Methods
    func completeConsent() {
        hasCompletedConsent = true
        saveAuthenticationState()
    }
    
    func resetConsent() {
        hasCompletedConsent = false
        saveAuthenticationState()
    }
    
    // MARK: - Remember Me & Saved Credentials
    func saveCredentials(email: String, password: String, rememberMe: Bool) {
        userDefaults.set(rememberMe, forKey: rememberMeKey)
        
        if rememberMe {
            let credentials = SavedCredentials(email: email, password: password)
            if let credentialsData = try? JSONEncoder().encode(credentials) {
                userDefaults.set(credentialsData, forKey: savedCredentialsKey)
            }
        } else {
            clearSavedCredentials()
        }
    }
    
    func getSavedCredentials() -> SavedCredentials? {
        guard userDefaults.bool(forKey: rememberMeKey),
              let credentialsData = userDefaults.data(forKey: savedCredentialsKey),
              let credentials = try? JSONDecoder().decode(SavedCredentials.self, from: credentialsData) else {
            return nil
        }
        return credentials
    }
    
    private func clearSavedCredentials() {
        userDefaults.removeObject(forKey: savedCredentialsKey)
        userDefaults.set(false, forKey: rememberMeKey)
    }
    
    // MARK: - Persistence
    private func saveAuthenticationState() {
        userDefaults.set(isAuthenticated, forKey: isAuthenticatedKey)
        userDefaults.set(hasCompletedConsent, forKey: hasCompletedConsentKey)
        
        if let user = currentUser {
            if let userData = try? JSONEncoder().encode(user) {
                userDefaults.set(userData, forKey: userDataKey)
            }
        }
    }
    
    private func loadAuthenticationState() {
        isAuthenticated = userDefaults.bool(forKey: isAuthenticatedKey)
        hasCompletedConsent = userDefaults.bool(forKey: hasCompletedConsentKey)
        
        if let userData = userDefaults.data(forKey: userDataKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
        }
    }
    
    private func clearAuthenticationState() {
        isAuthenticated = false
        hasCompletedConsent = false
        currentUser = nil
        
        // Clear all stored authentication data
        userDefaults.removeObject(forKey: isAuthenticatedKey)
        userDefaults.removeObject(forKey: hasCompletedConsentKey)
        userDefaults.removeObject(forKey: userDataKey)
        userDefaults.removeObject(forKey: savedCredentialsKey)
        userDefaults.removeObject(forKey: rememberMeKey)
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: UUID
    let email: String
    let name: String
    let dateOfBirth: Date
    let phoneNumber: String
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

// MARK: - Saved Credentials Model
struct SavedCredentials: Codable {
    let email: String
    let password: String
}

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError
    case serverError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .serverError:
            return "Server error. Please try again later."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}
