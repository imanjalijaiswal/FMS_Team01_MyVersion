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
    
    // Password validation properties
    @Published var hasMinLength: Bool = false
    @Published var hasLowercase: Bool = false
    @Published var hasUppercase: Bool = false
    @Published var hasDigit: Bool = false
    @Published var hasSpecialChar: Bool = false
    @Published var passwordsMatch: Bool = false
    
    private var timer: Timer?
    private let minimumResendInterval: TimeInterval = 60 // 60 seconds minimum between resends
    
    var isValidOTP: Bool {
        otpCode.count == 6 && otpCode.allSatisfy { $0.isNumber }
    }
    
    var isPasswordValid: Bool {
        hasMinLength && hasLowercase && hasUppercase && hasDigit && hasSpecialChar && 
        newPassword == confirmPassword
    }
    
    enum PasswordResetStep {
        case emailEntry
        case otpVerification
        case newPasswordEntry
        case completed
    }
    
    // MARK: - Password Validation
    
    /// Validates the password criteria in real-time
    func validatePasswordCriteria() {
        // Check minimum length (8 characters)
        hasMinLength = newPassword.count >= 8
        
        // Check for lowercase letter
        hasLowercase = newPassword.range(of: "[a-z]", options: .regularExpression) != nil
        
        // Check for uppercase letter
        hasUppercase = newPassword.range(of: "[A-Z]", options: .regularExpression) != nil
        
        // Check for digit
        hasDigit = newPassword.range(of: "[0-9]", options: .regularExpression) != nil
        
        // Check for special character
        hasSpecialChar = newPassword.range(of: "[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?]", options: .regularExpression) != nil
        
        // Check if passwords match
        passwordsMatch = newPassword == confirmPassword
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
        guard isPasswordValid else {
            if !hasMinLength {
                throw PasswordResetError.passwordTooShort
            } else if !hasLowercase {
                throw PasswordResetError.noLowercase
            } else if !hasUppercase {
                throw PasswordResetError.noUppercase
            } else if !hasDigit {
                throw PasswordResetError.noDigit
            } else if !hasSpecialChar {
                throw PasswordResetError.noSpecialChar
            } else {
                throw PasswordResetError.passwordsDoNotMatch
            }
        }
        
        // Check if new password is same as current password
        do {
            let isSamePassword = try await AuthManager.shared.checkIfSamePassword(
                email: email,  // Use the email from the current flow
                password: newPassword
            )
            if isSamePassword {
                throw PasswordResetError.sameAsCurrentPassword
            }
        } catch {
            // If checkIfSamePassword throws an error, it means either:
            // 1. The sign-in failed (different password)
            // 2. There was a network error
            // In case #1, we can proceed with the password update
            // In case #2, we should throw the error
            if let authError = error as? AuthError {
                // This is case #1, we can proceed
                print("Password is different, proceeding with update")
            } else {
                // This is case #2, rethrow the error
                throw error
            }
        }
        
        // Update password using Supabase
        try await AuthManager.shared.updateUserPassword(email: email, password: newPassword)
        currentStep = .completed
    }
    
    private func validatePassword() -> Bool {
        return isPasswordValid
    }
    
    deinit {
        timer?.invalidate()
    }
}

enum PasswordResetError: LocalizedError {
    case invalidEmail
    case invalidOTP
    case invalidPassword
    case passwordTooShort
    case noLowercase
    case noUppercase
    case noDigit
    case noSpecialChar
    case passwordsDoNotMatch
    case resetFailed
    case sameAsCurrentPassword
    case otpRateLimit
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidOTP:
            return "The verification code is incorrect. Please try again."
        case .invalidPassword:
            return "Password does not meet all requirements."
        case .passwordTooShort:
            return "Password must be at least 8 characters long."
        case .noLowercase:
            return "Include at least 1 lowercase letter."
        case .noUppercase:
            return "Include at least 1 uppercase letter."
        case .noDigit:
            return "Include at least 1 number."
        case .noSpecialChar:
            return "Include at least 1 special character (!@#$%^&*)."
        case .passwordsDoNotMatch:
            return "Passwords do not match."
        case .resetFailed:
            return "Failed to reset password. Please try again."
        case .sameAsCurrentPassword:
            return "⚠️ New password must be different from your current password."
        case .otpRateLimit:
            return "You have reached the rate limit for resending OTP. Please wait before trying again."
        }
    }
} 