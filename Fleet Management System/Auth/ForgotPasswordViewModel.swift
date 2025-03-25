import Foundation

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var currentStep: PasswordResetStep = .emailEntry
    @Published var email: String = ""
    @Published var otpCode: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var isNewPasswordVisible: Bool = false
    @Published var isConfirmPasswordVisible: Bool = false
    @Published var remainingTime: Int = 60
    @Published var isResendButtonEnabled: Bool = false
    @Published var isResendingOTP: Bool = false
    
    private var timer: Timer?
    private let minimumResendInterval: TimeInterval = 60 // 60 seconds minimum between resends
    
    var isValidOTP: Bool {
        otpCode.count == 6 && otpCode.allSatisfy { $0.isNumber }
    }
    
    var isPasswordValid: Bool {
        !newPassword.isEmpty && !confirmPassword.isEmpty && 
        newPassword == confirmPassword && newPassword.count >= 8
    }
    
    enum PasswordResetStep {
        case emailEntry
        case otpVerification
        case newPasswordEntry
        case completed
    }
    
    func startResendTimer() {
        remainingTime = 60
        isResendButtonEnabled = false
        isResendingOTP = false
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.timer?.invalidate()
                self.isResendButtonEnabled = true
            }
        }
    }
    
    func requestOTP() async throws {
        guard email.isValidEmail() else {
            throw PasswordResetError.invalidEmail
        }
        
        // Check if we're already in the process of sending an OTP
        guard !isResendingOTP else {
            throw PasswordResetError.otpRateLimit
        }
        
        isResendingOTP = true
        
        do {
            // Use Supabase's method to send OTP
            try await AuthManager.shared.resetPasswordWithOTP(email: email)
            currentStep = .otpVerification
            startResendTimer() // Start the timer when OTP is first requested
        } catch {
            isResendingOTP = false
            throw error
        }
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
    
    deinit {
        timer?.invalidate()
    }
}

enum PasswordResetError: LocalizedError {
    case invalidEmail
    case invalidOTP
    case invalidPassword
    case passwordsDoNotMatch
    case resetFailed
    case otpRateLimit
    
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
        case .otpRateLimit:
            return "You have reached the rate limit for resending OTP. Please wait before trying again."
        }
    }
} 