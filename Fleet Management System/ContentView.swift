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
                ProgressView("Loading...")
            } else if let user = user, isFirstTimeLogin {
                // Show password reset screen for first-time login - only when we have a user AND firstTimeLogin is true
                PasswordResetView(user: $user, isFirstTimeLogin: $isFirstTimeLogin)
            } else if let user = user {
                switch user.role {
                case .fleetManager, .maintenancePersonnel:
                    FleetManagerView(user: $user, role: $role)
                case .driver:
                    DriverView(user: $user, role: $role)
//                case .maintenancePersonal:
//                    MaintenanceView(user: $user, role: $role)
                }
            } else {
                LoginFormView(user: $user)
            }
        }
        .task {
            do {
                // Set isFirstTimeLogin to false by default - assume no first time login until proven otherwise
                isFirstTimeLogin = false
                user = try await AuthManager.shared.getCurrentSession()
                
                // Check if it's first-time login only if we have a valid user
                if let currentUser = user {
                    isFirstTimeLogin = try await AuthManager.shared.checkFirstTimeLogin(userId: currentUser.id.uuidString)
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
                    isFirstTimeLogin = try await AuthManager.shared.checkFirstTimeLogin(userId: newUser.id.uuidString)
                }
            }
        }
        // This additional binding ensures immediate UI updates when isFirstTimeLogin changes
        .onChange(of: isFirstTimeLogin) { _, _ in
            // This forces the view to re-evaluate which screen to show
        }
    }
}

#Preview {
    ContentView()
}




