//
//  llypocApp.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI
import SwiftData

@main
struct llypocApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
        @StateObject private var themeManager = ThemeManager.shared
        @StateObject private var startupManager = StartupCheckManager.shared
        @State private var showDebugPanel = false
        @State private var currentTab: Int = 0
        @State private var selectedTodayScenario: TodayScreenScenario = .oneTimeStartingDose
        
        var sharedModelContainer: ModelContainer = {
            let schema = Schema([
                Patient.self,
                InsulinDose.self,
                BloodGlucoseReading.self,
                Item.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }()

        var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if startupManager.startupState == .success {
                        if authManager.isAuthenticated && authManager.hasCompletedConsent {
                            MainTabView(currentTab: $currentTab, selectedTodayScenario: $selectedTodayScenario)
                        } else {
                            SignInView()
                        }
                    } else {
                        StartupCheckView()
                    }
                }

                .preferredColorScheme(themeManager.colorScheme)
                
                // Debug Button
                #if DEBUG
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showDebugPanel = true }) {
                            Image(systemName: "gearshape.2")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                )
                        }
                        .padding(.trailing, 16)
                    }
                    Spacer()
                }
                .padding(.top, 50)
                #endif
            }
            .sheet(isPresented: $showDebugPanel) {
                if startupManager.startupState == .success && authManager.isAuthenticated && authManager.hasCompletedConsent && currentTab == 0 {
                    // Today screen - show Today scenarios
                    TodayScreenDebugView(
                        selectedScenario: $selectedTodayScenario,
                        colors: themeManager.colors
                    )
                } else {
                    // Sign-in page - show startup debug
                    StartupDebugView()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
