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
                
                VStack(spacing: 20) {
                    // Title and subtitle
                    Text(stepTitle)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(stepSubtitle)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
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
                    
                    Spacer()
                }
                .padding(.top, 40)
                .padding(.horizontal)
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
        VStack(spacing: 20) {
            // Info box
            VStack(alignment: .leading, spacing: 8) {
                Text("Check your email")
                    .font(.headline)
                
                Text("We'll send a verification code to your email. Please enter the code on the next screen.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                
                TextField("Enter your email", text: $viewModel.email)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
            }
            
            // Send Verification Code Button
            Button(action: requestOTP) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Send Verification Code")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(isLoading || viewModel.email.isEmpty ? Color.gray.opacity(0.5) : Color.primaryGradientStart)
            .cornerRadius(12)
            .disabled(isLoading || viewModel.email.isEmpty)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
    }
    
    private var otpVerificationView: some View {
        VStack(spacing: 20) {
            // Info box
            VStack(alignment: .leading, spacing: 8) {
                Text("Check your email")
                    .font(.headline)
                
                Text("We've sent a verification link and code to your email. You can either click the link in the email or enter the code manually here.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.headline)
                
                TextField("Enter 6-digit code", text: $viewModel.otpCode)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.otpCode) { newValue in
                        if newValue.count > 6 {
                            viewModel.otpCode = String(newValue.prefix(6))
                        }
                        viewModel.otpCode = newValue.filter { $0.isNumber }
                    }
            }
            
            // Verify Button
            Button(action: verifyOTP) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(isLoading || !viewModel.isValidOTP ? Color.gray.opacity(0.5) : Color.primaryGradientStart)
            .cornerRadius(12)
            .disabled(isLoading || !viewModel.isValidOTP)
            
            Text(viewModel.isResendButtonEnabled ? "Resend Code" : "Resend Code in \(viewModel.remainingTime)s")
                .foregroundColor(viewModel.isResendButtonEnabled ? Color.primaryGradientStart : .gray)
                .font(.subheadline)
                .onTapGesture {
                    if viewModel.isResendButtonEnabled && !isLoading {
                        Task {
                            await requestOTP()
                        }
                    }
                }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
    }
    
    private var newPasswordView: some View {
        VStack(spacing: 20) {
            // Info box
            VStack(alignment: .leading, spacing: 8) {
                Text("Create New Password")
                    .font(.headline)
                
                Text("Please enter a new password that is different from your current password.")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("New Password")
                    .font(.headline)
                
                HStack {
                    if viewModel.isNewPasswordVisible {
                        TextField("Enter new password", text: $viewModel.newPassword)
                    } else {
                        SecureField("Enter new password", text: $viewModel.newPassword)
                    }
                    
                    Button(action: {
                        viewModel.isNewPasswordVisible.toggle()
                    }) {
                        Image(systemName: viewModel.isNewPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                    }
                }
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Text("Password must be at least 8 characters")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.headline)
                
                HStack {
                    if viewModel.isConfirmPasswordVisible {
                        TextField("Confirm new password", text: $viewModel.confirmPassword)
                    } else {
                        SecureField("Confirm new password", text: $viewModel.confirmPassword)
                    }
                    
                    Button(action: {
                        viewModel.isConfirmPasswordVisible.toggle()
                    }) {
                        Image(systemName: viewModel.isConfirmPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                    }
                }
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Update Password Button
            Button(action: updatePassword) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Update Password")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(isLoading || !viewModel.isPasswordValid ? Color.gray.opacity(0.5) : Color.primaryGradientStart)
            .cornerRadius(12)
            .disabled(isLoading || !viewModel.isPasswordValid)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
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
        
        Task {
            do {
                try await viewModel.updatePassword()
            } catch PasswordResetError.sameAsCurrentPassword {
                errorMessage = "⚠️ Please enter a different password. You cannot use your current password."
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

#Preview {
    ForgotPasswordView(isPresented: .constant(true))
} 