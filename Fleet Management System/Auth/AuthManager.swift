//
//  AuthManager.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 18/03/25.
//

import Foundation
import Supabase
import Auth

protocol User: Codable, Equatable, Identifiable {
    var meta_data: UserMetaData { get set }
    
    var id: UUID { get }
    
    var activeStatus: Bool { get }
    var employeeID: Int { get }
    var role: Role { get }
}

struct UserMetaData: Codable, Equatable, Identifiable {
    var id: UUID
    var fullName: String
    var email: String
    var phone: String
    var role: Role
    var employeeID: Int
    var firstTimeLogin: Bool
    var createdAt: Date
    var activeStatus: Bool
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

struct FleetManager: User {
    var activeStatus: Bool { return meta_data.activeStatus }
    
    var employeeID: Int { return meta_data.employeeID }
    
    var role: Role { return meta_data.role }
    
    var meta_data: UserMetaData
    var id: UUID { meta_data.id }
}

struct Driver: User {
    var activeStatus: Bool { return meta_data.activeStatus }
    
    var employeeID: Int { return meta_data.employeeID }
    
    var role: Role { return meta_data.role }
    
    var meta_data: UserMetaData
    var licenseNumber: String
    var totalTrips: Int
    var status: DriverStatus
    
    var id: UUID { meta_data.id }
}

struct AppUser: Codable, Equatable, Identifiable {
    var userData: UserSpecificData

    enum UserSpecificData: Codable, Equatable {
        case driver(Driver)
        case fleetManager(FleetManager)

        enum CodingKeys: String, CodingKey {
            case type, data
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .driver(let driver):
                try container.encode("driver", forKey: .type)
                try container.encode(driver, forKey: .data)
            case .fleetManager(let manager):
                try container.encode("fleetManager", forKey: .type)
                try container.encode(manager, forKey: .data)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "driver":
                let driver = try container.decode(Driver.self, forKey: .data)
                self = .driver(driver)
            case "fleetManager":
                let manager = try container.decode(FleetManager.self, forKey: .data)
                self = .fleetManager(manager)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid role type")
            }
        }
    }

    var meta_data: UserMetaData {
        switch userData {
        case .driver(let driver):
            return driver.meta_data
        case .fleetManager(let fleetManager):
            return fleetManager.meta_data
        }
    }
    
    var role: Role { return meta_data.role }
    
    var licenseNumber: String? {
        switch userData {
        case .driver(let driver):
            return driver.licenseNumber
        default: return nil
        }
    }
    
    var totalTrips: Int? {
        switch userData {
        case .driver(let driver):
            return driver.totalTrips
        default: return nil
        }
    }
    
    var driverStatus: DriverStatus? {
        switch userData {
        case .driver(let driver):
            return driver.status
        default: return nil
        }
    }
    
    var id: UUID {  return meta_data.id }
    
    var activeStatus: Bool { return meta_data.activeStatus }
    
    var employeeID: Int { return meta_data.employeeID }
}


//struct AppUser: Equatable {
//   var id: String
//   var email: String?
//   var role: Role
////   var workingStatus: Bool
//   
//   static func == (lhs: AppUser, rhs: AppUser) -> Bool {
//       return lhs.id == rhs.id && lhs.email == rhs.email && lhs.role == rhs.role
//   }
//}
//
//struct UserRoles:Codable{
//    var id : UUID
//    var role : Role
//    var workingStatus : Bool
//    var firstTimeLogin : Bool
//    var createdAt : Date
//}

enum Role: String, Codable {
    case fleetManager = "fleetManager"
    case driver = "driver"
    case maintenancePersonnel = "maintenancePersonnel"
}

//enum AuthError: Error {
//    case inactiveUser
//    case invalidCredentials
//    case networkError
//    
//    var description: String {
//        switch self {
//        case .inactiveUser:
//            return "Your account is currently inactive. Please contact your administrator."
//        case .invalidCredentials:
//            return "Invalid email or password."
//        case .networkError:
//            return "Network error occurred. Please try again."
//        }
//    }
//}

class AuthManager{
    static let shared = AuthManager()
    
    // Flag to enable/disable 2FA for testing
    static var is2FAEnabled = true
    
    // Flag to track if 2FA has been completed
    private var is2FACompleted = false
    
    // Store the current 2FA code
    private var current2FACode: String = ""
    
    // Store the current user
    private(set) var currentUser: AppUser?
    
    // UserDefaults key for storing 2FA completion status
    private let twoFACompletedKey = "twoFACompleted"
    
    // UserDefaults key for storing the active fleet manager's ID
    private let activeFleetManagerKey = "activeFleetManagerID"
    
    // Cache for first time login status to avoid repetitive database queries
    private var firstTimeLoginCache: [String: Bool] = [:]
    
    private init(){
        // Load 2FA completion status from UserDefaults
        is2FACompleted = UserDefaults.standard.bool(forKey: twoFACompletedKey)
    }
    
    let client = SupabaseClient(supabaseURL: URL(string: "https://rhmhyrccjrgmgjyxgmlf.supabase.co" )!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJobWh5cmNjanJnbWdqeXhnbWxmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDI3Mjk0MTksImV4cCI6MjA1ODMwNTQxOX0.FtGNdVw_TBTUOGlUm8tH6EqZbvCCZsdxpd6LN91_Sho")

    // Store the active fleet manager's ID in UserDefaults
    func saveActiveFleetManager(id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: activeFleetManagerKey)
    }
    
    // Get the stored fleet manager ID from UserDefaults
    func getActiveFleetManagerID() -> UUID? {
        guard let idString = UserDefaults.standard.string(forKey: activeFleetManagerKey),
              let uuid = UUID(uuidString: idString) else {
            return nil
        }
        return uuid
    }
    
    // Clear the saved fleet manager ID
    func clearActiveFleetManager() {
        UserDefaults.standard.removeObject(forKey: activeFleetManagerKey)
    }

    func getCurrentSession() async throws -> AppUser? {
        do {
            // Check if we have a stored fleet manager ID
            if let fleetManagerID = getActiveFleetManagerID() {
                // Try to get the user by the stored ID
                do {
                    let role = try await getUserRole(userId: fleetManagerID.uuidString)
                    let appUser = try await getAppUser(byType: role, id: fleetManagerID)
                    currentUser = appUser
                    return appUser
                } catch {
                    print("Could not restore fleet manager session: \(error)")
                    // If we couldn't load the fleet manager, continue with normal flow
                }
            }
            
            // Try to get the current session
            let session = try await client.auth.session
            let userId = session.user.id
            
            // If 2FA is not required or has been completed, return the user
            if !AuthManager.is2FAEnabled || is2FACompleted {
                let role = try await getUserRole(userId: userId.uuidString)
                
                // If this is a fleet manager, save their ID for future use
                if role == .fleetManager {
                    saveActiveFleetManager(id: userId)
                }
                
                let appUser = try await getAppUser(byType: role, id: userId)
                currentUser = appUser
                return appUser
            } else {
                // 2FA is required but not completed - force re-authentication
                try await signOut()
                return nil
            }
        } catch {
            print("Error in getCurrentSession: \(error)")
            return nil
        }
    }

    
    func signOut() async throws{
        try await client.auth.signOut()
        is2FACompleted = false
        currentUser = nil  // Clear current user
        // Clear 2FA completion status in UserDefaults
        UserDefaults.standard.set(false, forKey: twoFACompletedKey)
        
        // DON'T clear the active fleet manager when signing out
        // This allows the fleet manager to remain the primary user
        
        // Clear the firstTimeLogin cache to ensure fresh state on next login
        firstTimeLoginCache.removeAll()
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
        
        // Check working status first
        let workingStatus = try await getWorkingStatus(userId: userId)
        if !workingStatus {
            try await client.auth.signOut() // Sign out immediately if inactive
            throw AuthError.inactiveUser
        }
        
        // If working status is true, proceed with getting role and creating user
        let role = try await getUserRole(userId: userId)
        let user = try await getAppUser(byType: role, id: session.user.id)
        currentUser = user  // Set current user
        
        // If this is a fleet manager logging in, save their ID
        if role == .fleetManager {
            saveActiveFleetManager(id: session.user.id)
        }
        
        return user
    }
    
    func getAppUser(byType type: Role, id: UUID) async throws -> AppUser {
        switch type {
        case .driver:
            let driverData: Driver = try await client
                .rpc("get_driver_data_by_id", params: ["p_id": id.uuidString])
                .execute()
                .value
            return AppUser(userData: .driver(driverData))
        case .fleetManager, .maintenancePersonnel:
            let managerData: FleetManager = try await client
                .rpc("get_fleet_manager_data_by_id", params: ["p_id": id.uuidString])
                .execute()
                .value
            return AppUser(userData: .fleetManager(managerData))
        }
    }
    
    // MARK: - User Roles

    func getUserRole(userId: String) async throws -> Role {
        guard let userUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "Invalid UUID format", code: 0, userInfo: nil)
        }

        do {
            struct UserRole: Codable {
                let role: String
            }
            
            let response = try await client
                .from("UserRoles").select("role").eq("id", value: userUUID).single()
                .execute()
            
            let userRole = try JSONDecoder().decode(UserRole.self, from: response.data)
            if userRole.role == "driver" { return .driver }
            else { return .fleetManager }
//            print("JSON: \(json)")
//            if let json = try? JSONSerialization.jsonObject(with: response.data, options: []) as? [String: Any] {
//                   let roleString = json["role"] as? String
//                   let role = Role(rawValue: roleString ?? "fleetManager")!
//                    return role
//                } else {
//                    throw NSError(domain: "Invalid Role Data", code: 1, userInfo: nil)
//                }
        } catch {
            print("Error fetching user role: \(error.localizedDescription)")
            throw error
        }
    }
    
    func checkFirstTimeLogin(userId: String) async throws -> Bool {
        // Check if we have a cached value
        if let cachedValue = firstTimeLoginCache[userId] {
            return cachedValue
        }
        
        guard let userUUID = UUID(uuidString: userId) else {
            print("Invalid UUID format: \(userId)")
            return false // Default to false if UUID is invalid
        }

        do {
            let firstTimeLoginStatus: Bool = try await client
                .rpc("get_user_first_time_login_status_by_id", params: ["p_id": userId])
                .execute().value
            
            firstTimeLoginCache[userId] = firstTimeLoginStatus
            
            return firstTimeLoginStatus
        } catch {
            print("Error fetching firstTimeLogin status: \(error.localizedDescription)")
            return false // Default to false in case of errors
        }
    }

    /// Updates the firstTimeLogin status for a user in the UserRoles table
    func updateFirstTimeLoginStatus(userId: String, firstTimeLogin: Bool) async throws {
        guard let userUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "Invalid UUID format", code: 0, userInfo: nil)
        }
        
        do {
            try await client
                .from("UserMetaData")
                .update(["firstTimeLogin": firstTimeLogin])
                .eq("id", value: userId)
                .execute()
            
            // Update the cache
            firstTimeLoginCache[userId] = firstTimeLogin
        } catch {
            print("Error updating firstTimeLogin status: \(error.localizedDescription)")
            throw error
        }
    }
    
    func getWorkingStatus(userId: String) async throws -> Bool {
        guard let userUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "Invalid UUID format", code: 0, userInfo: nil)
        }

        do {
            return try await client
                .rpc("get_user_active_status_by_id", params: ["p_id": userId])
                .execute().value
        } catch {
            print("Error fetching user active status: \(error.localizedDescription)")
            throw error
        }
    }

    /// Clear any cached state for a user ID
    func clearUserCache(userId: String) {
        firstTimeLoginCache.removeValue(forKey: userId)
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
        print("Token: \(token)")
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
    func generateAndSend2FACode(email: String) async throws {
        // Use Supabase's OTP method
        try await client.auth.signInWithOTP(
            email: email,
            shouldCreateUser: false
        )
    }

    // Verify the 2FA code entered by the user
    func verify2FACode(email: String, token: String) async throws -> Bool {
        do {
            // Use Supabase's OTP verification
            try await client.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )
            // Mark 2FA as completed
            mark2FACompleted()
            return true
        } catch {
            print("2FA verification error: \(error.localizedDescription)")
            return false
        }
    }
    
    // Mark 2FA as completed
    func mark2FACompleted() {
        is2FACompleted = true
        // Save 2FA completion status to UserDefaults
        UserDefaults.standard.set(true, forKey: twoFACompletedKey)
    }

    // Enhanced sign-in method with 2FA support
    func signInWithEmailAndInitiate2FA(email: String, password: String) async throws -> AppUser? {
        do {
            print("Attempting to sign in...")
            let authResponse = try await client.auth.signIn(email: email, password: password)
            
            // Get the user from the response
            let user = authResponse.user
            let userId = user.id.uuidString
            
            // Check working status first
            let workingStatus = try await getWorkingStatus(userId: userId)
            if !workingStatus {
                try await client.auth.signOut() // Sign out immediately if inactive
                throw AuthError.inactiveUser
            }
            
            // Get user role
            let role = try await getUserRole(userId: userId)
            let appUser = try await getAppUser(byType: role, id: user.id)
            currentUser = appUser  // Set current user
            
            // Reset 2FA completed flag
            is2FACompleted = false
            UserDefaults.standard.set(false, forKey: twoFACompletedKey)
            
            // Check if this is a first-time login
            let isFirstTime = try await checkFirstTimeLogin(userId: userId)
            
            // Skip 2FA if it's a first-time login - they need to reset password first
            if isFirstTime {
                // Mark 2FA as completed to bypass that check
                mark2FACompleted()
                return appUser
            }
            
            // Otherwise, proceed with normal 2FA flow if enabled
            if AuthManager.is2FAEnabled {
                // Generate and send 2FA code
                try await generateAndSend2FACode(email: email)
                return appUser
            } else {
                // Skip 2FA if disabled
                mark2FACompleted()
                return appUser
            }
        } catch {
            // Handle known errors
            print("Auth error: \(error.localizedDescription)")
            if let authError = error as? AuthError {
                throw authError
            }
            throw error
        }
    }

    // Check if the new password is same as current password
    func checkIfSamePassword(email: String, password: String) async throws -> Bool {
        do {
            // Try to sign in with the provided password
            // If successful, it means the password is the same as current
            _ = try await client.auth.signIn(
                email: email,
                password: password
            )
            return true
        } catch {
            // If sign in fails, it means the password is different
            return false
        }
    }
}
