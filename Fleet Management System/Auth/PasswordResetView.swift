import SwiftUI

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PasswordResetViewModel()
    @Binding var user: AppUser?
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 25) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGradientStart)
                        .frame(width: 120, height: 120)
                    
                    Image("panda-open")
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
                        } else {
                            SecureField("Enter new password", text: $newPassword)
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
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .foregroundColor(.black)
                        .padding(.leading)
                    
                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("Confirm new password", text: $confirmPassword)
                        } else {
                            SecureField("Confirm new password", text: $confirmPassword)
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
                }
                .padding(.horizontal)
                
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
                    .background(isLoading ? Color.gray : Color.primaryGradientStart)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                // Show error message if reset fails
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }
                
                Spacer()
            }
            .padding(.top, 30)
            .contentShape(Rectangle())
            .onTapGesture {
                hideKeyboard()
            }
            
            // Success message overlay
            if showSuccess {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Password reset successful!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top)
                    
                    Button("Continue") {
                        // Continue to the main app
                        showSuccess = false
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                    .padding(.top, 20)
                }
                .padding(30)
                .background(Color.gray.opacity(0.9))
                .cornerRadius(20)
            }
        }
    }
    
    private func resetPassword() {
        hideKeyboard()
        
        // Validate passwords
        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "⚠️ Please enter both passwords."
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "⚠️ Password must be at least 6 characters."
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "⚠️ Passwords do not match."
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
                    userId: currentUser.id,
                    email: currentUser.email ?? "",
                    newPassword: newPassword
                )
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = nil
                    self.showSuccess = true
                    
                    // After a short delay, dismiss and continue to the main app
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.showSuccess = false
                        // No need to set user here as it's already set
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ Failed to reset password: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    PasswordResetView(user: .constant(AppUser(id: "123", email: "test@example.com", role: .driver)))
} 