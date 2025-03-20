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
            FleetManagerTabBarView(user: $user, role: $role)
        }
    }
    }
