import Foundation

@MainActor
class TwoFactorViewModel: ObservableObject {
    @Published var verificationCode: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasSentCode: Bool = false
    @Published var remainingTime: Int = 60
    @Published var isResendButtonEnabled: Bool = false
    
    private let authManager = AuthManager.shared
    private let authenticatedUser: AppUser
    private var timer: Timer?
    
    var isValidOTP: Bool {
        verificationCode.count == 6 && verificationCode.allSatisfy { $0.isNumber }
    }
    
    init(user: AppUser) {
        self.authenticatedUser = user
        // Start the timer immediately when view model is initialized
        startResendTimer()
    }
    
    func startResendTimer() {
        remainingTime = 60
        isResendButtonEnabled = false
        
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
    
    // Send verification code
    func sendVerificationCode() async throws {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // Generate and send code via AuthManager
            let email = authenticatedUser.meta_data.email
            try await authManager.generateAndSend2FACode(email: email)
            self.isLoading = false
            self.hasSentCode = true
            self.errorMessage = "Verification code sent to \(email)"
            self.startResendTimer() // Restart the timer when code is resent
        } catch {
            self.isLoading = false
            self.errorMessage = "Failed to send verification code: \(error.localizedDescription)"
            throw error
        }
    }
    
    // Verify the entered code
    func verifyCode() async -> Bool {
        let email = authenticatedUser.meta_data.email
        
        do {
            // Use Supabase's OTP verification
            let isVerified = try await authManager.verify2FACode(email: email, token: verificationCode)
            
            if !isVerified {
                errorMessage = "Invalid verification code. Please try again."
            } else {
                errorMessage = nil
                // The 2FA flag is already set in verify2FACode, but we can explicitly call mark2FACompleted
                // to ensure it's set in all cases
                authManager.mark2FACompleted()
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
    
    deinit {
        timer?.invalidate()
    }
} 
