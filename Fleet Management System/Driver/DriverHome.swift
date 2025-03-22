//
//  DriverHome.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 19/03/25.
//

import Foundation
import SwiftUI

struct DriverView: View {
    @Binding var user: AppUser?
    @Binding var role : Role?
    var body: some View {
        MainTabView(user: $user, role: $role)
//        Button(action: signOut) {
//            Text("Sign Out")
//                .font(.title2)
//                .padding()
//                .background(Color.white)
//                .foregroundColor(.green)
//                .cornerRadius(10)
//        }
//        .padding(.bottom, 50)
    }

    func signOut() {
        Task {
            do {
                try await AuthManager.shared.signOut()
                
                let newTrip = Trip(
                        id: UUID(),
                        tripID: 3,
                        assignedByFleetManagerID: UUID(),
                        assignedDriverIDs: [UUID()],
                        assigneVehicleID: 3,
                        pickupLocation: "IMT Manesar, Gurugram, Haryana",
                        destination: "MIDC Pimpri, Pune, Maharashtra",
                        estimatedArrivalDateTime: Date().addingTimeInterval(48*3600),
                        totalDistance: 1420,
                        totalTripDuration: Date().addingTimeInterval(20*3600),
                        description: "Auto Parts, 3200 kg",
                        scheduledDateTime: Date().addingTimeInterval(48*3600),
                        createdAt: Date(),
                        status: .scheduled
                )
                user = nil
                role = nil

            } catch {
                print("Error signing out: \(error)")
            }
        }
    }
}

struct MainTabView: View {
    @Binding var user: AppUser?
    @Binding var role : Role?
    var body: some View {
        TabView {
            DashboardView(user: $user, role: $role)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            
            MapView()
                .tabItem {
                    Label("Trip", systemImage: "map")
                }
            
//            MaintenanceView()
//                .tabItem {
//                    Label("Maintenance", systemImage: "wrench.and.screwdriver")
//                }
        }
        .accentColor(.primaryGradientEnd) // Applies teal color to selected tab
    }
}

