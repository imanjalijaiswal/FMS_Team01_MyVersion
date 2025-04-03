import SwiftUI
import CoreLocation
import Foundation


struct TripOverviewView: View {
    let task: Trip
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    let isInDestinationGeofence: Bool
    @State private var showingPostTripInspection = false
    @State private var hasCompletedPostInspection = false
    @State private var showPostInspectionAlert = false
    @State private var showingMapView = false
    @State private var showingTripSummary = false
    @State private var timer: Timer?
    let dataController = IFEDataController.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                contentView
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
            .sheet(isPresented: $showingPostTripInspection, onDismiss: {
                if !hasCompletedPostInspection {
                    showPostInspectionAlert = true
                }
            }) {
                postTripInspectionSheet
            }
            .alert("Inspection Required", isPresented: $showPostInspectionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot end journey without filling Post-Trip Inspection list")
            }
            .fullScreenCover(isPresented: $showingMapView) {
                MapView(selectedTab: $selectedTab)
                    .onAppear {
                        // Set the current trip in the MapViewModel
                        if let mapViewModel = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController?.view.window?.rootViewController?.children.first?.children.first?.children.first as? MapView {
                            mapViewModel.viewModel.setCurrentTrip(task)
                        }
                    }
            }
        }
        .onAppear {
            // Start the timer when the view appears
            startTimer()
        }
        .onDisappear {
            // Stop the timer when the view disappears
            stopTimer()
        }
        .navigationViewStyle(.stack)
        .task {
            if let inspection = await IFEDataController.shared.getTripInspectionForTrip(by: task.id) {
                hasCompletedPostInspection = !inspection.postInspection.isEmpty
            }
        }
    }
    private func startTimer() {
        // Create a timer that fires every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                await checkInspectionStatus()
            }
        }
    }
    private func checkInspectionStatus() async {
        if let inspection = await dataController.getTripInspectionForTrip(by: task.id) {
            hasCompletedPostInspection = !inspection.postInspection.isEmpty
        }
    }
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private var contentView: some View {
        VStack(spacing: 10) {
            TripStatusCard(task: task)
            if task.assignedDriverIDs.count > 1 {
                TripPartnerView(task: task)
            }
            VehicleDetailsCard(task: task)
            LocationsCard(task: task)
            
            if task.status == .scheduled {
                Button(action: {
                    // Mark trip as active and show map view
                    dismiss
                    dataController.updateTripStatus(task, to: .inProgress)
                }) {
                    Text("Mark as Active")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryGradientStart)
                        .cornerRadius(12)
                }
                .padding(.top)
            }
            
            if task.status == .inProgress && !hasCompletedPostInspection && !isInDestinationGeofence {
                Button(action: {
                    showingMapView = true
                }) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Open Navigation")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGradientStart)
                    .cornerRadius(12)
                }
                .padding(.top)
            }
            
            
            EndTripButton(task: task, isInspectionCompleted: hasCompletedPostInspection, showInspection: $showingPostTripInspection, isInDestinationGeofence: isInDestinationGeofence)
        }
        .padding()
    }
    
    private var postTripInspectionSheet: some View {
        PostTripInspectionChecklistView(trip: task) { inspectionItems, note in
            hasCompletedPostInspection = !inspectionItems.isEmpty
            IFEDataController.shared.addPostTripInspectionForTrip(
                by: task.id,
                inspection: inspectionItems,
                note: note)
            
            Task {
                if let inspection = await IFEDataController.shared.getTripInspectionForTrip(by: task.id) {
                    hasCompletedPostInspection = !inspection.postInspection.isEmpty
                }
            }
        }
    }
}

// Sub-view for Trip Status
struct TripStatusCard: View {
    let task: Trip
    var statusColor: Color {
        switch task.status {
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .scheduled:
            return .orange
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trip Status")
                    .font(.headline)
                Spacer()
                // Note: task.type doesn't exist, using task.status instead
                Text(task.status.rawValue)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
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

struct TripPartnerView: View {
    let task: Trip
    @State private var partner: UserMetaData?
    let dataController = IFEDataController.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Partner Details")
                .font(.title3)
                .fontWeight(.semibold)
            
            Group {
                if let partner = partner {
                    // Partner info section
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.primaryGradientStart)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(partner.fullName)
                                .font(.headline)
                            Text("Amazon Logistics")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Contact info section
                    VStack(spacing: 12) {
                        Button(action: { 
                            if let url = URL(string: "tel://\(partner.phone)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.primaryGradientStart)
                                Text(partner.phone)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                        
                        Button(action: { 
                            if let url = URL(string: "mailto:\(partner.email)") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.primaryGradientStart)
                                Text(partner.email)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 8)
                } else {
                    // Loading state
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.gray.opacity(0.3))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 16)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 14)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.gray.opacity(0.3))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 16)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.gray.opacity(0.3))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 150, height: 16)
                            Spacer()
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .task {
            // Get the current user's ID
            if let currentUserId = dataController.user?.id {
                // Find the partner's ID (the one that's not the current user)
                if let partnerId = task.assignedDriverIDs.first(where: { $0 != currentUserId }) {
                    // Fetch partner's metadata
                    if let partnerMetaData = await dataController.getUserMetaData(by: partnerId) {
                        partner = partnerMetaData
                    }
                }
            }
        }
    }
}

// Sub-view for Vehicle Details
struct VehicleDetailsCard: View {
    let task: Trip
    @State private var vehicle: Vehicle?
    var remoteController = RemoteController()
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle Details")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let vehicle = vehicle {
                        HStack{
                            VStack(alignment: .leading, spacing: 4){
                                Text("Name")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text("\(vehicle.make) \(vehicle.model)") // Show vehicle name instead of ID
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4){
                                Text("License Number")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                                Text("\(vehicle.licenseNumber)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.statusOrange)
                            }
                        }
                    } else {
                        Text("Loading...")
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
        }
        .task {
            await fetchVehicle() // Fetch vehicle data when TaskCard appears
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    private func fetchVehicle() async {
        do {
            vehicle = try await remoteController.getRegisteredVehicle(by: task.assignedVehicleID)
        } catch {
            print("Error fetching vehicle: \(error)")
        }
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
                    Text("\(Int(task.totalDistance)/50) hours")
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



struct EndTripButton: View {
    let task: Trip
    @State var isInspectionCompleted: Bool = false
    @Binding var showInspection: Bool
    @State private var showCancelAlert = false
    @State private var timer: Timer?
    @State private var showingTripSummary = false
    var dataController = IFEDataController.shared
    let isInDestinationGeofence: Bool
    
    var body: some View {
        if task.status == .inProgress {
            VStack(spacing: 8) {
                if isInspectionCompleted {
                    Button(action: {
                        // End trip action
                        dataController.updateTripStatus(task, to: .completed)
                        // Show trip summary
                    }) {
                        Text("Mark as Completed")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primaryGradientStart)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.top)
            .onAppear {
                // Start the timer when the view appears
                startTimer()
            }
            .onDisappear {
                // Stop the timer when the view disappears
                stopTimer()
            }
            .task {
                // Initial check
                await checkInspectionStatus()
            }
            .sheet(isPresented: $showingTripSummary) {
                TripSummaryView(trip: task)
            }
        }
    }
    
    private func startTimer() {
        // Create a timer that fires every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task {
                await checkInspectionStatus()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkInspectionStatus() async {
        if let inspection = await dataController.getTripInspectionForTrip(by: task.id) {
            isInspectionCompleted = !inspection.postInspection.isEmpty
        }
    }
}


// Add this custom checkbox view before the inspection views
struct CheckboxView: View {
    let title: String
    @Binding var isChecked: Bool
    
    var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: isChecked ? "checkmark.square.fill" : "xmark.square.fill")
                    .foregroundColor(isChecked ? .primaryGradientStart : .red)
            }
            .contentShape(Rectangle())
        }
    }
}
                  


struct PostTripInspectionChecklistView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    let onSave: ([TripInspectionItem: Bool], String) -> Void
    
    @State private var inspectionItems: [TripInspectionItem: Bool] = Dictionary(
        uniqueKeysWithValues: TripInspectionItem.allCases.map { ($0, false) }
    )
    @State private var postTripNote: String = ""
    
    private var isAnyItemChecked: Bool {
        inspectionItems.values.contains(true)
    }
    
    @State private var allGood: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    CheckboxView(
                        title: "All Good",
                        isChecked: Binding(
                            get: { allGood },
                            set: { newValue in
                                allGood = newValue
                                // Update all items when "All Good" is toggled
                                for item in TripInspectionItem.allCases {
                                    inspectionItems[item] = newValue
                                }
                                print("All Good toggled: \(allGood), inspectionItems: \(inspectionItems)")
                            }
                        )
                    )
                }
                
                Section(header: Text("Post-Trip Inspection Checklist")) {
                    ForEach(TripInspectionItem.allCases, id: \.self) { item in
                        CheckboxView(
                            title: item.rawValue,
                            isChecked: Binding(
                                get: { inspectionItems[item] ?? false },
                                set: { newValue in
                                    inspectionItems[item] = newValue
                                    // Recalculate allGood based on all items
                                    allGood = inspectionItems.values.allSatisfy { $0 }
                                    print("Item \(item.rawValue) toggled: \(newValue), inspectionItems: \(inspectionItems)")
                                }
                            )
                        )
                    }
                }
                
                Section(header: Text("Description (Optional)")) {
                    TextEditor(text: $postTripNote)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if postTripNote.isEmpty {
                                    Text("Enter the issue in vehicle")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                        .onChange(of: postTripNote) { newValue in
                            print("Post-Trip Note updated: \(newValue)")
                        }
                }
            }
            .navigationTitle("Post-Trip Inspection")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("Cancel pressed, passing: inspectionItems: [:], note: ''")
                        onSave([:], "") // Pass empty dictionary to indicate cancellation
                        dismiss()
                    }
                    .foregroundColor(.primaryGradientStart)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("Save pressed, passing: inspectionItems: \(inspectionItems), note: \(postTripNote)")
                        onSave(inspectionItems, postTripNote) // Pass current state
                        dismiss()
                    }
                    .disabled(!isAnyItemChecked)
                    .foregroundColor(isAnyItemChecked ? .primaryGradientStart : .gray)
                }
            }
        }
    }
}

func findNearestServiceCenter(to coordinate: String) async -> ServiceCenter? {
    let components = coordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    guard components.count == 2,
          let latitude = Double(components[0]),
          let longitude = Double(components[1]) else {
        print("Invalid vehicle coordinate format")
        return nil
    }
    
    let vehicleLocation = CLLocation(latitude: latitude, longitude: longitude)
    let serviceCenters = IFEDataController.shared.serviceCenters
    
    // Sort service centers by distance
    var sortedCenters = serviceCenters.map { center -> (ServiceCenter, CLLocationDistance) in
        guard let centerCoords = parseCoordinates(center.coordinate) else {
            return (center, .greatestFiniteMagnitude)
        }
        let centerLocation = CLLocation(latitude: centerCoords.latitude, longitude: centerCoords.longitude)
        let distance = vehicleLocation.distance(from: centerLocation)
        return (center, distance)
    }.sorted { $0.1 < $1.1 }
    
    // Iterate through sorted centers until we find one with active maintenance personnel
    for (center, distance) in sortedCenters {
        // *** CHANGE 1: Skip if service center is not assigned (inactive) ***
        guard center.isAssigned else {
            print("Service center \(center.id) is not assigned, skipping...")
            continue
        }
        
        // *** CHANGE 2: Check maintenance personnel availability and activity ***
        guard let personnelMetaData = await IFEDataController.shared.getMaintenancePersonnelMetaData(ofCenter: center.id) else {
            print("No maintenance personnel found for service center \(center.id), skipping...")
            continue
        }
        
        // *** CHANGE 3: Verify personnel active status ***
        guard personnelMetaData.activeStatus else {
            print("Maintenance personnel for service center \(center.id) is inactive (ID: \(personnelMetaData.id)), skipping...")
            continue
        }
        
        print("Found active service center \(center.id) with active personnel \(personnelMetaData.id) at distance: \(distance) meters")
        return center
    }
    
    print("No active service center with active maintenance personnel found")
    return nil
}

func assignMaintenanceTaskForFailedItems(inspectionItems: [TripInspectionItem: Bool], note: String, trip: Trip, isPreTrip: Bool) async {
    // Filter failed items
    let failedItems = inspectionItems.filter { !$0.value }
    guard !failedItems.isEmpty else { return }
    
    // Create issue note using TripInspection.issueDescription
    let issueDescriptions = failedItems.map { item in
        "\(item.key.rawValue): \(TripInspection.issueDescription[item.key] ?? "Issue detected.")"
    }.joined(separator: "\n")
    
    let inspectionType = isPreTrip ? "Pre-Trip" : "Post-Trip"
    let fullIssueNote = "\(inspectionType) Inspection Failures:\n\(issueDescriptions)\n\nAdditional Note: \(note)"
    
    // Get the vehicle's current coordinate
    guard let vehicle = await IFEDataController.shared.getRegisteredVehicle(by: trip.assignedVehicleID) else {
        print("Failed to fetch vehicle for maintenance task assignment")
        return
    }
    
    // *** CHANGE 4: Use the updated findNearestServiceCenter function ***
    guard let nearestServiceCenter = await findNearestServiceCenter(to: vehicle.currentCoordinate) else {
        print("No available active service center with active personnel found")
        return
    }
    
    // Debug: Log service center details
    print("Nearest Service Center ID: \(nearestServiceCenter.id)")
    
    // Fetch the maintenance personnel metadata for this service center
    guard let personnelMetaData = await IFEDataController.shared.getMaintenancePersonnelMetaData(ofCenter: nearestServiceCenter.id) else {
        print("No maintenance personnel metadata found for service center \(nearestServiceCenter.id)")
        return
    }
    
    // *** CHANGE 5: Remove redundant active status check since findNearestServiceCenter already ensures this ***
    // No need to check personnelMetaData.activeStatus here
    
    // Debug: Log personnel details
    print("Assigned Personnel: ID: \(personnelMetaData.id), Name: \(personnelMetaData.fullName), Active: \(personnelMetaData.activeStatus)")
    
    // Assign the maintenance task
    let assignedBy = IFEDataController.shared.user?.id ?? trip.assignedByFleetManagerID
    guard let task = await IFEDataController.shared.assignNewMaintenanceTask(
        by: assignedBy,
        to: personnelMetaData.id,
        for: trip.assignedVehicleID,
        ofType: .preInspectionMaintenance,
        fullIssueNote
    ) else {
        print("Failed to assign maintenance task")
        return
    }
    
    print("Maintenance task assigned: \(task)")
}


private func parseCoordinates(_ coordinate: String) -> (latitude: Double, longitude: Double)? {
    let components = coordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    guard components.count == 2,
          let latitude = Double(components[0]),
          let longitude = Double(components[1]) else {
        return nil
    }
    return (latitude, longitude)
}
