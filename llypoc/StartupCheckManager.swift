//
//  StartupCheckManager.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI
import Network
import Foundation

class StartupCheckManager: ObservableObject {
    static let shared = StartupCheckManager()
    
    @Published var startupState: StartupState = .checking
    @Published var errorMessage: String = ""
    @Published var canRetry: Bool = false
    @Published var selectedUserType: UserType = .firstTime
    @Published var treatmentPlanStatus: TreatmentPlanStatus = .updated
    
    private var isDebugScenarioActive = false
    
    enum UserType {
        case firstTime
        case returning
    }
    
    enum TreatmentPlanStatus {
        case active
        case ended
        case updated
        case notSet
    }
    
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "StartupCheck")
    
    enum StartupState {
        case checking
        case noNetwork
        case backendUnreachable
        case appVersionOutdated
        case deviceIncompatible
        case success
    }
    
    private init() {}
    
    func performStartupChecks() {
        guard !isDebugScenarioActive else { return }
        
        startupState = .checking
        errorMessage = ""
        canRetry = false
        
        // Step 1: Check network connectivity
        checkNetworkConnection()
    }
    
    private func checkNetworkConnection() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    // Network is available, proceed to backend check
                    self?.checkBackendReachability()
                } else {
                    // No network connection
                    self?.startupState = .noNetwork
                    self?.errorMessage = "No internet connection available. Please check your network settings and try again."
                    self?.canRetry = true
                }
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    private func checkBackendReachability() {
        // Simulate backend reachability check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Simulate 90% success rate for backend reachability
            let isBackendReachable = Double.random(in: 0...1) > 0.1
            
            if isBackendReachable {
                // Backend is reachable, proceed to startup API check
                self.checkStartupAPI()
            } else {
                // Backend is not reachable
                self.startupState = .backendUnreachable
                self.errorMessage = "Unable to connect to our servers. Please check your internet connection and try again."
                self.canRetry = true
            }
        }
    }
    
    private func checkStartupAPI() {
        // Simulate startup API check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Simulate 95% success rate for startup API
            let isStartupAPISuccess = Double.random(in: 0...1) > 0.05
            
            if isStartupAPISuccess {
                // Startup API check successful
                self.startupState = .success
                self.networkMonitor.cancel()
            } else {
                let isAppVersionIssue = Double.random(in: 0...1) > 0.5
                
                if isAppVersionIssue {
                    self.startupState = .appVersionOutdated
                    self.errorMessage = "Your app version is outdated and no longer supported. Please update to the latest version to continue using Efsitora."
                } else {
                    self.startupState = .deviceIncompatible
                    self.errorMessage = "Your device is not compatible with this version of Efsitora. Please use a supported device or contact support for assistance."
                }
                self.canRetry = false
            }
        }
    }
    
    func retry() {
        networkMonitor.cancel()
        performStartupChecks()
    }
    
    // MARK: - Debug/Simulation Methods
    func resetToNormal() {
        networkMonitor.cancel()
        isDebugScenarioActive = false
        
        // Reset to normal state on main queue
        DispatchQueue.main.async {
            self.startupState = .checking
            self.errorMessage = ""
            self.canRetry = false
            self.objectWillChange.send()
            
            // Restart normal checks
            self.performStartupChecks()
        }
    }
    
    func simulateNoNetwork() {
        networkMonitor.cancel()
        isDebugScenarioActive = true
        
        DispatchQueue.main.async {
            self.startupState = .noNetwork
            self.errorMessage = "No internet connection available. Please check your network settings and try again."
            self.canRetry = true
            self.objectWillChange.send()
        }
    }
    
    func simulateBackendUnreachable() {
        networkMonitor.cancel()
        isDebugScenarioActive = true
        
        DispatchQueue.main.async {
            self.startupState = .backendUnreachable
            self.errorMessage = "Unable to connect to our servers. Please check your internet connection and try again."
            self.canRetry = true
            self.objectWillChange.send()
        }
    }
    
    func simulateAppVersionOutdated() {
        networkMonitor.cancel()
        isDebugScenarioActive = true

        DispatchQueue.main.async {
            self.startupState = .appVersionOutdated
            self.errorMessage = "Your app version is outdated and no longer supported. Please update to the latest version to continue using Efsitora."
            self.canRetry = false
            self.objectWillChange.send()
        }
    }
    
    func simulateDeviceIncompatible() {
        networkMonitor.cancel()
        isDebugScenarioActive = true
        
        DispatchQueue.main.async {
            self.startupState = .deviceIncompatible
            self.errorMessage = "Your device is not compatible with this version of Efsitora. Please use a supported device or contact support for assistance."
            self.canRetry = false
            self.objectWillChange.send()
        }
    }
    
    func forceSuccess() {
        networkMonitor.cancel()
        isDebugScenarioActive = true

        DispatchQueue.main.async {
            self.startupState = .success
            self.errorMessage = ""
            self.canRetry = false
            self.objectWillChange.send()
        }
    }
    
    func simulateTreatmentPlanEnded() {
        networkMonitor.cancel()
        isDebugScenarioActive = true

        DispatchQueue.main.async {
            self.treatmentPlanStatus = .ended
            self.startupState = .success
            self.errorMessage = ""
            self.canRetry = false
            self.objectWillChange.send()
        }
    }
    
    func simulateTreatmentPlanNotSet() {
        networkMonitor.cancel()
        isDebugScenarioActive = true
        
        DispatchQueue.main.async {
            self.treatmentPlanStatus = .notSet
            self.startupState = .success
            self.errorMessage = ""
            self.canRetry = false
            self.objectWillChange.send()
        }
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

// MARK: - Startup Check View
struct StartupCheckView: View {
    @StateObject private var startupManager = StartupCheckManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showUserTypeSelection = false
    @State private var showFirstTimeFlow = false
    @State private var showSignInFlow = false
    
    var body: some View {
        ZStack {
            themeManager.colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon and Title
                VStack(spacing: 24) {
                    switch startupManager.startupState {
                    case .checking:
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.colors.primary))
                        
                        Text("Checking App Status...")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.colors.text)
                        
                    case .noNetwork:
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 80))
                            .foregroundColor(themeManager.colors.error)
                        
                        Text("No Network Connection")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.colors.text)
                        
                    case .backendUnreachable:
                        Image(systemName: "cloud.slash")
                            .font(.system(size: 80))
                            .foregroundColor(themeManager.colors.error)
                        
                        Text("Server Unavailable")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.colors.text)
                        
                    case .appVersionOutdated:
                        Image(systemName: "arrow.up.circle")
                            .font(.system(size: 80))
                            .foregroundColor(themeManager.colors.warning)
                        
                        Text("App Update Required")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.colors.text)
                        
                    case .deviceIncompatible:
                        Image(systemName: "iphone.slash")
                            .font(.system(size: 80))
                            .foregroundColor(themeManager.colors.error)
                        
                        Text("Device Not Supported")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.colors.text)
                        
                    case .success:
                        if showUserTypeSelection {
                            // User Type Selection
                            VStack(spacing: 24) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(themeManager.colors.primary)
                                
                                Text("Welcome to Efsitora")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.colors.text)
                                
                                Text("Are you a new user or returning user?")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(themeManager.colors.success)
                            
                            Text("App Ready")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.colors.text)
                        }
                    }
                }
                
                // Error Message
                if !startupManager.errorMessage.isEmpty {
                    VStack(spacing: 16) {
                        Text(startupManager.errorMessage)
                            .font(.subheadline)
                            .foregroundColor(themeManager.colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        // Additional help text based on error type
                        switch startupManager.startupState {
                        case .noNetwork:
                            VStack(spacing: 8) {
                                Text("Please check:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.colors.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Your Wi-Fi or cellular connection")
                                    Text("• Airplane mode is turned off")
                                    Text("• Network settings are correct")
                                }
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                            }
                            
                        case .backendUnreachable:
                            VStack(spacing: 8) {
                                Text("This might be due to:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.colors.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Server maintenance")
                                    Text("• High server load")
                                    Text("• Network connectivity issues")
                                }
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                            }
                            
                        case .appVersionOutdated:
                            VStack(spacing: 8) {
                                Text("To update your app:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.colors.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• Open the App Store")
                                    Text("• Search for 'Efsitora'")
                                    Text("• Tap 'Update' to install the latest version")
                                }
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                            }
                            
                        case .deviceIncompatible:
                            VStack(spacing: 8) {
                                Text("Device requirements:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(themeManager.colors.textSecondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("• iOS 15.0 or later")
                                    Text("• iPhone 8 or newer")
                                    Text("• iPad with iOS 15.0+")
                                }
                                .font(.caption)
                                .foregroundColor(themeManager.colors.textSecondary)
                            }
                            
                        default:
                            EmptyView()
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    if startupManager.startupState == .success && showUserTypeSelection {
                        // User Type Selection Buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                showFirstTimeFlow = true
                            }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                        .font(.subheadline)
                                    
                                    Text("First Time User")
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
                            .opacity(startupManager.selectedUserType == .firstTime ? 1.0 : 0.6)
                            
                            Button(action: {
                                showSignInFlow = true
                            }) {
                                HStack {
                                    Image(systemName: "person.circle")
                                        .font(.subheadline)
                                    
                                    Text("Returning User")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.colors.secondary)
                                )
                                .foregroundColor(.white)
                            }
                            .opacity(startupManager.selectedUserType == .returning ? 1.0 : 0.6)
                        }
                    } else if startupManager.canRetry {
                        Button(action: startupManager.retry) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline)
                                
                                Text("Try Again")
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
                    
                    if startupManager.startupState == .appVersionOutdated {
                        Button(action: openAppStore) {
                            HStack {
                                Image(systemName: "arrow.up.circle")
                                    .font(.subheadline)
                                
                                Text("Update App")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.colors.secondary)
                            )
                            .foregroundColor(.white)
                        }
                    }
                    
                    if startupManager.startupState != .checking && startupManager.startupState != .success && startupManager.startupState != .noNetwork && startupManager.startupState != .appVersionOutdated {
                        Button(action: contactSupport) {
                            Text("Contact Support")
                                .font(.subheadline)
                                .foregroundColor(themeManager.colors.primary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            startupManager.performStartupChecks()
        }
        .onChange(of: startupManager.startupState) { newState in
            if newState == .success {
                // Show user type selection after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showUserTypeSelection = true
                }
            }
        }
        .fullScreenCover(isPresented: $showFirstTimeFlow) {
            FirstTimeSignInFlow()
        }
        .fullScreenCover(isPresented: $showSignInFlow) {
            SignInView()
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
    
    private func openAppStore() {
        print("Opening App Store...")
    }
    
    private func contactSupport() {
        print("Opening support contact...")
    }
}
