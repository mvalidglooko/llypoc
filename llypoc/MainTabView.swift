//
//  MainTabView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @Binding var currentTab: Int
    @Binding var selectedTodayScenario: TodayScreenScenario
    
    var body: some View {
        TabView(selection: $currentTab) {
            TodayView(selectedScenario: $selectedTodayScenario, currentTab: $currentTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Today")
                }
                .tag(0)
            
            LogbookView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Logbook")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(themeManager.colors.primary)
        .preferredColorScheme(themeManager.colorScheme)
    }
}

struct TodayView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var patients: [Patient]
    @Query private var insulinDoses: [InsulinDose]
    @Query private var bgReadings: [BloodGlucoseReading]
    
    @State private var showDoseGuidance = false
    @State private var showCelebratoryMessage = false
    @State private var lastLoggedDate: Date?
    @State private var showDebugSheet = false
    @Binding var selectedScenario: TodayScreenScenario
    @Binding var currentTab: Int
    @State private var showLogBGFlow = false
    @State private var showLogInsulinFlow = false
    @State private var showWeeklyReport = false
    @State private var selectedQuickActionScenario: QuickActionTestScenario? = nil
    @State private var showQuickActionTestSheet = false
    @State private var showInfoScenariosSheet = false
    @State private var showInfoScreen = false
    @State private var selectedInfoScenario: InfoScenario? = nil
    
    private var currentPatient: Patient? {
        patients.first
    }
    
    private var latestDose: InsulinDose? {
        insulinDoses
            .filter { $0.patientId == currentPatient?.id }
            .sorted { $0.dateTime > $1.dateTime }
            .first
    }
    
    private var recentFBGReadings: [BloodGlucoseReading] {
        bgReadings
            .filter { $0.patientId == currentPatient?.id && $0.readingType == .fasting }
            .sorted { $0.dateTime > $1.dateTime }
            .prefix(3)
            .map { $0 }
    }
    
    private var isDoseDay: Bool {
        guard let latestDose = latestDose else { return true }
        let hoursSinceLastDose = Calendar.current.dateComponents([.hour], from: latestDose.dateTime, to: Date()).hour ?? 0
        return Double(hoursSinceLastDose) >= 71.5
    }
    
    private var canRequestDoseGuidance: Bool {
        // For One Time Starting Dose scenario, dose guidance is not available
        if selectedScenario == .oneTimeStartingDose {
            return false
        }
        
        // Check normal data conditions
        guard let latestDose = latestDose else { return true }
        let hoursSinceLastDose = Calendar.current.dateComponents([.hour], from: latestDose.dateTime, to: Date()).hour ?? 0
        return Double(hoursSinceLastDose) >= 71.5 && !recentFBGReadings.isEmpty
    }
    
    private var nextDoseDate: Date? {
        guard let latestDose = latestDose else { return nil }
        return Calendar.current.date(byAdding: .hour, value: 71, to: latestDose.dateTime)
    }
    
    private var hasMissingFBGReadings: Bool {
        // For One Time Starting Dose scenario, don't show missing FBG readings banner
        if selectedScenario == .oneTimeStartingDose {
            return false
        }
        
        // Show missing FBG readings banner when no readings exist
        return recentFBGReadings.isEmpty
    }
    
    private var isTreatmentPlanSuspended: Bool {
        // For One Time Starting Dose scenario, treatment plan is not suspended
        return false
    }
    
    private var shouldShowCelebratoryMessage: Bool {
        // For One Time Starting Dose scenario, don't show celebratory message
        if selectedScenario == .oneTimeStartingDose {
            return false
        }
        
        // Show if user has logged FBG or dose recently
        let recentActivity = bgReadings.filter {
            Calendar.current.isDateInToday($0.dateTime)
        }.count > 0 || insulinDoses.filter {
            Calendar.current.isDateInToday($0.dateTime)
        }.count > 0
        
        return recentActivity
    }
    
    private var shouldShowOneTimeStartingDose: Bool {
        // Show only when the specific scenario is selected
        return selectedScenario == .oneTimeStartingDose
    }
    
    private var weeklyStatistics: (readings: Int, doses: Int, lastReportDate: Date?) {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let weeklyReadings = bgReadings.filter {
            $0.patientId == currentPatient?.id && $0.dateTime >= oneWeekAgo
        }.count
        
        let weeklyDoses = insulinDoses.filter {
            $0.patientId == currentPatient?.id && $0.dateTime >= oneWeekAgo
        }.count
        
        // use the most recent activity
        let lastActivity = max(
            bgReadings.filter { $0.patientId == currentPatient?.id }.map { $0.dateTime }.max() ?? Date.distantPast,
            insulinDoses.filter { $0.patientId == currentPatient?.id }.map { $0.dateTime }.max() ?? Date.distantPast
        )
        
        return (weeklyReadings, weeklyDoses, lastActivity == Date.distantPast ? nil : lastActivity)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hi, \(currentPatient?.name.components(separatedBy: " ").first ?? "User")!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(themeManager.colors.text)
                                
                                Text("Today's Overview")
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Info Icon
                            Button(action: {
                                showInfoScenariosSheet = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.title2)
                                    .foregroundColor(themeManager.colors.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // One Time Starting Dose Section
                        if shouldShowOneTimeStartingDose {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Get Started")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    Text("Welcome to your diabetes management journey!")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.center)
                                    
                                    Button(action: {
                                        showLogInsulinFlow = true
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "syringe.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Take Your First Dose")
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white)
                                                
                                                Text("Start your treatment with your initial dose")
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "arrow.right.circle.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        }
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(themeManager.colors.primary)
                                        )
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.colors.surface)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(themeManager.colors.border, lineWidth: 1)
                                        )
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Banners Section
                        VStack(spacing: 12) {
                            // Show banners based on scenario
                            if selectedScenario == .oneTimeStartingDose {
                                // One Time Starting Dose - Show relevant banners
                                if hasMissingFBGReadings {
                                    BannerView(
                                        title: "Missing FBG Readings",
                                        message: "Please enter your fasting blood glucose readings to get dose guidance.",
                                        type: .warning,
                                        colors: themeManager.colors
                                    )
                                }
                                
                                if isTreatmentPlanSuspended {
                                    BannerView(
                                        title: "Treatment Plan Suspended",
                                        message: "Your treatment plan is currently suspended. Please contact your healthcare provider.",
                                        type: .error,
                                        colors: themeManager.colors
                                    )
                                }
                                
                                if let latestDose = latestDose {
                                    let hoursSinceLastDose = Calendar.current.dateComponents([.hour], from: latestDose.dateTime, to: Date()).hour ?? 0
                                    
                                    if Double(hoursSinceLastDose) < 71.5 {
                                        BannerView(
                                            title: "Dose Guidance Unavailable",
                                            message: "You can request dose guidance again in \(71 - hoursSinceLastDose) hours. Next dose day: \(nextDoseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A")",
                                            type: .info,
                                            colors: themeManager.colors
                                        )
                                    }
                                }
                                
                                if shouldShowCelebratoryMessage {
                                    BannerView(
                                        title: "Great Job!",
                                        message: "You've logged your readings today. Your next weekly dose is scheduled for \(nextDoseDate?.formatted(date: .abbreviated, time: .omitted) ?? "N/A").",
                                        type: .success,
                                        colors: themeManager.colors
                                    )
                                }
                            } else if selectedScenario == .doseDay {
                                // Dose Day
                                BannerView(
                                    title: "Dose Day",
                                    message: "Today is your dose day. You can request dose guidance now.",
                                    type: .success,
                                    colors: themeManager.colors
                                )
                            } else if selectedScenario == .nextDoseDay {
                                // Next Dose Day
                                BannerView(
                                    title: "Next Dose Day",
                                    message: "Your next dose day is \(Calendar.current.date(byAdding: .day, value: 3, to: Date())?.formatted(date: .abbreviated, time: .omitted) ?? "N/A"). Continue monitoring your blood glucose until then.",
                                    type: .info,
                                    colors: themeManager.colors
                                )
                            } else if selectedScenario == .yesterdayTitration {
                                // Yesterday Titration
                                BannerView(
                                    title: "Weekly Dose Overdue",
                                    message: "Your weekly dose was due yesterday. Please take your dose as soon as possible.",
                                    type: .warning,
                                    colors: themeManager.colors
                                )
                            } else if selectedScenario == .requestDoseEarly {
                                // Request Dose Early
                                BannerView(
                                    title: "Request Dose Early",
                                    message: "Hi user, continue logging your FBGs daily. Next dose day is Aug 01.",
                                    type: .info,
                                    colors: themeManager.colors
                                )
                            } else if selectedScenario == .treatmentPlanSuspended {
                                // Treatment Plan Suspended
                                BannerView(
                                    title: "Treatment Plan Suspended",
                                    message: "Your treatment plan is currently suspended. Please contact your healthcare provider for guidance.",
                                    type: .error,
                                    colors: themeManager.colors
                                )
                            } else if selectedScenario == .afterDoseTaken {
                                // After Dose Taken
                                BannerView(
                                    title: "Great Job!",
                                    message: "You've taken your dose today. Your next weekly dose is scheduled for \(Calendar.current.date(byAdding: .day, value: 7, to: Date())?.formatted(date: .abbreviated, time: .omitted) ?? "N/A").",
                                    type: .success,
                                    colors: themeManager.colors
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // BG Section
                        if selectedScenario == .oneTimeStartingDose {
                            // One Time Starting Dose
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Recent fasting BG readings")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.title2)
                                            .foregroundColor(.orange)
                                        
                                        Text("No readings recorded since last dose")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.colors.text)
                                    }
                                    
                                    Text("Please enter your fasting blood glucose readings to get dose guidance.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.colors.surface)
                                )
                            }
                            .padding(.horizontal, 20)
                        } else if selectedScenario == .doseDay {
                            // Dose Day
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Recent fasting BG readings")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    // Mock FBG readings for dose day scenario
                                    FBGReadingCard(
                                        reading: BloodGlucoseReading(
                                            patientId: currentPatient?.id ?? UUID(),
                                            reading: 125.0,
                                            readingType: .fasting,
                                            dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                                        ),
                                        colors: themeManager.colors
                                    )
                                    
                                    FBGReadingCard(
                                        reading: BloodGlucoseReading(
                                            patientId: currentPatient?.id ?? UUID(),
                                            reading: 118.0,
                                            readingType: .fasting,
                                            dateTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                                        ),
                                        colors: themeManager.colors
                                    )
                                    
                                    FBGReadingCard(
                                        reading: BloodGlucoseReading(
                                            patientId: currentPatient?.id ?? UUID(),
                                            reading: 132.0,
                                            readingType: .fasting,
                                            dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
                                        ),
                                        colors: themeManager.colors
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        } else if selectedScenario == .nextDoseDay {
                            // Next Dose Day
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Recent fasting BG readings")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    // Mock FBG readings
                                    FBGReadingCard(
                                        reading: BloodGlucoseReading(
                                            patientId: currentPatient?.id ?? UUID(),
                                            reading: 128.0,
                                            readingType: .fasting,
                                            dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                                        ),
                                        colors: themeManager.colors
                                    )
                                    
                                    FBGReadingCard(
                                        reading: BloodGlucoseReading(
                                            patientId: currentPatient?.id ?? UUID(),
                                            reading: 122.0,
                                            readingType: .fasting,
                                            dateTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                                        ),
                                        colors: themeManager.colors
                                    )
                                    
                                    FBGReadingCard(
                                        reading: BloodGlucoseReading(
                                            patientId: currentPatient?.id ?? UUID(),
                                            reading: 135.0,
                                            readingType: .fasting,
                                            dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
                                        ),
                                        colors: themeManager.colors
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        } else if selectedScenario == .yesterdayTitration {
                            // Yesterday Titration
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Recent fasting BG readings")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    Text("Remember to take your fasting BG reading regularly.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        // Mock FBG readings
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 150.0,
                                                readingType: .fasting,
                                                dateTime: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                        
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 140.0,
                                                readingType: .fasting,
                                                dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                        
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 120.0,
                                                readingType: .fasting,
                                                dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                    }
                                    
                                    Button(action: {
                                        showLogBGFlow = true
                                    }) {
                                        Text("+ Add fasting BG")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.colors.success)
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.colors.surface)
                                )
                            }
                            .padding(.horizontal, 20)
                        } else if selectedScenario == .requestDoseEarly {
                            // Request Dose Early
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Recent fasting BG readings")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    Text("Remember to take your fasting BG reading regularly.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        // Mock FBG readings
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 145.0,
                                                readingType: .fasting,
                                                dateTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                        
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 138.0,
                                                readingType: .fasting,
                                                dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                        
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 152.0,
                                                readingType: .fasting,
                                                dateTime: Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                    }
                                    
                                    Button(action: {
                                        showLogBGFlow = true
                                    }) {
                                        Text("+ Add fasting BG")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.colors.success)
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.colors.surface)
                                )
                            }
                            .padding(.horizontal, 20)
                        } else if selectedScenario == .afterDoseTaken {
                            // After Dose Taken
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Recent fasting BG readings")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    Text("Remember to take your fasting BG reading regularly.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        // Mock FBG readings
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 125.0,
                                                readingType: .fasting,
                                                dateTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                        
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 118.0,
                                                readingType: .fasting,
                                                dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                        
                                        FBGReadingCard(
                                            reading: BloodGlucoseReading(
                                                patientId: currentPatient?.id ?? UUID(),
                                                reading: 122.0,
                                                readingType: .fasting,
                                                dateTime: Date()
                                            ),
                                            colors: themeManager.colors
                                        )
                                    }
                                    
                                    Button(action: {
                                        showLogBGFlow = true
                                    }) {
                                        Text("+ Add fasting BG")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.colors.success)
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.colors.surface)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Request Dose Guidance Section
                        if selectedScenario == .doseDay || selectedScenario == .yesterdayTitration {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Request Dose Guidance")
                                        .font(.headline)
                                        .foregroundColor(themeManager.colors.text)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "brain.head.profile")
                                            .font(.title2)
                                            .foregroundColor(themeManager.colors.accent)
                                        
                                        Text("Ready for dose guidance")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(themeManager.colors.text)
                                    }
                                    
                                    Text("Based on your recent FBG readings, you can now request personalized dose guidance.")
                                        .font(.subheadline)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Button(action: {
                                        showDoseGuidance = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.right.circle.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                            
                                            Text("Request Guidance")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(themeManager.colors.accent)
                                        )
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(themeManager.colors.surface)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Discreet Request Dose Guidance Section (dose early scenario)
                        if selectedScenario == .requestDoseEarly {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Dose Guidance")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(themeManager.colors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showDoseGuidance = true
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "arrow.right")
                                                .font(.caption)
                                                .foregroundColor(themeManager.colors.accent)
                                            
                                            Text("Ask early request")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(themeManager.colors.accent)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(themeManager.colors.surface.opacity(0.5))
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Quick Actions Section
                        VStack(spacing: 16) {
                            HStack {
                                Text("Quick Actions")
                                    .font(.headline)
                                    .foregroundColor(themeManager.colors.text)
                                
                                Spacer()
                            }
                            
                            LazyVGrid(columns: selectedScenario == .treatmentPlanSuspended ? [GridItem(.flexible())] : [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                QuickActionCard(
                                    title: "Add BG Reading",
                                    icon: "drop.fill",
                                    color: themeManager.colors.success,
                                    colors: themeManager.colors
                                ) {
                                    showLogBGFlow = true
                                }
                                
                                if selectedScenario != .treatmentPlanSuspended {
                                    QuickActionCard(
                                        title: "Log Insulin",
                                        icon: "syringe.fill",
                                        color: themeManager.colors.primary,
                                        colors: themeManager.colors
                                    ) {
                                        #if DEBUG
                                        showQuickActionTestSheet = true
                                        #else
                                        showLogInsulinFlow = true
                                        #endif
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                            
                            // Your Last Efsitora Dose Section
                            if selectedScenario == .doseDay || selectedScenario == .nextDoseDay || selectedScenario == .yesterdayTitration || selectedScenario == .requestDoseEarly || selectedScenario == .afterDoseTaken {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("Your last Efsitora dose")
                                            .font(.headline)
                                            .foregroundColor(themeManager.colors.text)
                                        
                                        Spacer()
                                    }
                                    
                                    VStack(spacing: 12) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(themeManager.colors.primary.opacity(0.1))
                                                    .frame(width: 50, height: 50)
                                                
                                                Image(systemName: "syringe.fill")
                                                    .font(.title2)
                                                    .foregroundColor(themeManager.colors.primary)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("300 units")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(themeManager.colors.text)
                                                
                                                Text("\(Calendar.current.date(byAdding: .day, value: -7, to: Date())?.formatted(date: .abbreviated, time: .shortened) ?? "N/A")")
                                                    .font(.subheadline)
                                                    .foregroundColor(themeManager.colors.textSecondary)
                                            }
                                            
                                            Spacer()
                                        }
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(themeManager.colors.surface)
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            Spacer(minLength: 100)
                        }
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showDoseGuidance) {
                    // Create mock data for testing the full flow
                    let mockPatient = Patient(
                        name: "John Doe",
                        dateOfBirth: Calendar.current.date(byAdding: .year, value: -45, to: Date()) ?? Date(),
                        email: "john.doe@example.com",
                        phoneNumber: "+1-555-0123",
                        insulinType: .efsitora,
                        previousInsulinDose: 300.0,
                        medianFBG: 125.0,
                        isInsulinNaive: false
                    )
                    
                    let mockFBGReadings = [
                        BloodGlucoseReading(
                            patientId: mockPatient.id,
                            reading: 120.0,
                            readingType: .fasting,
                            dateTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
                        ),
                        BloodGlucoseReading(
                            patientId: mockPatient.id,
                            reading: 135.0,
                            readingType: .fasting,
                            dateTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
                        ),
                        BloodGlucoseReading(
                            patientId: mockPatient.id,
                            reading: 118.0,
                            readingType: .fasting,
                            dateTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
                        )
                    ]
                    
                    let mockLastDose = InsulinDose(
                        patientId: mockPatient.id,
                        doseAmount: 300.0,
                        doseType: .weekly,
                        dateTime: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
                    )
                    
                    DoseGuidanceFlowView(
                        patient: mockPatient,
                        recentFBGReadings: selectedScenario == .requestDoseEarly ? [mockFBGReadings[0]] : mockFBGReadings,
                        lastDose: mockLastDose,
                        scenario: selectedScenario == .requestDoseEarly ? "requestDoseEarly" : nil
                    )
                }
                .sheet(isPresented: $showDebugSheet) {
                    TodayScreenDebugView(
                        selectedScenario: $selectedScenario,
                        colors: themeManager.colors
                    )
                }
                .fullScreenCover(isPresented: $showLogBGFlow) {
                    LogBGFlowView()
                }
                .fullScreenCover(isPresented: $showLogInsulinFlow) {
                    LogInsulinFlowView(
                        bypassStarterDoseQuestion: selectedQuickActionScenario == .weeklyDose,
                        testScenario: selectedQuickActionScenario
                    )
                }
                .sheet(isPresented: $showQuickActionTestSheet) {
                    QuickActionTestSelectorView(
                        selectedScenario: $selectedQuickActionScenario,
                        onScenarioSelected: { scenario in
                            print("🔍 DEBUG: Scenario selected = \(scenario.rawValue)")
                            selectedQuickActionScenario = scenario
                            showQuickActionTestSheet = false
                            
                            let shouldBypass = scenario == .weeklyDose
                            print("🔍 DEBUG: shouldBypass = \(shouldBypass)")
                            
                            showLogInsulinFlow = true
                        },
                        colors: themeManager.colors
                    )
                }
                .sheet(isPresented: $showWeeklyReport) {
                    WeeklyReportView(
                        weeklyStatistics: weeklyStatistics,
                        selectedScenario: selectedScenario,
                        colors: themeManager.colors
                    )
                }
                .sheet(isPresented: $showInfoScenariosSheet) {
                    InfoScenariosSelectorView(
                        selectedScenario: $selectedInfoScenario,
                        onScenarioSelected: { scenario in
                            selectedInfoScenario = scenario
                            showInfoScenariosSheet = false
                            showInfoScreen = true
                        },
                        colors: themeManager.colors
                    )
                }
                .sheet(isPresented: $showInfoScreen) {
                    if let scenario = selectedInfoScenario {
                        InfoScreenView(
                            scenario: scenario,
                            colors: themeManager.colors
                        )
                    }
                }
            }
        }
    }
 
    struct BannerView: View {
        let title: String
        let message: String
        let type: BannerType
        let colors: AppColors
        
        enum BannerType {
            case success, warning, error, info
            
            var color: Color {
                switch self {
                case .success: return .green
                case .warning: return .orange
                case .error: return .red
                case .info: return .blue
                }
            }
            
            var icon: String {
                switch self {
                case .success: return "checkmark.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .error: return "xmark.circle.fill"
                case .info: return "info.circle.fill"
                }
            }
        }
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(type.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(colors.text)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(type.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(type.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    struct FBGReadingCard: View {
        let reading: BloodGlucoseReading
        let colors: AppColors
        
        var body: some View {
            VStack(spacing: 8) {
                // Date
                Text(reading.dateTime.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
                
                // Reading value
                Text("\(Int(reading.reading)) mg/dL")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
            )
        }
    }
    
    struct DoseGuidanceView: View {
        let colors: AppColors
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                ZStack {
                    colors.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(colors.primary)
                        
                        Text("Dose Guidance")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colors.text)
                        
                        Text("Based on your recent FBG readings and treatment plan, here's your recommended dose guidance.")
                            .font(.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 16) {
                            Text("Recommended Dose: 300 units")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(colors.text)
                            
                            Text("This recommendation is based on your fasting blood glucose readings and current treatment plan.")
                                .font(.caption)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colors.surface)
                                .shadow(color: colors.shadow, radius: 4, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
                .navigationTitle("Dose Guidance")
                .navigationBarTitleDisplayMode(.inline)
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
    
    struct QuickActionCard: View {
        let title: String
        let icon: String
        let color: Color
        let colors: AppColors
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(colors.text)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colors.surface)
                        .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    struct ActivityItem: View {
        let title: String
        let subtitle: String
        let time: String
        let icon: String
        let color: Color
        let colors: AppColors
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(colors.text)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(colors.textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colors.surface)
            )
        }
    }
    
    // MARK: - Weekly Report View
    struct WeeklyReportView: View {
        let weeklyStatistics: (readings: Int, doses: Int, lastReportDate: Date?)
        let selectedScenario: TodayScreenScenario
        let colors: AppColors
        @Environment(\.dismiss) private var dismiss
        
        private var displayStatistics: (readings: Int, doses: Int, lastReportDate: Date?) {
            return weeklyStatistics
        }
        
        var body: some View {
            NavigationView {
                ZStack {
                    colors.background
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 16) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(colors.primary)
                                
                                Text("Weekly Report")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(colors.text)
                                
                                Text("Your diabetes management summary for the past 7 days")
                                    .font(.subheadline)
                                    .foregroundColor(colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Statistics Cards
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                StatCard(
                                    title: "Blood Glucose Readings",
                                    value: "\(displayStatistics.readings)",
                                    subtitle: "This week",
                                    icon: "drop.fill",
                                    color: colors.success,
                                    colors: colors
                                )
                                
                                StatCard(
                                    title: "Insulin Doses",
                                    value: "\(displayStatistics.doses)",
                                    subtitle: "This week",
                                    icon: "syringe.fill",
                                    color: colors.primary,
                                    colors: colors
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Summary Section
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Weekly Summary")
                                        .font(.headline)
                                        .foregroundColor(colors.text)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    SummaryRow(
                                        title: "Total Activities",
                                        value: "\(displayStatistics.readings + displayStatistics.doses)",
                                        colors: colors
                                    )
                                    
                                    SummaryRow(
                                        title: "Average per Day",
                                        value: String(format: "%.1f", Double(displayStatistics.readings + displayStatistics.doses) / 7.0),
                                        colors: colors
                                    )
                                    
                                    if let lastDate = displayStatistics.lastReportDate {
                                        SummaryRow(
                                            title: "Last Activity",
                                            value: lastDate.formatted(date: .abbreviated, time: .shortened),
                                            colors: colors
                                        )
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colors.surface)
                                        .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Action Buttons
                            VStack(spacing: 12) {
                                Button(action: {
                                    // Navigate to detailed logbook
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .font(.subheadline)
                                        
                                        Text("View Detailed Logbook")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colors.primary)
                                    )
                                    .foregroundColor(.white)
                                }
                                
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Close")
                                        .font(.subheadline)
                                        .foregroundColor(colors.primary)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            Spacer(minLength: 50)
                        }
                    }
                }
                .navigationTitle("Weekly Report")
                .navigationBarTitleDisplayMode(.inline)
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
    
    // MARK: - Supporting Views
    struct StatCard: View {
        let title: String
        let value: String
        let subtitle: String
        let icon: String
        let color: Color
        let colors: AppColors
        
        var body: some View {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(spacing: 4) {
                    Text(value)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colors.text)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(colors.textSecondary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colors.surface)
                    .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
            )
        }
    }
    
    struct SummaryRow: View {
        let title: String
        let value: String
        let colors: AppColors
        
        var body: some View {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(colors.text)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colors.text)
            }
        }
    }
    
    // MARK: - Quick Action Test Selector
    struct QuickActionTestSelectorView: View {
        @Binding var selectedScenario: QuickActionTestScenario?
        let onScenarioSelected: (QuickActionTestScenario) -> Void
        let colors: AppColors
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            NavigationView {
                ZStack {
                    colors.background
                        .ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Select Test Scenario")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(colors.text)
                            
                            Text("Choose a scenario to test the Log Insulin flow")
                                .font(.subheadline)
                                .foregroundColor(colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Scenario Options
                        VStack(spacing: 16) {
                            ForEach(QuickActionTestScenario.allCases, id: \.self) { scenario in
                                Button(action: {
                                    onScenarioSelected(scenario)
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(colors.primary.opacity(0.1))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: scenario.icon)
                                                .font(.title2)
                                                .foregroundColor(colors.primary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(scenario.rawValue)
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(colors.text)
                                            
                                            Text(scenario.description)
                                                .font(.subheadline)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colors.surface)
                                            .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                }
                .navigationTitle("Test Scenarios")
                .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Info Scenarios Selector View
struct InfoScenariosSelectorView: View {
    @Binding var selectedScenario: InfoScenario?
    let onScenarioSelected: (InfoScenario) -> Void
    let colors: AppColors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Info Screen Scenarios")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colors.text)
                        
                        Text("Choose a scenario to test info screens")
                            .font(.subheadline)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Scenario Options
                    VStack(spacing: 16) {
                        ForEach(InfoScenario.allCases, id: \.self) { scenario in
                            Button(action: {
                                onScenarioSelected(scenario)
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(scenario.color.opacity(0.1))
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: scenario.icon)
                                            .font(.title2)
                                            .foregroundColor(scenario.color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(scenario.rawValue)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(colors.text)
                                        
                                        Text(scenario.description)
                                            .font(.subheadline)
                                            .foregroundColor(colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(colors.textSecondary)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colors.surface)
                                        .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Info Scenarios")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Info Screen View
struct InfoScreenView: View {
    let scenario: InfoScenario
    let colors: AppColors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: scenario.icon)
                        .font(.system(size: 60))
                        .foregroundColor(scenario.color)
                    
                    // Title and Message
                    VStack(spacing: 12) {
                        Text("Your treatment plan has been suspended")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colors.text)
                            .multilineTextAlignment(.center)
                        
                        Text(scenarioMessage)
                            .font(.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ok") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var scenarioMessage: String {
        switch scenario {
        case .suspendOverdose:
            return "Your treatment plan has been suspended due to an overdose incident. Please contact your healthcare provider immediately for guidance and to discuss next steps for your treatment."
        case .suspendUnderdose:
            return "Your treatment plan has been suspended due to consistent underdosing. Please contact your healthcare provider to review your treatment plan and ensure proper dosing compliance."
        case .suspendHypo:
            return "Your treatment plan has been suspended due to frequent hypoglycemic events. Multiple low blood glucose readings have been detected, which requires immediate medical attention. Please contact your healthcare provider to review your treatment plan and ensure your safety."
        case .suspendGeneral:
            return "Your treatment plan has been suspended. Please contact your healthcare provider to review your treatment plan and determine the next steps for your care."
        case .suspendMaxDose:
            return "Your treatment plan has been suspended because the recommended dose has reached the maximum safe limit of 1400 units. Please contact your healthcare provider immediately to review your treatment plan and discuss alternative approaches."
        case .suspendMinDose:
            return "Your treatment plan has been suspended because the recommended dose has fallen below the minimum effective level of 60 units. Please contact your healthcare provider to review your treatment plan and determine appropriate next steps."
        }
    }
}

// MARK: - Info Scenarios
enum InfoScenario: String, CaseIterable {
    case suspendOverdose = "TP suspended because overdose"
    case suspendUnderdose = "TP suspended because underdose"
    case suspendHypo = "TP suspended because hypo logged"
    case suspendGeneral = "General TP suspended"
    case suspendMaxDose = "Max dose reached TP suspended"
    case suspendMinDose = "Min dose reached TP suspended"
    
    var description: String {
        switch self {
        case .suspendOverdose:
            return "Show info screen for overdose suspension"
        case .suspendUnderdose:
            return "Show info screen for underdose suspension"
        case .suspendHypo:
            return "Show info screen for hypoglycemia suspension"
        case .suspendGeneral:
            return "Show info screen for general suspension"
        case .suspendMaxDose:
            return "Show info screen for maximum dose suspension"
        case .suspendMinDose:
            return "Show info screen for minimum dose suspension"
        }
    }
    
    var icon: String {
        switch self {
        case .suspendOverdose, .suspendUnderdose, .suspendHypo, .suspendGeneral, .suspendMaxDose, .suspendMinDose:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .suspendOverdose, .suspendUnderdose, .suspendHypo, .suspendGeneral, .suspendMaxDose, .suspendMinDose:
            return .red
        }
    }
}

