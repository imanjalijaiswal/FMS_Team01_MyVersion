import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PasswordResetViewModel()
    @Binding var user: AppUser?
    @Binding var isFirstTimeLogin: Bool
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSuccess = false
    
    private var shouldShowPandaEyesOpen: Bool {
        isPasswordVisible || isConfirmPasswordVisible
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryGradientStart)
                            .frame(width: 120, height: 120)
                        
                        Image(shouldShowPandaEyesOpen ? "panda-open" : "panda-closed")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 110, height: 110)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                    
                    Text("First-Time Login")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Please set a new password to continue")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Password")
                            .foregroundColor(.black)
                            .padding(.leading)
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("Enter new password", text: $newPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .onChange(of: newPassword) { _ in
                                        viewModel.validatePasswordCriteria(password: newPassword, confirmPassword: confirmPassword)
                                    }
                            } else {
                                SecureField("Enter new password", text: $newPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .onChange(of: newPassword) { _ in
                                        viewModel.validatePasswordCriteria(password: newPassword, confirmPassword: confirmPassword)
                                    }
                            }
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Password validation criteria feedback
                        VStack(alignment: .leading, spacing: 5) {
                            PasswordRequirementRow(
                                isMet: viewModel.hasMinLength,
                                text: "At least 8 characters long"
                            )
                            
                            PasswordRequirementRow(
                                isMet: viewModel.hasLowercase,
                                text: "Include at least 1 lowercase letter"
                            )
                            
                            PasswordRequirementRow(
                                isMet: viewModel.hasUppercase,
                                text: "Include at least 1 uppercase letter"
                            )
                            
                            PasswordRequirementRow(
                                isMet: viewModel.hasDigit,
                                text: "Include at least 1 number"
                            )
                            
                            PasswordRequirementRow(
                                isMet: viewModel.hasSpecialChar,
                                text: "Include at least 1 special character (!@#$%^&*)"
                            )
                        }
                        .padding(.top, 8)
                        .padding(.leading, 4)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .foregroundColor(.black)
                            .padding(.leading)
                        
                        HStack {
                            if isConfirmPasswordVisible {
                                TextField("Confirm new password", text: $confirmPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .onChange(of: confirmPassword) { _ in
                                        viewModel.validatePasswordCriteria(password: newPassword, confirmPassword: confirmPassword)
                                    }
                            } else {
                                SecureField("Confirm new password", text: $confirmPassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .onChange(of: confirmPassword) { _ in
                                        viewModel.validatePasswordCriteria(password: newPassword, confirmPassword: confirmPassword)
                                    }
                            }
                            
                            Button(action: {
                                isConfirmPasswordVisible.toggle()
                            }) {
                                Image(systemName: isConfirmPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Password match validation
                        if !confirmPassword.isEmpty {
                            PasswordRequirementRow(
                                isMet: viewModel.passwordsMatch,
                                text: "Passwords match"
                            )
                            .padding(.top, 5)
                            .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Password strength feedback
                    if viewModel.isPasswordValid {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Strong password!")
                                .foregroundColor(.green)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.top, 5)
                    }
                    
                    // Show error message if reset fails
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true) // Allows text to expand vertically
                    }
                    
                    // Reset Button
                    Button(action: {
                        resetPassword()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isLoading ? "Saving..." : "Set New Password")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : (viewModel.isPasswordValid ? Color.primaryGradientStart : Color.gray.opacity(0.5)))
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || !viewModel.isPasswordValid)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                }
                .padding(.top, 10)
                .padding(.bottom, 20)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            // Success message overlay
            if showSuccess {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Close button
                    HStack {
                        Button(action: {
                            navigateToMainApp()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                                .padding()
                        }
                        Spacer()
                    }
                    
                    Spacer()
                    
                    Text("Password Updated!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Your password has been successfully updated. You can now log in with your new password.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Green checkmark circle
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 30)
                    
                    Button(action: {
                        navigateToMainApp()
                    }) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 52/255, green: 120/255, blue: 120/255))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            // Initialize validation on first appearance
            viewModel.validatePasswordCriteria(password: newPassword, confirmPassword: confirmPassword)
        }
    }
    
    // Password requirement row
    private struct PasswordRequirementRow: View {
        let isMet: Bool
        let text: String
        
        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isMet ? .green : .gray)
                
                Text(text)
                    .font(.caption)
                    .foregroundColor(isMet ? .green : .gray)
            }
        }
    }
    
    private func resetPassword() {
        hideKeyboard()
        
        // Only proceed if we have a user and all validation criteria are met
        guard viewModel.isPasswordValid else {
            if !viewModel.hasMinLength {
                errorMessage = "⚠️ Password must be at least 8 characters long."
            } else if !viewModel.hasLowercase {
                errorMessage = "⚠️ Include at least 1 lowercase letter."
            } else if !viewModel.hasUppercase {
                errorMessage = "⚠️ Include at least 1 uppercase letter."
            } else if !viewModel.hasDigit {
                errorMessage = "⚠️ Include at least 1 number."
            } else if !viewModel.hasSpecialChar {
                errorMessage = "⚠️ Include at least 1 special character."
            } else if !viewModel.passwordsMatch {
                errorMessage = "⚠️ Passwords do not match."
            } else {
                errorMessage = "⚠️ Password doesn't meet all requirements."
            }
            return
        }
        
        isLoading = true
        
        // Only proceed if we have a user
        guard let currentUser = user else {
            errorMessage = "⚠️ User information not available."
            isLoading = false
            return
        }
        
        Task {
            do {
                // Update password and mark first login as completed
                try await viewModel.updatePasswordAndFirstTimeLoginStatus(
                    userId: currentUser.id.uuidString,
                    email: currentUser.meta_data.email,
                    newPassword: newPassword
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = nil
                    self.showSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ Failed to reset password: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func navigateToMainApp() {
        // Update the firstTimeLogin flag to immediately transition to the main app
        DispatchQueue.main.async {
            self.isFirstTimeLogin = false
            self.showSuccess = false
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
