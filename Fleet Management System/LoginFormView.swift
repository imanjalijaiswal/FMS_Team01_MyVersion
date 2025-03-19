//
//  LoginFormView.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 19/03/25.
//

import Foundation

import SwiftUI

struct LoginFormView: View {
    @StateObject private var viewModel = SignInViewModel()
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    
    @Binding var user: AppUser?

    var body: some View {
        VStack(spacing: 20) {
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Button(action: handleSignIn) {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            

        }
        .padding()
    }
    
    // MARK: - Authentication Handlers

    private func handleSignIn() {
        Task {
            do {
                let signedInUser = try await viewModel.signInWithEmail(email: email, password: password)
                DispatchQueue.main.async {
                    self.user = signedInUser
                    self.errorMessage = nil
                }
            } catch let authError as AuthError {
                DispatchQueue.main.async {
                    self.errorMessage = authError.localizedDescription  
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ Something went wrong. Please try again."
                }
            }
        }
    }


    
//    private func handleSignUp() {
//        Task {
//            do {
//                user = try await viewModel.registerNewUserWithEmail(email: email, password: password)
//                errorMessage = nil
//            } catch {
//                errorMessage = error.localizedDescription
//            }
//        }
//    }
}

#Preview {
    LoginFormView(user: .constant(nil))
}
