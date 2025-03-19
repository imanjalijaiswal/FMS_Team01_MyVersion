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









}
