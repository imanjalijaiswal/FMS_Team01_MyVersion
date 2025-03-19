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


struct FleetManagerView: View {
   @Binding var user: AppUser?
    @Binding var role : Role?

    var body: some View {
        VStack {
            Text("Fleet Manager View")
                .font(.largeTitle)
                .foregroundColor(.white)

            Spacer()

            Button(action: signOut) {
                Text("Sign Out")
                    .font(.title2)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.blue)
                    .cornerRadius(10)
            }
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue)
        .edgesIgnoringSafeArea(.all)
    }

    func signOut() {
        Task {
            do {
                try await AuthManager.shared.signOut()
                user = nil
                role = nil
            } catch {
                print("Error signing out: \(error)")
            }
        }
    }
}

struct DriverView: View {
    @Binding var user: AppUser?
    @Binding var role : Role?

    var body: some View {
        VStack {
            Text("Driver View")
                .font(.largeTitle)
                .foregroundColor(.white)

            Spacer()

            Button(action: signOut) {
                Text("Sign Out")
                    .font(.title2)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.green)
                    .cornerRadius(10)
            }
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.green)
        .edgesIgnoringSafeArea(.all)
    }

    func signOut() {
        Task {
            do {
                try await AuthManager.shared.signOut()
                user = nil
                role = nil

            } catch {
                print("Error signing out: \(error)")
            }
        }
    }
}

struct MaintenanceView: View {
    @Binding var user: AppUser?
    @Binding var role : Role?

    var body: some View {
        VStack {
            Text("Maintenance View")
                .font(.largeTitle)
                .foregroundColor(.white)

            Spacer()

            Button(action: signOut) {
                Text("Sign Out")
                    .font(.title2)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.orange)
                    .cornerRadius(10)
            }
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.orange)
        .edgesIgnoringSafeArea(.all)
    }

    func signOut() {
        Task {
            do {
                try await AuthManager.shared.signOut()
                user = nil
                role = nil

            } catch {
                print("Error signing out: \(error)")
            }
        }
    }
}
