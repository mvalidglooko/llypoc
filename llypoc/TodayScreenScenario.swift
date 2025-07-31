//
//  TodayScreenScenario.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

// MARK: - Today Screen Scenarios
enum TodayScreenScenario: String, CaseIterable {
    case oneTimeStartingDose = "One Time Starting Dose"
    case doseDay = "Dose Day"
    case nextDoseDay = "Next Dose Day"
    case yesterdayTitration = "Yesterday Titration"
    case requestDoseEarly = "Request Dose Early"
    case treatmentPlanSuspended = "Treatment Plan Suspended"
    case afterDoseTaken = "After Dose Taken (Good Job)"
    
    var description: String {
        switch self {
        case .oneTimeStartingDose:
            return "Show one time starting dose button when patient hasn't taken their first dose"
        case .doseDay:
            return "Show dose day scenario with recent FBG readings and dose guidance"
        case .nextDoseDay:
            return "Show next dose day scenario with upcoming dose information"
        case .yesterdayTitration:
            return "Show scenario where weekly dose was due yesterday"
        case .requestDoseEarly:
            return "Show scenario where patient can request dose before scheduled date"
        case .treatmentPlanSuspended:
            return "Show scenario where treatment plan is suspended"
        case .afterDoseTaken:
            return "Show scenario after patient has taken their dose"
        }
    }
    
    var icon: String {
        switch self {
        case .oneTimeStartingDose:
            return "syringe.circle.fill"
        case .doseDay:
            return "calendar.circle.fill"
        case .nextDoseDay:
            return "calendar.badge.plus"
        case .yesterdayTitration:
            return "exclamationmark.circle.fill"
        case .requestDoseEarly:
            return "clock.arrow.circlepath"
        case .treatmentPlanSuspended:
            return "pause.circle.fill"
        case .afterDoseTaken:
            return "checkmark.circle.fill"
        }
    }
} 
