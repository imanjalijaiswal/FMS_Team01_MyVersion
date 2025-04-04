import Foundation

@MainActor
class PasswordResetViewModel: ObservableObject {
    private let authManager = AuthManager.shared
    
    // Password validation properties
    @Published var hasMinLength: Bool = false
    @Published var hasLowercase: Bool = false
    @Published var hasUppercase: Bool = false
    @Published var hasDigit: Bool = false
    @Published var hasSpecialChar: Bool = false
    @Published var passwordsMatch: Bool = false
    
    var isPasswordValid: Bool {
        hasMinLength && hasLowercase && hasUppercase && hasDigit && hasSpecialChar && passwordsMatch
    }
    
    /// Validates the password criteria in real-time
    func validatePasswordCriteria(password: String, confirmPassword: String) {
        // Check minimum length (8 characters)
        hasMinLength = password.count >= 8
        
        // Check for lowercase letter
        hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        
        // Check for uppercase letter
        hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        
        // Check for digit
        hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        // Check for special character
        hasSpecialChar = password.range(of: "[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>/?]", options: .regularExpression) != nil
        
        // Check if passwords match
        passwordsMatch = !confirmPassword.isEmpty && password == confirmPassword
    }
    
    /// Updates the user's password and marks firstTimeLogin as false
    func updatePasswordAndFirstTimeLoginStatus(userId: String, email: String, newPassword: String) async throws {
        // Validate password criteria before updating
        guard isPasswordValid else {
            throw PasswordUpdateError.invalidPassword
        }
        
        // Update the user's password
        try await authManager.updateUserPassword(email: email, password: newPassword)
        
        // Update the firstTimeLogin flag to false
        try await authManager.updateFirstTimeLoginStatus(userId: userId, firstTimeLogin: false)
        
        // Clear any cached user state to ensure fresh data
        authManager.clearUserCache(userId: userId)
    }
}

// Password update error types
enum PasswordUpdateError: LocalizedError {
    case invalidPassword
    case passwordTooShort
    case noLowercase
    case noUppercase
    case noDigit
    case noSpecialChar
    case passwordsDoNotMatch
    
    var errorDescription: String? {
        switch self {
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
        }
    }
} 