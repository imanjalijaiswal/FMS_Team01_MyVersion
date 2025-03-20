import Foundation

@MainActor
class TwoFactorViewModel: ObservableObject {
    @Published var verificationCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let authManager = AuthManager.shared
    private let authenticatedUser: AppUser
    
    init(user: AppUser) {
        self.authenticatedUser = user
    }
    
    // Send verification code
    func sendVerificationCode() async throws {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // Generate and send code via AuthManager
            if let email = authenticatedUser.email {
                // Just send the OTP, we don't need to store the actual code anymore
                // since Supabase will handle verification
                try await authManager.generateAndSend2FACode(email: email)
                self.isLoading = false
                self.errorMessage = "Verification code sent to \(email)"
            } else {
                self.isLoading = false
                self.errorMessage = "User email not available"
                throw NSError(domain: "TwoFactorError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User email not available"])
            }
        } catch {
            self.isLoading = false
            self.errorMessage = "Failed to send verification code: \(error.localizedDescription)"
            throw error
        }
    }
    
    // Verify the entered code
    func verifyCode() async -> Bool {
        guard let email = authenticatedUser.email else {
            errorMessage = "User email not available"
            return false
        }
        
        do {
            // Use Supabase's OTP verification
            let isVerified = try await authManager.verifyOTP(email: email, token: verificationCode)
            
            if !isVerified {
                errorMessage = "Invalid verification code. Please try again."
            } else {
                errorMessage = nil
            }
            
            return isVerified
        } catch {
            errorMessage = "Failed to verify code: \(error.localizedDescription)"
            return false
        }
    }
    
    // Get the authenticated user
    func getAuthenticatedUser() -> AppUser {
        return authenticatedUser
    }
} 