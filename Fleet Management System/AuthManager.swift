//
//  AuthManager.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 18/03/25.
//

import Foundation
import Supabase

struct AppUser{
   var id: String
   var email: String?
}

extension String{
    func isValidEmail() -> Bool {

        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: self)

    }
}
class AuthManager{
    static let shared = AuthManager()
    
    private init(){}
    let client = SupabaseClient(supabaseURL: URL(string: "" )!, supabaseKey: "")
    func getCurrentSession() async throws -> AppUser? {
        let session = try await client.auth.session
        return AppUser(id: session.user.id.uuidString, email: session.user.email)
        
    }
    
    func signOut() async throws{
        try await client.auth.signOut()
    }
    
    // MARK: - REgistration
    func registerNewUserWithEmail(email: String, password: String) async throws -> AppUser {
        let regAuthResponse = try await client.auth.signUp(email: email, password: password)
        guard let session = regAuthResponse.session else{
            print("no session when regestring user")
            throw NSError(domain: "", code: 0, userInfo: nil)
        }
        
        return AppUser(id: session.user.id.uuidString, email: session.user.email)
    }
    
    // MARK: - SigniIN
    
    func signUpWithEmail(email: String, password: String) async throws -> AppUser {
        
        let session = try await client.auth.signIn(email: email, password: password)
        return AppUser(id: session.user.id.uuidString, email: session.user.email)
    }
}
