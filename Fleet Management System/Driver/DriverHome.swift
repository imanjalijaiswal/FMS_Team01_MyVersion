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
                let newTrip = Trips(
                    tripId: "TRP-2024-003",
                    truckType: "BharatBenz 2823C",
                    numberPlate: "DL 01 HH 9876",
                    type: .assigned,
                    date: "Thursday - Mar 21, 2024",
                    details: "Auto Parts, 3200 kg",
                    pickup: Location(
                        name: "Maruti Suzuki Plant",
                        address: "IMT Manesar, Gurugram, Haryana"
                    ),
                    destination: Location(
                        name: "Tata Motors Factory",
                        address: "MIDC Pimpri, Pune, Maharashtra"
                    ),
                    distance: "1420 km",
                    estimatedTime: "20 hours",
                    partner: Partner(
                        name: "Amit Patel",
                        company: "Maruti Suzuki",
                        contactNumber: "+91 76543 21098",
                        email: "amit.patel@maruti.com"
                    )
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
            
            TripsView()
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

