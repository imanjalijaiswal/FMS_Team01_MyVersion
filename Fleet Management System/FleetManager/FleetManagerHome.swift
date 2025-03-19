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
