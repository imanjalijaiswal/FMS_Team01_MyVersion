//
//  FleetMangerHome.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 19/03/25.
//

import Foundation
import SwiftUI

struct FleetManagerView: View {
    @Binding var user: AppUser?
    @Binding var role : Role?
    
    var body: some View {
        VStack {
            FleetManagerTabBarView()
        }
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
