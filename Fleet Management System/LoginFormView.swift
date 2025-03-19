import SwiftUI

struct LoginFormView: View {
    @StateObject private var viewModel = SignInViewModel()
    
    @State private var errorMessage: String?
    @Binding var user: AppUser?
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isBlinking = false
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 25) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGradientStart)
                        .frame(width: 150, height: 150)
                    
                    Image(isPasswordVisible ? "panda-open" : "panda-closed")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 135, height: 135)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.2), value: isPasswordVisible)
                }
                .padding(.bottom, 20)
                
                Text("Welcome To")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("InFleet Express")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .foregroundColor(.black)
                        .padding(.leading)
                    
                    TextField("Enter your email", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .foregroundColor(.black)
                        .padding(.leading)
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("Enter password", text: $password)
                        } else {
                            SecureField("Enter password", text: $password)
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
                
                // Login Button
                Button(action: {
                    handleSignIn()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isLoading ? "Logging in..." : "Log In")
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
                
                // Show error message if login fails
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
    
    // MARK: - Authentication Handlers
    
    private func handleSignIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "⚠️ Please enter email and password."
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let signedInUser = try await viewModel.signInWithEmail(email: email, password: password)
                DispatchQueue.main.async {
                    self.user = signedInUser
                    self.errorMessage = nil
                    self.isLoading = false
                }
            } catch let authError as AuthError {
                DispatchQueue.main.async {
                    self.errorMessage = authError.localizedDescription
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ Something went wrong. Please try again."
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginFormView(user: .constant(nil))
}
