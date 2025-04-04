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
    @State private var opacity = 1.0 // For smooth transitions
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    // Show role-specific skeleton immediately if role is known, otherwise show login
                    if let role = role {
                        switch role {
                        case .fleetManager:
                            SkeltonView()
                                .transition(.opacity)
                                .opacity(opacity)
                        case .driver:
                            NavigationView {
                                DriverDashboardSkeletonView()
                                    .navigationTitle("Driver")
                                    .toolbar {
                                        ToolbarItem(placement: .navigationBarTrailing) {
                                            Circle()
                                                .fill(Color.gray.opacity(0.4))
                                                .frame(width: 35, height: 35)
                                                .shimmer()
                                        }
                                    }
                            }
                            .transition(.opacity)
                            .opacity(opacity)
                        case .maintenancePersonnel:
                            SkeltonView() // Fallback for now
                                .transition(.opacity)
                                .opacity(opacity)
                        }
                    } else {
                        // If not authenticated, show login screen
                        LoginFormView(user: $user)
                            .transition(.opacity)
                            .opacity(isLoading ? 0 : 1)
                    }
                }
                // Show password reset screen for first-time login
                else if let user = user, isFirstTimeLogin {
                    PasswordResetView(user: $user, isFirstTimeLogin: $isFirstTimeLogin)
                        .transition(.opacity)
                }
                // Show main views based on role
                else if let user = user {
                    switch user.role {
                    case .fleetManager:
                        FleetManagerView(user: $user, role: $role)
                            .transition(.opacity)
                    case .driver:
                        DriverView(user: $user, role: $role)
                            .transition(.opacity)
                    case .maintenancePersonnel:
                        MaintenanceView(user: $user, role: $role)
                            .transition(.opacity)
                    }
                }
                else {
                    LoginFormView(user: $user)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isLoading)
            .animation(.easeInOut(duration: 0.3), value: opacity)
        }
        .task {
            do {
                // Fetch user session
                if let session = try await AuthManager.shared.getCurrentSession() {
                    user = session
                    role = session.role
                    
                    // Add a small delay to show the skeleton view
                    try? await Task.sleep(for: .seconds(1.5))
                    
                    // Fade out skeleton view
                    withAnimation {
                        opacity = 0
                    }
                    
                    // Wait for fade out to complete
                    try? await Task.sleep(for: .seconds(0.3))
                    withAnimation {
                        isLoading = false
                    }
                } else {
                    withAnimation {
                        isLoading = false
                    }
                }
            } catch {
                print("Error fetching session: \(error)")
                withAnimation {
                    isLoading = false
                }
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
                
                // When user logs in, show skeleton briefly
                if oldUser == nil && newUser != nil {
                    role = newUser?.role
                    
                    // Enable loading to show skeleton
                    withAnimation {
                        isLoading = true
                        opacity = 1
                    }
                    
                    // Artificial delay for skeleton view to be visible
                    try? await Task.sleep(for: .seconds(1.5))
                    
                    // Fade out skeleton
                    withAnimation {
                        opacity = 0
                    }
                    
                    // Wait for fade out
                    try? await Task.sleep(for: .seconds(0.3))
                    
                    // Disable loading to show main content
                    withAnimation {
                        isLoading = false
                    }
                }
                
                // Check first-time login status for the new user
                if let newUser = newUser {
                    if newUser.role == .fleetManager || newUser.role == .maintenancePersonnel {
                        isFirstTimeLogin = try await AuthManager.shared.checkFirstTimeLogin(userId: newUser.id.uuidString)
                    } else if newUser.role == .driver {
                        let isFirstTime = try await AuthManager.shared.checkFirstTimeLogin(userId: newUser.id.uuidString)
                        if isFirstTime {
                            isFirstTimeLogin = isFirstTime
                        }
                    }
                }
            }
        }
        // This additional binding ensures immediate UI updates when isFirstTimeLogin changes
        .onChange(of: isFirstTimeLogin) { _, _ in }
    }
}

#Preview {
    ContentView()
}




