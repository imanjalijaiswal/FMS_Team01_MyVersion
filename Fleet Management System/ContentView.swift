//
//  ContentView.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 17/03/25.
//

import SwiftUI

struct ContentView: View {
    @State private var user: AppUser? = nil
    @State private var role: Role? = nil
    @State private var isLoading = true
    @State private var isFirstTimeLogin = false
    
    var body: some View {
        NavigationStack {
            if isLoading {
                SkeltonView()
            } else if let user = user, isFirstTimeLogin {
                // Show password reset screen for first-time login - only when we have a user AND firstTimeLogin is true
                // AND the user is NOT a driver that was just created
                PasswordResetView(user: $user, isFirstTimeLogin: $isFirstTimeLogin)
            } else if let user = user {
                switch user.role {
                case .fleetManager:
                    FleetManagerView(user: $user, role: $role)
                case .driver:
                    DriverView(user: $user, role: $role)
                case .maintenancePersonnel:
                    MaintenanceView(user: $user, role: $role)
                }
            } else {
                LoginFormView(user: $user)
            }
        }
        .task {
            do {
                // Fetch user session
                if let session = try await AuthManager.shared.getCurrentSession() {
                    user = session
                    role = session.role
                }
                isLoading = false
            } catch {
                print("Error fetching session: \(error)")
                isLoading = false
            }
        }
        .onChange(of: user) { oldUser, newUser in
            // When user changes (e.g., after login), check for first-time login
            Task {
                // Reset firstTimeLogin state when no user
                if newUser == nil {
                    isFirstTimeLogin = false
                    return
                }
                
                // Check first-time login status for the new user
                if let newUser = newUser {
                    // Only allow first-time login flow for fleet managers
                    // Newly created drivers will be redirected to login screen
                    if newUser.role == .fleetManager || newUser.role == .maintenancePersonnel {
                        isFirstTimeLogin = try await AuthManager.shared.checkFirstTimeLogin(userId: newUser.id.uuidString)
                    } else if newUser.role == .driver {
                        // For drivers, check if this is first-time login
                        let isFirstTime = try await AuthManager.shared.checkFirstTimeLogin(userId: newUser.id.uuidString)
                        if isFirstTime {
                            // If it's a first-time login for a driver, allow them to reset their password
                            // but only if they explicitly logged in (not on app restart)
                            isFirstTimeLogin = isFirstTime
                        }
                    }
                }
            }
        }
        // This additional binding ensures immediate UI updates when isFirstTimeLogin changes
        .onChange(of: isFirstTimeLogin) { _, _ in
            // This forces the view to re-evaluate which screen to show
        }
    }
}


// Shimmer effect modifier for iOS 17+

#Preview {
    ContentView()
}




