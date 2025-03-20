import SwiftUI

struct TripOverviewView: View {
    let task: Trips
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    // Trip Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Trip Status")
                                .font(.headline)
                            Spacer()
                            Text(task.type.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(task.type.color.opacity(0.2))
                                .foregroundColor(task.type.color)
                                .cornerRadius(4)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Trip ID")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text(task.tripId)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Date")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text(task.date)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Partner Details Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Partner Details")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.primaryGradientStart)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.partner.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(task.partner.company)
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.primaryGradientStart)
                                Text(task.partner.contactNumber)
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.primaryGradientStart)
                                Text(task.partner.email)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Vehicle Details Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Vehicle Details")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Truck Type")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text(task.truckType)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Number Plate")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text(task.numberPlate)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.statusOrange)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Locations Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Locations")
                            .font(.headline)
                        
                        LocationView(location: task.pickup, type: .pickup)
                        LocationView(location: task.destination, type: .destination)
                        
                        HStack {
                            VStack{
                                Text("Total Distance")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text(task.distance)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            VStack{
                                Text("Estimated Time")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text(task.estimatedTime)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    // Start Trip Button - Only show for assigned trips
                    if task.type == .assigned {
                        Button(action: {
                            // Start trip action will be implemented later
                        }) {
                            Text("Start Trip")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.primaryGradientStart)
                                .cornerRadius(12)
                        }
                        .padding(.top)
                    }
                }
                .padding()
            }
            .background(Color.cardBackground)
            .navigationTitle("Trip Overview")
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

#Preview {
    TripOverviewView(task: Trips(
        tripId: "TRP-2024-001",
        truckType: "Tata Prima LX 2823.K",
        numberPlate: "MH 04 HJ 1234",
        type: .assigned,
        date: "Today",
        details: "Electronics, 2500 kg",
        pickup: Location(
            name: "Amazon Warehouse",
            address: "Bhiwandi Logistics Park, Mumbai-Nashik Highway, Maharashtra"
        ),
        destination: Location(
            name: "Amazon FC",
            address: "Attibele Industrial Area, Hosur Road, Bangalore"
        ),
        distance: "985 km",
        estimatedTime: "14 hours",
        partner: Partner(
            name: "Priya Sharma",
            company: "Amazon Logistics",
            contactNumber: "+91 98765 43210",
            email: "priya.sharma@amazon.com"
        )
    ))
} 
