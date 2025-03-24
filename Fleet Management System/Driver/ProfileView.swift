import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var user: AppUser?
    @Binding var role : Role?
    // Sample driver data with Indian standards
//    let driver = Driver(meta_data: UserMetaData(id: UUID(),
//                                                fullName: "Rajesh Kumar Singh",
//                                                email: "driver@driver.com",
//                                                phone: "+910987654321",
//                                                role: .driver,
//                                                employeeID: 4,
//                                                firstTimeLogin: false,
//                                                createdAt: .now,
//                                                activeStatus: true),
//                        licenseNumber: "DL-01-2024-1234567",
//                        totalTrips: 9,
//                        status: .available
//        drivingLicense: "DL-01-2024-1234567" // Format: DL-{State Code}-{Year}-{7 digits}
//    )
    func signOut() {
        Task {
            do {
                try await AuthManager.shared.signOut()
                DispatchQueue.main.async {
                    dismiss()
                    user = nil
                    role = nil
                }
            } catch {
                print("Error signing out: \(error)")
            }
        }
    }

    var licenseInfoView: some View {
        guard let user = user, user.role == .driver else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("License Information")
                    .font(.headline)

                Divider()

                InfoRow(title: "Driving License", value: user.licenseNumber!)
                Text("Format: DL-{State Code}-{Year}-{7 digits}")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                    .padding(.top, 4)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        )
    }

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.primaryGradientStart)
                        
                        Text(user?.meta_data.fullName ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Professional Driver")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top)
                    
                    // Profile Information Cards
                    VStack(spacing: 16) {
                        // Employee Information Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Employee Information")
                                .font(.headline)
                            
                            Divider()
                            
                            InfoRow(title: "Employee ID", value: String(user?.employeeID ?? 0))
                            InfoRow(title: "Full Name", value: user?.meta_data.fullName ?? "")
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Contact Information Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact Information")
                                .font(.headline)
                            
                            Divider()
                            
                            InfoRow(title: "Email", value: user?.meta_data.email ?? "")
                            InfoRow(title: "Phone Number", value: user?.meta_data.phone ?? "")
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // License Information Card
                        licenseInfoView
                        
                        Button(action: signOut) {
                                    Text("Sign Out")
                                        .font(.title2)
                                        .padding()
                                        .background(Color.white)
                                        .foregroundColor(.statusRed)
                                        .cornerRadius(10)
                                }
                                .padding(.bottom, 50)
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.cardBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.subheadline)
                            .foregroundColor(.primaryGradientStart)
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}
//
//struct DriverProfile {
//    let employeeId: String
//    let fullName: String
//    let email: String
//    let phoneNumber: String
//    let drivingLicense: String
//}

