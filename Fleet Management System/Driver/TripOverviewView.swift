import SwiftUI

//struct TripOverviewView: View {
//    let task: Trip
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 10) {
//                    // Trip Status Card
//                    VStack(alignment: .leading, spacing: 12) {
//                        HStack {
//                            Text("Trip Status")
//                                .font(.headline)
//                            Spacer()
//                            Text(task.status.rawValue)
//                                .font(.caption)
//                                .fontWeight(.medium)
//                                .padding(.horizontal, 8)
//                                .padding(.vertical, 4)
//                                .background(task.type.color.opacity(0.2))
//                                .foregroundColor(task.type.color)
//                                .cornerRadius(4)
//                        }
//                        
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("Trip ID")
//                                    .font(.caption)
//                                    .foregroundColor(.textSecondary)
//                                Text("\(task.tripID)")
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                            }
//                            
//                            Spacer()
//                            
//                            VStack(alignment: .trailing, spacing: 4) {
//                                Text("Date")
//                                    .font(.caption)
//                                    .foregroundColor(.textSecondary)
//                                Text(task.scheduledDateTime,style : .date)
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                            }
//                        }
//                    }
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(12)
//                    
//                    // Partner Details Card
////                    VStack(alignment: .leading, spacing: 12) {
////                        Text("Partner Details")
////                            .font(.headline)
////                        
////                        HStack(spacing: 12) {
////                            Image(systemName: "person.circle.fill")
////                                .resizable()
////                                .frame(width: 40, height: 40)
////                                .foregroundColor(.primaryGradientStart)
////                            
////                            VStack(alignment: .leading, spacing: 4) {
////                                Text(task.partner.name)
////                                    .font(.subheadline)
////                                    .fontWeight(.medium)
////                                Text(task.partner.company)
////                                    .font(.caption)
////                                    .foregroundColor(.textSecondary)
////                            }
////                        }
////                        
////                        Divider()
////                        
////                        VStack(alignment: .leading, spacing: 8) {
////                            HStack {
////                                Image(systemName: "phone.fill")
////                                    .foregroundColor(.primaryGradientStart)
////                                Text(task.partner.contactNumber)
////                                    .font(.subheadline)
////                            }
////                            
////                            HStack {
////                                Image(systemName: "envelope.fill")
////                                    .foregroundColor(.primaryGradientStart)
////                                Text(task.partner.email)
////                                    .font(.subheadline)
////                            }
////                        }
////                    }
////                    .padding()
////                    .background(Color.white)
////                    .cornerRadius(12)
//                    
//                    // Vehicle Details Card
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Vehicle Details")
//                            .font(.headline)
//                        
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("Vehicle ID")
//                                    .font(.caption)
//                                    .foregroundColor(.textSecondary)
//                                Text("\(task.assigneVehicleID)")
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                            }
//                            
//                            Spacer()
//                            
////                            VStack(alignment: .trailing, spacing: 4) {
////                                Text("Number Plate")
////                                    .font(.caption)
////                                    .foregroundColor(.textSecondary)
////                                Text(task.numberPlate)
////                                    .font(.subheadline)
////                                    .fontWeight(.medium)
////                                    .foregroundColor(.statusOrange)
////                            }
//                        }
//                    }
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(12)
//                    
//                    // Locations Card
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Locations")
//                            .font(.headline)
//                        
//                        LocationView(location: Location(name: "Pickup", address: task.pickupLocation), type: .pickup)
//                        LocationView(location: Location(name: "Destination", address: task.destination), type: .destination)
//                        HStack {
//                            VStack{
//                                Text("Total Distance")
//                                    .font(.caption)
//                                    .foregroundColor(.textSecondary)
//                                Text("\(task.totalDistance) km")
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                            }
//                            Spacer()
//                            VStack{
//                                Text("Estimated Time")
//                                    .font(.caption)
//                                    .foregroundColor(.textSecondary)
//                                Text("\(Int(task.totalTripDuration.timeIntervalSince(task.scheduledDateTime)/3600)) hours")
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                            }
//                        }
//                    }
//                    .padding()
//                    .background(Color.white)
//                    .cornerRadius(12)
//                    
//                    // Start Trip Button - Only show for assigned trips
//                    if task.status == .scheduled {
//                        Button(action: {
//                            // Start trip action will be implemented later
//                        }) {
//                            Text("Start Trip")
//                                .font(.headline)
//                                .foregroundColor(.white)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.primaryGradientStart)
//                                .cornerRadius(12)
//                        }
//                        .padding(.top)
//                    }
//                }
//                .padding()
//            }
//            .background(Color.cardBackground)
//            .navigationTitle("Trip Overview")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: { dismiss() }) {
//                        Text("Cancel")
//                            .font(.subheadline)
//                            .foregroundColor(.primaryGradientStart)
//                    }
//                }
//            }
//        }
//    }
//}
//
//#Preview {
//    TripOverviewView(task: Trip(
//            id: UUID(),
//            tripID: 1,
//            assignedByFleetManagerID: UUID(),
//            assignedDriverIDs: [UUID()],
//            assigneVehicleID: 1,
//            pickupLocation: "Bhiwandi Logistics Park, Mumbai-Nashik Highway, Maharashtra",
//            destination: "Attibele Industrial Area, Hosur Road, Bangalore",
//            estimatedArrivalDateTime: Date().addingTimeInterval(14*3600),
//            totalDistance: 985,
//            totalTripDuration: Date().addingTimeInterval(14*3600),
//            description: "Electronics, 2500 kg",
//            scheduledDateTime: Date(),
//            createdAt: Date(),
//            status: .scheduled
//        ))
//}


import SwiftUI

struct TripOverviewView: View {
    let task: Trip
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 10) {
                    TripStatusCard(task: task)
                    VehicleDetailsCard(task: task)
                    LocationsCard(task: task)
                    StartTripButton(task: task)
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

// Sub-view for Trip Status
struct TripStatusCard: View {
    let task: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trip Status")
                    .font(.headline)
                Spacer()
                // Note: task.type doesn't exist, using task.status instead
                Text(task.status.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .cornerRadius(4)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trip ID")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("\(task.tripID)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Date")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(task.scheduledDateTime, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// Sub-view for Vehicle Details
struct VehicleDetailsCard: View {
    let task: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle Details")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vehicle ID")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("\(task.assignedVehicleID)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// Sub-view for Locations
struct LocationsCard: View {
    let task: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Locations")
                .font(.headline)
            
            LocationView(location: Location(name: "Pickup", address: task.pickupLocation), type: .pickup)
            LocationView(location: Location(name: "Destination", address: task.destination), type: .destination)
            
            HStack {
                VStack {
                    Text("Total Distance")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("\(task.totalDistance) km")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                Spacer()
                VStack {
                    Text("Estimated Time")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("\(Int(task.totalTripDuration.timeIntervalSince(task.scheduledDateTime)/3600)) hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// Sub-view for Start Trip Button
struct StartTripButton: View {
    let task: Trip
    
    var body: some View {
        if task.status == .scheduled {
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
}

#Preview {
    TripOverviewView(task: Trip(
        id: UUID(),
        tripID: 1,
        assignedByFleetManagerID: UUID(),
        assignedDriverIDs: [UUID()],
        assignedVehicleID: 1,
        pickupLocation: "Bhiwandi Logistics Park, Mumbai-Nashik Highway, Maharashtra",
        destination: "Attibele Industrial Area, Hosur Road, Bangalore",
        estimatedArrivalDateTime: Date().addingTimeInterval(14*3600),
        totalDistance: 985,
        totalTripDuration: Date().addingTimeInterval(14*3600),
        description: "Electronics, 2500 kg",
        scheduledDateTime: Date(),
        createdAt: Date(),
        status: .scheduled
    ))
}
