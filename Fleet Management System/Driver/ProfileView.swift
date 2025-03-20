import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var user: AppUser?
    @Binding var role : Role?
    // Sample driver data with Indian standards
    let driver = DriverProfile(
        employeeId: "EMP-2024-001",
        fullName: "Rajesh Kumar Singh",
        email: "rajesh.singh@driver.com",
        phoneNumber: "+91 98765 43210",
        drivingLicense: "DL-01-2024-1234567" // Format: DL-{State Code}-{Year}-{7 digits}
    )
    func signOut() {
        Task {
            do {
                dismiss()
                try await AuthManager.shared.signOut()
//                let newTrip = Trips(
//                    tripId: "TRP-2024-003",
//                    truckType: "BharatBenz 2823C",
//                    numberPlate: "DL 01 HH 9876",
//                    type: .assigned,
//                    date: "Thursday - Mar 21, 2024",
//                    details: "Auto Parts, 3200 kg",
//                    pickup: Location(
//                        name: "Maruti Suzuki Plant",
//                        address: "IMT Manesar, Gurugram, Haryana"
//                    ),
//                    destination: Location(
//                        name: "Tata Motors Factory",
//                        address: "MIDC Pimpri, Pune, Maharashtra"
//                    ),
//                    distance: "1420 km",
//                    estimatedTime: "20 hours",
//                    partner: Partner(
//                        name: "Amit Patel",
//                        company: "Maruti Suzuki",
//                        contactNumber: "+91 76543 21098",
//                        email: "amit.patel@maruti.com"
//                    )
//                )
                DispatchQueue.main.async {
                
                    user = nil
                    role = nil
                }

            } catch {
                print("Error signing out: \(error)")
            }
        }
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
                        
                        Text(driver.fullName)
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
                            
                            InfoRow(title: "Employee ID", value: driver.employeeId)
                            InfoRow(title: "Full Name", value: driver.fullName)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // Contact Information Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact Information")
                                .font(.headline)
                            
                            Divider()
                            
                            InfoRow(title: "Email", value: driver.email)
                            InfoRow(title: "Phone Number", value: driver.phoneNumber)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        // License Information Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("License Information")
                                .font(.headline)
                            
                            Divider()
                            
                            InfoRow(title: "Driving License", value: driver.drivingLicense)
                            Text("Format: DL-{State Code}-{Year}-{7 digits}")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .padding(.top, 4)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
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

struct DriverProfile {
    let employeeId: String
    let fullName: String
    let email: String
    let phoneNumber: String
    let drivingLicense: String
}

