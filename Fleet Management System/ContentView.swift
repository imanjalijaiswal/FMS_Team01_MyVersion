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
    
    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView("Loading...")
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
                isLoading = false
            } catch {
                print("Error fetching session: \(error)")
                isLoading = false
            }
        }
    }
}


#Preview {
    ContentView()
}




