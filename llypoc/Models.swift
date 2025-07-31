//
//  Models.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import Foundation
import SwiftData

// MARK: - Patient Model
@Model
class Patient {
    var id: UUID
    var name: String
    var dateOfBirth: Date
    var email: String
    var phoneNumber: String
    var insulinTypeRaw: String
    var previousInsulinDose: Double
    var medianFBG: Double
    var isInsulinNaive: Bool
    var createdAt: Date
    var updatedAt: Date
    
    var insulinType: InsulinType {
        get {
            return InsulinType(rawValue: insulinTypeRaw) ?? .efsitora
        }
        set {
            insulinTypeRaw = newValue.rawValue
        }
    }
    
    init(name: String, dateOfBirth: Date, email: String, phoneNumber: String, insulinType: InsulinType, previousInsulinDose: Double, medianFBG: Double, isInsulinNaive: Bool) {
        self.id = UUID()
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.email = email
        self.phoneNumber = phoneNumber
        self.insulinTypeRaw = insulinType.rawValue
        self.previousInsulinDose = previousInsulinDose
        self.medianFBG = medianFBG
        self.isInsulinNaive = isInsulinNaive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Insulin Dose Model
@Model
class InsulinDose {
    var id: UUID
    var patientId: UUID
    var doseAmount: Double
    var doseTypeRaw: String
    var dateTime: Date
    var notes: String?
    var isStartingDose: Bool
    var createdAt: Date
    
    var doseType: DoseType {
        get {
            return DoseType(rawValue: doseTypeRaw) ?? .weekly
        }
        set {
            doseTypeRaw = newValue.rawValue
        }
    }
    
    init(patientId: UUID, doseAmount: Double, doseType: DoseType, dateTime: Date, notes: String? = nil, isStartingDose: Bool = false) {
        self.id = UUID()
        self.patientId = patientId
        self.doseAmount = doseAmount
        self.doseTypeRaw = doseType.rawValue
        self.dateTime = dateTime
        self.notes = notes
        self.isStartingDose = isStartingDose
        self.createdAt = Date()
    }
}

// MARK: - Blood Glucose Reading Model
@Model
class BloodGlucoseReading {
    var id: UUID
    var patientId: UUID
    var reading: Double
    var readingTypeRaw: String
    var dateTime: Date
    var notes: String?
    var createdAt: Date
    
    var readingType: BGReadingType {
        get {
            return BGReadingType(rawValue: readingTypeRaw) ?? .fasting
        }
        set {
            readingTypeRaw = newValue.rawValue
        }
    }
    
    init(patientId: UUID, reading: Double, readingType: BGReadingType, dateTime: Date, notes: String? = nil) {
        self.id = UUID()
        self.patientId = patientId
        self.reading = reading
        self.readingTypeRaw = readingType.rawValue
        self.dateTime = dateTime
        self.notes = notes
        self.createdAt = Date()
    }
}

// MARK: - Enums
enum InsulinType: String, CaseIterable, Codable {
    case nphU100 = "NPH (U-100)"
    case glargineU300 = "Glargine (U-300)"
    case glargineU100 = "Glargine (U-100)"
    case detemirU100 = "Detemir (U-100)"
    case degludecU100 = "Degludec (U-100)"
    case degludecU200 = "Degludec (U-200)"
    case efsitora = "Efsitora"
    
    var frequency: InsulinFrequency {
        switch self {
        case .nphU100:
            return .twiceDaily
        case .glargineU300, .glargineU100, .detemirU100, .degludecU100, .degludecU200, .efsitora:
            return .daily
        }
    }
}

enum InsulinFrequency: String, Codable {
    case daily = "Daily"
    case twiceDaily = "Twice Daily"
}

enum DoseType: String, CaseIterable, Codable {
    case starting = "Starting Dose"
    case weekly = "Weekly Dose"
    case correction = "Correction Dose"
}

enum BGReadingType: String, CaseIterable, Codable {
    case fasting = "Fasting"
    case afterBreakfast = "After Breakfast"
    case beforeLunch = "Before Lunch"
    case afterLunch = "After Lunch"
    case beforeDinner = "Before Dinner"
    case afterDinner = "After Dinner"
}

// MARK: - DPAG Engine Logic
class DPAGEngine {
    static func calculateStartingDose(patient: Patient) -> StartingDoseResult {
        let isInsulinNaive = patient.isInsulinNaive
        let medianFBG = patient.medianFBG
        let previousInsulinType = patient.insulinType
        let previousDose = patient.previousInsulinDose
        
        // Case 1: Insulin naive or switching from twice daily in
        if isInsulinNaive || previousInsulinType == .nphU100 || previousInsulinType == .glargineU300 {
            if medianFBG <= 120 || medianFBG > 120 {
                return StartingDoseResult(
                    isRequired: true,
                    dose: 300,
                    minDose: 100,
                    maxDose: 300,
                    reason: "Default starting dose for insulin naive or specific insulin types"
                )
            }
        }
        
        // Case 2: Switching from twice daily insulin
        if previousInsulinType.frequency == .twiceDaily {
            if medianFBG > 120 {
                let calculatedDose = previousDose * 0.8 * 7 * 3
                return StartingDoseResult(
                    isRequired: true,
                    dose: calculatedDose,
                    minDose: 60,
                    maxDose: 2100,
                    reason: "Calculated from previous twice daily dose"
                )
            } else {
                return StartingDoseResult(
                    isRequired: false,
                    dose: 0,
                    minDose: 0,
                    maxDose: 0,
                    reason: "Starting dose skipped for FBG <= 120 mg/dL"
                )
            }
        }
        
        // Case 3: Switching from daily insulin
        if previousInsulinType.frequency == .daily {
            if medianFBG > 120 {
                let calculatedDose = previousDose * 7 * 3
                return StartingDoseResult(
                    isRequired: true,
                    dose: calculatedDose,
                    minDose: 60,
                    maxDose: 2100,
                    reason: "Calculated from previous daily dose"
                )
            } else {
                return StartingDoseResult(
                    isRequired: false,
                    dose: 0,
                    minDose: 0,
                    maxDose: 0,
                    reason: "Starting dose skipped for FBG <= 120 mg/dL"
                )
            }
        }
        
        return StartingDoseResult(
            isRequired: false,
            dose: 0,
            minDose: 0,
            maxDose: 0,
            reason: "No starting dose required"
        )
    }
}

// MARK: - Starting Dose Result
struct StartingDoseResult {
    let isRequired: Bool
    let dose: Double
    let minDose: Double
    let maxDose: Double
    let reason: String
}
