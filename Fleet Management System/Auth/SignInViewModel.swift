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
    case inactiveUser
    case otpRateLimit
    
    var errorDescription: String? {
        switch self {
        case .invalidForm:
            return "Email or password is incorrect."
        case .invalidCredentials:
            return "Email or password is incorrect."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emptyFields:
            return "Please enter your email and password."
        case .inactiveUser:
            return "Your account is currently inactive. Please contact your administrator."
        case .otpRateLimit:
            return "Please wait before requesting another OTP. Try again in a few seconds."
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
            
            // If the user is null or not found, return nil
            guard let authUser = user else {
                return nil
            }
            
            // Check if this is a first-time login
            let isFirstTimeLogin = try await authManager.checkFirstTimeLogin(userId: authUser.id.uuidString)
            
            // Skip 2FA if it's a first-time login
            if isFirstTimeLogin {
                return authUser  // Return the user directly, bypassing 2FA
            }
            
            // Otherwise, if 2FA is required, set up for 2FA
            if AuthManager.is2FAEnabled {
                is2FARequired = true
                tempAuthenticatedUser = authUser
                return nil
            }
            
            // Otherwise just return the user directly (2FA disabled)
            return authUser
        } catch let error as AuthError {
            switch error {
            case .inactiveUser:
                throw AuthError.inactiveUser
            case .invalidCredentials:
                throw AuthError.invalidCredentials
            default:
                throw AuthError.invalidCredentials
            }
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
