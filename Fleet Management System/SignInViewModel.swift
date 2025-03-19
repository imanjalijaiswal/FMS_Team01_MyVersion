//
//  SignInViewModel.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 18/03/25.
//

import Foundation

@MainActor
class SignInViewModel: ObservableObject {
    
//    func registerNewUserWithEmail(email: String, password: String) async throws -> AppUser {
//        guard isFormValid(email: email, password: password) else {
//            throw AuthError.invalidForm
//        }
//        return try await AuthManager.shared.registerNewUserWithEmail(email: email, password: password)
//    }
    
    func signInWithEmail(email: String, password: String) async throws -> AppUser {
        guard isFormValid(email: email, password: password) else {
            throw AuthError.invalidCredentials 
        }
        return try await AuthManager.shared.signInWithEmail(email: email, password: password)
    }
    
    private func isFormValid(email: String, password: String) -> Bool {
        return email.isValidEmail() && password.count >= 8
    }
}

// MARK: - Custom Auth Errors
enum AuthError: LocalizedError {
    case invalidForm
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .invalidForm:
            return "❌ Invalid email or password. Password must be at least 8 characters."
        case .invalidCredentials:
            return "❌ Email or password incorrect."
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
