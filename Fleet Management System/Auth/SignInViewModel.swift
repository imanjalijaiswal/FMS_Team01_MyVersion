//
//  SignInViewModel.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 18/03/25.
//

import Foundation

// Custom Auth Errors defined locally
enum AuthError: LocalizedError {
    case invalidForm
    case invalidCredentials
    case invalidEmail
    case emptyFields
    case passwordTooShort
    
    var errorDescription: String? {
        switch self {
        case .invalidForm:
            return "❌ Invalid email or password. Password must be at least 8 characters."
        case .invalidCredentials:
            return "❌ Email or password incorrect."
        case .invalidEmail:
            return "❌ Invalid email format."
        case .emptyFields:
            return "❌ Email and password fields cannot be empty."
        case .passwordTooShort:
            return "❌ Password must be at least 6 characters."
        }
    }
}

@MainActor
class SignInViewModel: ObservableObject {
    @Published var is2FARequired = false
    private var tempAuthenticatedUser: AppUser?
    private let authManager = AuthManager.shared
    
    //    func registerNewUserWithEmail(email: String, password: String) async throws -> AppUser {
    //        guard isFormValid(email: email, password: password) else {
    //            throw AuthError.invalidForm
    //        }
    //        return try await AuthManager.shared.registerNewUserWithEmail(email: email, password: password)
    //    }
    
    // Sign in with email and password
    func signInWithEmail(email: String, password: String) async throws -> AppUser? {
        guard let validatedEmail = email.isValidEmail() ? email : nil else {
            throw AuthError.invalidEmail
        }
        
        try await validateForm(email: validatedEmail, password: password)
        
        do {
            // Use the new 2FA method instead of the regular sign-in
            let user = try await authManager.signInWithEmailAndInitiate2FA(email: validatedEmail, password: password)
            
            // If we got a user back and 2FA is enabled, set flag and temp user
            if AuthManager.is2FAEnabled, let authUser = user {
                is2FARequired = true
                tempAuthenticatedUser = authUser
                return nil
            }
            
            // Otherwise just return the user directly (2FA disabled or not required)
            return user
        } catch {
            // Convert NSError to AuthError if needed
            if let nsError = error as NSError?,
               nsError.domain == "Auth" && nsError.code == 401 {
                throw AuthError.invalidCredentials
            }
            throw error
        }
    }
    
    // Get the authenticated user (for 2FA process)
    func getAuthenticatedUser() -> AppUser? {
        return tempAuthenticatedUser
    }
    
    // MARK: - Private Methods
    
    private func validateForm(email: String, password: String) async throws {
        // Validation logic
        if email.isEmpty || password.isEmpty {
            throw AuthError.emptyFields
        }
        
        if password.count < 6 {
            throw AuthError.passwordTooShort
        }
    }
}

// MARK: - Email Validation Extension
extension String {
    func isValidEmail() -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)
    }
}
