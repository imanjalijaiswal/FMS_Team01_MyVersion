import SwiftUI

struct TripSummaryView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    @State private var preInspection: [TripInspectionItem: Bool] = [:]
    @State private var postInspection: [TripInspectionItem: Bool] = [:]
    @State private var postTripNote: String = ""
    @State private var vehicle: Vehicle?
    @State private var fleetManager: UserMetaData?
    let dataController = IFEDataController.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Fleet Manager Details
                    FleetManagerCard(fleetManager: fleetManager)
                    
                    // Trip Status Card
                    TripStatusCard(task: trip)
                    
                    // Vehicle Details
                    VehicleDetailsCard(task: trip)
                    
                    // Locations Summary
                    LocationsCard(task: trip)
                    
                    // Pre-Trip Inspection Summary
                    InspectionSummaryCard(
                        title: "Pre-Trip Inspection",
                        inspection: preInspection,
                        isPreTrip: true
                    )
                    
                    // Post-Trip Inspection Summary
                    InspectionSummaryCard(
                        title: "Post-Trip Inspection",
                        inspection: postInspection,
                        note: postTripNote,
                        isPreTrip: false
                    )
                }
                .padding()
            }
            .background(Color.cardBackground)
            .navigationTitle("Trip Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGradientStart)
                }
            }
            .task {
                await loadTripData()
            }
        }
    }
    
    private func loadTripData() async {
        // Load inspection data
        if let inspection = await dataController.getTripInspectionForTrip(by: trip.id) {
            preInspection = inspection.preInspection
            postInspection = inspection.postInspection
            postTripNote = inspection.postInspectionNote
        }
        
        // Load vehicle data
        do {
            vehicle = try await RemoteController().getRegisteredVehicle(by: trip.assignedVehicleID)
        } catch {
            print("Error fetching vehicle: \(error)")
        }
        
        // Load fleet manager data
        if let fleetManagerData = await dataController.getUserMetaData(by: trip.assignedByFleetManagerID) {
            fleetManager = fleetManagerData
        }
    }
}

struct FleetManagerCard: View {
    let fleetManager: UserMetaData?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assigned By")
                .font(.headline)
            
            if let manager = fleetManager {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(.primaryGradientStart)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(manager.fullName)
                            .font(.headline)
                        Text("Fleet Manager")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.primaryGradientStart)
                        Text(manager.phone)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.primaryGradientStart)
                        Text(manager.email)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
                .padding(.top, 8)
            } else {
                Text("Loading fleet manager details...")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct InspectionSummaryCard: View {
    let title: String
    let inspection: [TripInspectionItem: Bool]
    var note: String = ""
    let isPreTrip: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(TripInspectionItem.allCases, id: \.self) { item in
                    HStack {
                        Text(item.rawValue)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: inspection[item] == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(inspection[item] == true ? .green : .red)
                    }
                }
            }
            
            if !isPreTrip && !note.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
} 
