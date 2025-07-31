//
//  ToastView.swift
//  llypoc
//
//  Created by Mirela Validzic on 24.07.2025..
//

import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    let colors: AppColors
    @Binding var isShowing: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: type.icon)
                .font(.subheadline)
                .foregroundColor(type.textColor(colors))
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(type.textColor(colors))
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Close button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isShowing = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(type.textColor(colors))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(type.backgroundColor(colors))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.borderColor(colors), lineWidth: 1)
                )
        )
        .shadow(color: colors.shadow, radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

enum ToastType {
    case error
    case warning
    case success
    case info
    
    var icon: String {
        switch self {
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    func backgroundColor(_ colors: AppColors) -> Color {
        switch self {
        case .error: return colors.error.opacity(0.95)
        case .warning: return colors.warning.opacity(0.95)
        case .success: return colors.success.opacity(0.95)
        case .info: return colors.primary.opacity(0.95)
        }
    }
    
    func borderColor(_ colors: AppColors) -> Color {
        switch self {
        case .error: return colors.error
        case .warning: return colors.warning
        case .success: return colors.success
        case .info: return colors.primary
        }
    }
    
    func textColor(_ colors: AppColors) -> Color {
        switch self {
        case .error: return .white
        case .warning: return .white
        case .success: return .white
        case .info: return .white
        }
    }
}

struct ToastManager: ViewModifier {
    @Binding var toast: ToastMessage?
    let colors: AppColors
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if let toast = toast {
                VStack {
                    Spacer()
                    
                    ToastView(
                        message: toast.message,
                        type: toast.type,
                        colors: colors,
                        isShowing: Binding(
                            get: { self.toast != nil },
                            set: { if !$0 { self.toast = nil } }
                        )
                    )
                    .zIndex(1000)
                }
                .padding(.bottom, 140)
                .animation(.easeInOut(duration: 0.3), value: toast != nil)
            }
        }
    }
}

struct ToastMessage {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    
    init(_ message: String, type: ToastType = .error, duration: TimeInterval = 4.0) {
        self.message = message
        self.type = type
        self.duration = duration
    }
}

extension View {
    func toast(_ toast: Binding<ToastMessage?>, colors: AppColors) -> some View {
        self.modifier(ToastManager(toast: toast, colors: colors))
    }
}
