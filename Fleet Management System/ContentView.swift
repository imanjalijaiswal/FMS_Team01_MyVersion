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
            } else if isFirstTimeLogin, let user = user {
                // Show password reset screen for first-time login
                PasswordResetView(user: $user)
            } else if let user = user {
                switch user.role {
                case .fleetManager:
                    FleetManagerView(user: $user, role: $role)
                case .driver:
                    DriverView(user: $user, role: $role)
                case .maintenancePersonal:
                    MaintenanceView(user: $user, role: $role)
                }
            } else {
                LoginFormView(user: $user)
            }
        }
        .task {
            do {
                user = try await AuthManager.shared.getCurrentSession()
                
                // Check if it's first-time login
                if let user = user {
                    isFirstTimeLogin = try await AuthManager.shared.checkFirstTimeLogin(userId: user.id)
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
                do {
                    if let newUser = newUser {
                        isFirstTimeLogin = try await AuthManager.shared.checkFirstTimeLogin(userId: newUser.id)
                    }
                } catch {
                    print("Error checking first-time login: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}




