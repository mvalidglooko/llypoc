//
//  BiometricAuthManager.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import Foundation
import LocalAuthentication

class BiometricAuthManager: ObservableObject {
    @Published var isBiometricAvailable = false
    @Published var biometricType: BiometricType = .none
    
    private let context = LAContext()
    
    init() {
        checkBiometricAvailability()
    }
    
    private func checkBiometricAvailability() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
            
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            default:
                biometricType = .none
                isBiometricAvailable = false
            }
        } else {
            isBiometricAvailable = false
            biometricType = .none
        }
    }
    
    func authenticate(completion: @escaping (Bool) -> Void) {
        let reason = "Sign in to your Efsitora account"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
}

enum BiometricType {
    case none
    case touchID
    case faceID
} 
