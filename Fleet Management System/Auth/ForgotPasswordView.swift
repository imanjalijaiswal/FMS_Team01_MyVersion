import SwiftUI

struct ForgotPasswordView: View {
    @Binding var isPresented: Bool
    @StateObject private var viewModel = ForgotPasswordViewModel()
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Header
                    headerView
                    
                    // Current step content
                    Group {
                        switch viewModel.currentStep {
                        case .emailEntry:
                            emailEntryView
                        case .otpVerification:
                            otpVerificationView
                        case .newPasswordEntry:
                            newPasswordView
                        case .completed:
                            completedView
                        }
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.top, 10)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack {
            Text(stepTitle)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 30)
            
            Text(stepSubtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var stepTitle: String {
        switch viewModel.currentStep {
        case .emailEntry:
            return "Reset Password"
        case .otpVerification:
            return "Enter Verification Code"
        case .newPasswordEntry:
            return "Create New Password"
        case .completed:
            return "Password Updated!"
        }
    }
    
    private var stepSubtitle: String {
        switch viewModel.currentStep {
        case .emailEntry:
            return "Enter your email and we'll send you a verification code"
        case .otpVerification:
            return "We've sent a 6-digit verification code to your email. Please check your inbox and enter the code below."
        case .newPasswordEntry:
            return "Create a new password for your account"
        case .completed:
            return "Your password has been successfully updated. You can now log in with your new password."
        }
    }
    
    // MARK: - Step Views
    
    private var emailEntryView: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .foregroundColor(.black)
                    .padding(.leading)
                
                TextField("Enter your email", text: $viewModel.email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Request OTP Button
            actionButton(
                title: "Send Verification Code",
                isLoading: isLoading,
                loadingTitle: "Sending...",
                action: requestOTP
            )
            .disabled(isLoading || viewModel.email.isEmpty)
        }
    }
    
    private var otpVerificationView: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .foregroundColor(.black)
                    .padding(.leading)
                
                TextField("Enter 6-digit code", text: $viewModel.otpCode)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.otpCode) { newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            viewModel.otpCode = String(newValue.prefix(6))
                        }
                        
                        // Remove non-numeric characters
                        viewModel.otpCode = newValue.filter { $0.isNumber }
                    }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Verify OTP Button
            actionButton(
                title: "Verify Code",
                isLoading: isLoading,
                loadingTitle: "Verifying...",
                action: verifyOTP
            )
            .disabled(isLoading || viewModel.otpCode.count != 6)
            
            // Resend Code with Timer
            Button(action: {
                Task {
                    await requestOTP()
                }
            }) {
                Text(viewModel.isResendButtonEnabled ? "Resend Code" : "Resend Code in \(viewModel.remainingTime)s")
                    .foregroundColor(viewModel.isResendButtonEnabled ? Color.primaryGradientStart : .gray)
                    .font(.subheadline)
            }
            .padding(.top, 15)
            .disabled(isLoading || !viewModel.isResendButtonEnabled)
        }
    }
    
    private var newPasswordView: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("New Password")
                    .foregroundColor(.black)
                    .padding(.leading)
                
                SecureField("Enter new password", text: $viewModel.newPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .foregroundColor(.black)
                    .padding(.leading)
                
                SecureField("Confirm new password", text: $viewModel.confirmPassword)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Update Password Button
            actionButton(
                title: "Update Password",
                isLoading: isLoading,
                loadingTitle: "Updating...",
                action: updatePassword
            )
            .disabled(isLoading || viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty)
        }
    }
    
    private var completedView: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(Color.green)
                .padding(.bottom, 20)
            
            Button(action: {
                isPresented = false
            }) {
                Text("Return to Login")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGradientStart)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Reusable Components
    
    private func actionButton(title: String, isLoading: Bool, loadingTitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                Text(isLoading ? loadingTitle : title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading ? Color.gray : Color.primaryGradientStart)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func requestOTP() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                try await viewModel.requestOTP()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func verifyOTP() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                try await viewModel.verifyOTP()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func updatePassword() {
        errorMessage = nil
        isLoading = true
        
        // Validate passwords match
        if viewModel.newPassword != viewModel.confirmPassword {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }
        
        Task {
            do {
                try await viewModel.updatePassword()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView(isPresented: .constant(true))
} 