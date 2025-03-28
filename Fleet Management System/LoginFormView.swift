import SwiftUI

struct LoginFormView: View {
    @StateObject private var viewModel = SignInViewModel()
    
    @State private var errorMessage: String?
    @Binding var user: AppUser?
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var pandaEyesOpen: Bool = true  // New explicit state for panda eyes
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @State private var isBlinking = false
    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var show2FAView = false
    @State private var tempAuthenticatedUser: AppUser?
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 25) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGradientStart)
                        .frame(width: 150, height: 150)
                    
                    Image(pandaEyesOpen ? "panda-open" : "panda-closed")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 135, height: 135)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 0.3), value: pandaEyesOpen)
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
                        .focused($isEmailFocused)
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
                                .focused($isPasswordFocused)
                        } else {
                            SecureField("Enter password", text: $password)
                                .focused($isPasswordFocused)
                        }
                        
                        Button(action: {
                            // Toggle password visibility and explicitly update panda eyes
                            isPasswordVisible.toggle()
                            
                            // Use explicit animation and make sure it's applied
                            withAnimation(.easeInOut(duration: 0.3)) {
                                // Always update panda eyes based on password visibility
                                // when the eye button is pressed
                                pandaEyesOpen = isPasswordVisible
                            }
                            
                            // Double-check the update with slight delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    pandaEyesOpen = isPasswordVisible
                                }
                            }
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.gray)
                                .contentShape(Rectangle())
                                .frame(width: 35, height: 35) // Larger tap target
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .onTapGesture {
                        // Force close eyes immediately when tapping on password field
                        pandaEyesOpen = false
                        
                        // Set focus with slight delay to avoid race conditions
                        DispatchQueue.main.async {
                            isPasswordFocused = true
                            
                            // Ensure eyes are still closed after focus change
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if !isPasswordVisible {
                                        pandaEyesOpen = false
                                    }
                                }
                            }
                        }
                    }
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
                
                // Forgot Password Button
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(Color.primaryGradientStart)
                        .font(.subheadline)
                }
                .padding(.top, 5)
                
                // Show error message if login fails
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .padding(.horizontal)
                        .padding(.top, 5)
                }
                
                Spacer()
            }
            .padding(.top, 60)
            .contentShape(Rectangle()) // Make the whole content tappable
            .onTapGesture {
                hideKeyboard()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView(isPresented: $showForgotPassword)
            }
        }
        .onChange(of: isPasswordFocused) { _, newValue in
            if newValue {
                // When password field is focused, ALWAYS close eyes
                // Use DispatchQueue to ensure this happens reliably
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pandaEyesOpen = false
                    }
                }
                
                // Add a second update with slight delay to ensure the change persists
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        // Only update if still focused and eye icon is not showing
                        if isPasswordFocused && !isPasswordVisible {
                            pandaEyesOpen = false
                        }
                    }
                }
            } else {
                // When password field loses focus, eyes open
                withAnimation(.easeInOut(duration: 0.2)) {
                    pandaEyesOpen = true
                }
            }
        }
        .onChange(of: isEmailFocused) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                // Email field always has open eyes
                pandaEyesOpen = true
            }
        }
        .sheet(isPresented: $show2FAView) {
            if let tempUser = tempAuthenticatedUser {
                TwoFactorView(authenticatedUser: tempUser, user: $user)
            }
        }
    }
    
    // MARK: - Authentication Handlers
    
    private func handleSignIn() {
        hideKeyboard()
        
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let signedInUser = try await viewModel.signInWithEmail(email: email, password: password)
                
                DispatchQueue.main.async {
                    if viewModel.is2FARequired, let tempUser = viewModel.getAuthenticatedUser() {
                        // If 2FA is required, show the 2FA view
                        self.tempAuthenticatedUser = tempUser
                        self.show2FAView = true
                        self.errorMessage = nil
                    } else {
                        // If no 2FA required, set the user directly
                        self.user = signedInUser
                        self.errorMessage = nil
                    }
                    self.isLoading = false
                }
            } catch let authError as AuthError {
                DispatchQueue.main.async {
                    self.errorMessage = authError.localizedDescription
                    self.isLoading = false
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    // Handle Supabase rate limit error
                    if error.domain == "Auth" && error.code == 429 {
                        self.errorMessage = "Please wait before requesting another OTP. Try again in a few seconds."
                    } else {
                        self.errorMessage = "Something went wrong. Please try again."
                    }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Something went wrong. Please try again."
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Keyboard Handling
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginFormView(user: .constant(nil))
}
