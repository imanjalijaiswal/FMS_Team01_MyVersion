import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var user: AppUser?
    @Binding var role : Role?
    
    func signOut() {
        Task {
            do {
             //   try await updateUserStatusInDatabase(userID: user.id, isActive: false)
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
    
    // Profile header component
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.primaryGradientStart)
            
            Text(user?.meta_data.fullName ?? "")
                .font(.title2)
                .fontWeight(.bold)
            
            if let user = user, user.role == .driver {
                Text("Driver")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            } else {
                Text("Fleet Manager")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.top)
    }
    
    // Employee information card component
    private var employeeInfoCard: some View {
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
    }
    
    // Contact information card component
    private var contactInfoCard: some View {
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
    }
    
    // Sign out button component
    private var signOutButton: some View {
        Button(action: signOut) {
            Text("Sign Out")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .background(Color.primaryGradientEnd)
        .cornerRadius(8)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    profileHeader
                    
                    // Information Cards
                    VStack(spacing: 16) {
                        employeeInfoCard
                        contactInfoCard
                        licenseInfoView
                        signOutButton
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
    var textColor: Color = .primary // Default text color

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(textColor) // Apply the color to title
                .font(.headline)
            Spacer()
            Text(value)
                .foregroundColor(textColor) // Apply color dynamically
        }
        .padding(.vertical, 4)
    }
}

// Preview provider for ProfileView
//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        // Create sample data for preview
//        let sampleMetaData = UserMetaData(
//            id: UUID(),
//            fullName: "Arnav Chauhan",
//            email: "arnav@example.com",
//            phone: "+917043788123",
//            role: .fleetManager,
//            employeeID: 10,
//            firstTimeLogin: false,
//            createdAt: Date(),
//            activeStatus: true
//        )
//        
//        let sampleFleetManager = FleetManager(meta_data: sampleMetaData)
//        
//        let sampleAppUser = AppUser(userData: .fleetManager(sampleFleetManager))
//        
//        // Preview using StateObject wrapper
//        return ProfileView(
//            user: .constant(sampleAppUser),
//            role: .constant(.fleetManager)
//        )
//    }
//}

