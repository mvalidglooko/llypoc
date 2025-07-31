//
//  TodayScreenDebugView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

// MARK: - Today Screen Debug View
struct TodayScreenDebugView: View {
    @Binding var selectedScenario: TodayScreenScenario
    let colors: AppColors
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 60))
                                .foregroundColor(colors.primary)
                            
                            Text("Today Screen Debug Panel")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(colors.text)
                        }
                        
                        // Scenario Selection
                        VStack(spacing: 16) {
                            Text("Test Scenarios")
                                .font(.headline)
                                .foregroundColor(colors.text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                                ForEach(TodayScreenScenario.allCases, id: \.self) { scenario in
                                    ScenarioCard(
                                        scenario: scenario,
                                        isSelected: selectedScenario == scenario,
                                        colors: colors
                                    ) {
                                        selectedScenario = scenario
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Action Button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.subheadline)
                                
                                Text("Apply & Close")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colors.primary)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Debug Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ScenarioCard: View {
    let scenario: TodayScreenScenario
    let isSelected: Bool
    let colors: AppColors
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: scenario.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : colors.primary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : colors.text)
                    
                    Text(scenario.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? colors.primary : colors.surface)
                    .shadow(color: colors.shadow, radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
