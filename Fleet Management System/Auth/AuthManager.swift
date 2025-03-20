//
//  AuthManager.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 18/03/25.
//

import Foundation
import Supabase
import Auth

struct AppUser{
   var id: String
   var email: String?
    var role : Role
}

struct UserRoles:Codable{
    var id : UUID
    var role : Role
    var workingStatus : Bool
    var firstTimeLogin : Bool
    var createdAt : Date
}

enum Role:String,Codable{
    case fleetManager
    case driver
    case maintenancePersonal
}


class AuthManager{
    static let shared = AuthManager()
    
    // Flag to enable/disable 2FA for testing
    static var is2FAEnabled = true
    
    private init(){}
    let client = SupabaseClient(supabaseURL: URL(string: "https://cxeocphyzvdokhuzrkre.supabase.co" )!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN4ZW9jcGh5enZkb2todXpya3JlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIzNDY4MDAsImV4cCI6MjA1NzkyMjgwMH0.XnWtTxwBfTVhqXyY4dr9avnGLVWYDlsT3T9hdEz96lk")

    func getCurrentSession() async throws -> AppUser? {
        let session = try await client.auth.session
        let userId = session.user.id.uuidString
        
        do {
            let role = try await getUserRole(userId: userId) 
            return AppUser(id: userId, email: session.user.email, role: role)
        } catch {
            print("Error fetching role: \(error)")
            return nil
        }
    }

    
    func signOut() async throws{
        try await client.auth.signOut()
    }
    
    // MARK: - REgistration
//    func registerNewUserWithEmail(email: String, password: String) async throws -> AppUser {
//        let regAuthResponse = try await client.auth.signUp(email: email, password: password)
//        guard let session = regAuthResponse.session else{
//            print("no session when regestring user")
//            throw NSError(domain: "", code: 0, userInfo: nil)
//        }
//        
//        return AppUser(id: session.user.id.uuidString, email: session.user.email)
//    }
    
    // MARK: - SigniIN
    
    func signInWithEmail(email: String, password: String) async throws -> AppUser {
        
        let session = try await client.auth.signIn(email: email, password: password)
        let userId = session.user.id.uuidString
        let role = try await getUserRole(userId: userId)
        return AppUser(id: session.user.id.uuidString, email: session.user.email, role:role)
    }
    
    // MARK: - User Roles

    func getUserRole(userId: String) async throws -> Role {
        guard let userUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "Invalid UUID format", code: 0, userInfo: nil)
        }

        do {

            let response: UserRoles = try await client
                .from("UserRoles")
                .select("*")
                .eq("id", value: userUUID)
                .single()
                .execute()
                .value
            
            return response.role
        } catch {
            print("Error fetching user role: \(error.localizedDescription)")
            throw error
        }
    }
    
    func checkFirstTimeLogin(userId: String) async throws -> Bool {
        guard let userUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "Invalid UUID format", code: 0, userInfo: nil)
        }

        do {

            let response: UserRoles = try await client
                .from("UserRoles")
                .select("*")
                .eq("id", value: userUUID)
                .single()
                .execute()
                .value
            
            return response.firstTimeLogin
        } catch {
            print("Error fetching user role: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Password Reset with OTP
    
    func resetPasswordWithOTP(email: String) async throws {
        // Send OTP to the user's email
        // The signInWithOTP method should trigger the OTP email template
        try await client.auth.signInWithOTP(
            email: email,
            shouldCreateUser: false  // Don't create a new user if they don't exist
        )
    }
    
    func verifyOTP(email: String, token: String) async throws -> Bool {
        // Verify the OTP using the verifyOTP method
        do {
            try await client.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )
            return true
        } catch {
            print("OTP verification error: \(error.localizedDescription)")
            return false
        }
    }
    
    func updateUserPassword(email: String, password: String) async throws {
        // Update the user's password
        // This requires the user to be authenticated
        var attributes = UserAttributes()
        attributes.password = password
        try await client.auth.update(user: attributes)
    }

    // MARK: - Password Reset with Direct Password Update

    // This function will be used in a new approach for password reset
    func generateAndSendResetCode(email: String) async throws -> String {
        // Generate a random 6-digit code
        let resetCode = String(format: "%06d", Int.random(in: 0...999999))
        
        // Store the reset code somewhere (in a real app, you'd store this securely in a database)
        // For this demo, we'll just return it and let the view model handle it
        
        // In a real implementation, you would send an email to the user with this code
        print("Generated reset code for \(email): \(resetCode)")
        
        return resetCode
    }

    // Use this instead of verifyOTP since we're handling the verification ourselves
    func verifyPasswordResetCode(submittedCode: String, actualCode: String) -> Bool {
        return submittedCode == actualCode
    }

    // Update password directly after verification
    func updatePassword(email: String, newPassword: String) async throws {
        // In a real app, you would need to use admin access to update the password
        // Since we can't do that here, we'll create a simplified approach
        
        // Here, you would typically:
        // 1. Use an Admin API or Cloud Function to reset the user's password
        // 2. Then allow them to sign in with the new password
        
        // For demo purposes, we'll log what would happen
        print("Password for \(email) would be updated to: \(newPassword)")
        
        // This is a placeholder - in a real implementation you would use Supabase admin functions
        // or a custom server endpoint to change the password
    }

    // MARK: - Two-Factor Authentication

    // Generate and send a 2FA code to the user's email
    func generateAndSend2FACode(email: String) async throws -> String {
        // Generate a 6-digit code
        let authCode = String(format: "%06d", Int.random(in: 0...999999))
        
        // Log the code to console for testing
        print("2FA code for \(email): \(authCode)")
        
        // Use the same approach as resetPasswordWithOTP
        try await client.auth.signInWithOTP(
            email: email,
            shouldCreateUser: false
        )
        
        return authCode
    }

    // Verify the 2FA code entered by the user
    func verify2FACode(submittedCode: String, actualCode: String) -> Bool {
        return submittedCode == actualCode
    }

    // Enhanced sign-in method with 2FA support
    func signInWithEmailAndInitiate2FA(email: String, password: String) async throws -> AppUser? {
        do {
            let authResponse = try await client.auth.signIn(email: email, password: password)
            
            // Get the user from the response
            let user = authResponse.user
            let userId = user.id.uuidString
            let userEmail = user.email
            
            // Get user role
            let role = try await getUserRole(userId: userId)
            let appUser = AppUser(id: userId, email: userEmail, role: role)
            
            // Only initiate 2FA if it's enabled
            if AuthManager.is2FAEnabled {
                // Generate and send 2FA code
                let _ = try await generateAndSend2FACode(email: email)
                return appUser
            } else {
                // Skip 2FA if disabled
                return appUser
            }
        } catch {
            // Handle known errors
            print("Auth error: \(error.localizedDescription)")
            throw error
        }
    }
}
