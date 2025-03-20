import Foundation

@MainActor
class PasswordResetViewModel: ObservableObject {
    private let authManager = AuthManager.shared
    
    /// Updates the user's password and marks firstTimeLogin as false
    func updatePasswordAndFirstTimeLoginStatus(userId: String, email: String, newPassword: String) async throws {
        // Update the user's password
        try await authManager.updateUserPassword(email: email, password: newPassword)
        
        // Update the firstTimeLogin flag to false
        try await authManager.updateFirstTimeLoginStatus(userId: userId, firstTimeLogin: false)
    }
} 