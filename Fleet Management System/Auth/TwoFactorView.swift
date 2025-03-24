import SwiftUI

struct TwoFactorView: View {
    @StateObject private var viewModel: TwoFactorViewModel
    @Binding var user: AppUser?
    @State private var isLoading = false
    
    init(authenticatedUser: AppUser, user: Binding<AppUser?>) {
        _viewModel = StateObject(wrappedValue: TwoFactorViewModel(user: authenticatedUser))
        _user = user
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Header
                VStack {
                    Text("Two-Factor Authentication")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Please click the link sent to your email or enter the verification code from the email")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 50)
                
                // Info box
                VStack(alignment: .leading, spacing: 10) {
                    Text("Check your email")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("We've sent a verification link and code to your email. You can either click the link in the email or enter the code manually here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Verification code input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification Code")
                        .foregroundColor(.black)
                        .padding(.leading)
                    
                    TextField("Enter 6-digit code", text: $viewModel.verificationCode)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.verificationCode) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                viewModel.verificationCode = String(newValue.prefix(6))
                            }
                            
                            // Remove non-numeric characters
                            viewModel.verificationCode = newValue.filter { $0.isNumber }
                        }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Verify Button
                Button(action: verifyCode) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isLoading ? "Verifying..." : "Verify")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isLoading ? Color.gray : Color.primaryGradientStart)
                    .cornerRadius(12)
                }
                .disabled(isLoading || viewModel.verificationCode.count != 6)
                .padding(.horizontal)
                
                // Resend Code
                Button(action: {
                    Task {
                        await sendVerificationCode()
                    }
                }) {
                    Text("Resend Code")
                        .foregroundColor(Color.primaryGradientStart)
                        .font(.subheadline)
                }
                .padding(.top, 15)
                .disabled(isLoading)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.top, 10)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
    }
    
    private func sendVerificationCode() async {
        do {
            try await viewModel.sendVerificationCode()
        } catch {
            print("Failed to send verification code: \(error)")
        }
    }
    
    private func verifyCode() {
        isLoading = true
        
        // Async verification
        Task {
            // Verify the code
            let isVerified = await viewModel.verifyCode()
            
            // Update UI on main thread
            await MainActor.run {
                if isVerified {
                    // Set the authenticated user
                    user = viewModel.getAuthenticatedUser()
                }
                
                isLoading = false
            }
        }
    }
}
