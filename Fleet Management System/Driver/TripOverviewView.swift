
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
            
            LocationViewWrapper(coordinate: task.pickupLocation, type: .pickup)
            LocationViewWrapper(coordinate: task.destination, type: .destination)
            
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
//            Button(action: {
//                // Start trip action will be implemented later
//            }) {
//                Text("Start Trip")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                    .background(Color.primaryGradientStart)
//                    .cornerRadius(12)
//            }
//            .padding(.top)
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
