import Foundation

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var currentStep: PasswordResetStep = .emailEntry
    @Published var email: String = ""
    @Published var otpCode: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    
    enum PasswordResetStep {
        case emailEntry
        case otpVerification
        case newPasswordEntry
        case completed
    }
    
    func requestOTP() async throws {
        guard email.isValidEmail() else {
            throw PasswordResetError.invalidEmail
        }
        
        // Use Supabase's method to send OTP
        try await AuthManager.shared.resetPasswordWithOTP(email: email)
        currentStep = .otpVerification
    }
    
    func verifyOTP() async throws {
        guard !otpCode.isEmpty else {
            throw PasswordResetError.invalidOTP
        }
        
        // Verify OTP using Supabase
        let isVerified = try await AuthManager.shared.verifyOTP(email: email, token: otpCode)
        if isVerified {
            currentStep = .newPasswordEntry
        } else {
            throw PasswordResetError.invalidOTP
        }
    }
    
    func updatePassword() async throws {
        guard validatePassword() else {
            throw PasswordResetError.invalidPassword
        }
        
        // Update password using Supabase
        try await AuthManager.shared.updateUserPassword(email: email, password: newPassword)
        currentStep = .completed
    }
    
    private func validatePassword() -> Bool {
        // Password must be at least 8 characters
        if newPassword.count < 8 {
            return false
        }
        
        // Passwords must match
        if newPassword != confirmPassword {
            return false
        }
        
        return true
    }
}

enum PasswordResetError: LocalizedError {
    case invalidEmail
    case invalidOTP
    case invalidPassword
    case passwordsDoNotMatch
    case resetFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidOTP:
            return "The verification code is incorrect. Please try again."
        case .invalidPassword:
            return "Password must be at least 8 characters."
        case .passwordsDoNotMatch:
            return "Passwords do not match."
        case .resetFailed:
            return "Failed to reset password. Please try again."
        }
    }
} 