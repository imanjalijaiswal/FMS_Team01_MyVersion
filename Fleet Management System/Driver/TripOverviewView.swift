import SwiftUI
import Foundation


struct TripOverviewView: View {
    let task: Trip
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    let isInDestinationGeofence: Bool
    @State private var showingPreTripInspection = false
    @State private var showingPostTripInspection = false
    @State private var hasCompletedPreInspection = false
    @State private var hasCompletedPostInspection = false
    @State private var showPreInspectionAlert = false
    @State private var showPostInspectionAlert = false
    @State private var requiresMaintenance = false
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
            .sheet(isPresented: $showingPreTripInspection, onDismiss: {
                if !hasCompletedPreInspection {
                    showPreInspectionAlert = true
                }
            }) {
                preTripInspectionSheet
            }
            .sheet(isPresented: $showingPostTripInspection, onDismiss: {
                if !hasCompletedPostInspection {
                    showPostInspectionAlert = true
                }
            }) {
                postTripInspectionSheet
            }
            .alert("Inspection Required", isPresented: $showPreInspectionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot start journey without filling Pre-Trip Inspection list")
            }
            .alert("Inspection Required", isPresented: $showPostInspectionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot end journey without filling Post-Trip Inspection list")
            }
        }
        .task {
            // Replace onAppear with task modifier for async operations
            if let inspection = await IFEDataController.shared.getTripInspectionForTrip(by: task.id) {
                hasCompletedPreInspection = !inspection.preInspection.isEmpty
                hasCompletedPostInspection = !inspection.postInspection.isEmpty
                requiresMaintenance = inspection.preInspection.values.contains(false)
            }
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 10) {
            TripStatusCard(task: task)
            TripPartnerView(task: task)
            VehicleDetailsCard(task: task)
            LocationsCard(task: task)
            StartTripButton(task: task, isInspectionCompleted: hasCompletedPreInspection, requiresMaintenance: requiresMaintenance, showInspection: $showingPreTripInspection, selectedTab: $selectedTab, onStartTrip: {
                selectedTab = 1
                // Update trip status to inProgress
                    dataController.updateTripStatus(task, to: .inProgress)
                dismiss()
            })
            EndTripButton(task: task, isInspectionCompleted: hasCompletedPostInspection, showInspection: $showingPostTripInspection, isInDestinationGeofence: isInDestinationGeofence)
        }
        .padding()
    }
    
    private var leadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.subheadline)
                    .foregroundColor(.primaryGradientStart)
            }
        }
    }
    
    
    private var preTripInspectionSheet: some View {
        PreTripInspectionChecklistView(trip: task) { inspectionItems, note in
            let hasAnyFailure = inspectionItems.values.contains(false)
            hasCompletedPreInspection = !inspectionItems.isEmpty
            requiresMaintenance = hasAnyFailure
            IFEDataController.shared.addPreTripInspectionForTrip(
                by: task.id,
                inspection: inspectionItems,
                note: note
            )
        }
    }
    
    private var postTripInspectionSheet: some View {
        PostTripInspectionChecklistView(trip: task) { inspectionItems, note in
            hasCompletedPostInspection = !inspectionItems.isEmpty
            IFEDataController.shared.addPostTripInspectionForTrip(
                by: task.id,
                inspection: inspectionItems,
                note: note
            )
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



struct StartTripButton: View {
    let task: Trip
    let isInspectionCompleted: Bool
    let requiresMaintenance: Bool
    @Binding var showInspection: Bool
    @State private var showCancelAlert = false
    @Binding var selectedTab: Int
    let onStartTrip: () -> Void
    let dataController = IFEDataController.shared
    
    var body: some View {
        if task.status == .scheduled {
            VStack {
                if requiresMaintenance {
                    Text("You Cannot Start Trip As Vehicle is Lined Up for Maintenance")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                } else {
                    Button(action: {
                        if !isInspectionCompleted {
                            showInspection = true
                        } else {
                            // Start trip action and dismiss modal
                            onStartTrip()
                        }
                    }) {
                        Text(isInspectionCompleted ? "Go to Navigation to Start Trip" : "Pre-Trip Inspection")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isInspectionCompleted ? Color.primaryGradientStart : Color.primaryGradientStart)
                            .cornerRadius(12)
                    }
                    .alert("Inspection Required", isPresented: $showCancelAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("You cannot start journey without filling Pre-Trip Inspection list")
                    }
                }
            }
            .padding(.top)
        }
    }
}

struct EndTripButton: View {
    let task: Trip
    let isInspectionCompleted: Bool
    @Binding var showInspection: Bool
    @State private var showCancelAlert = false
    let isInDestinationGeofence: Bool
    var dataController = IFEDataController.shared
    
    var body: some View {
        if task.status == .inProgress {
            VStack(spacing: 8) {
                if !isInDestinationGeofence {
                    Text("You must be at the destination to complete the trip")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    if !isInspectionCompleted {
                        showInspection = true
                    } else {
                        // End trip action will be implemented later
                        dataController.updateTripStatus(task, to: .completed)
                    }
                }) {
                    Text(isInspectionCompleted ? "End Trip" : "Post-Trip Inspection")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isInDestinationGeofence ? Color.primaryGradientStart : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isInDestinationGeofence)
            }
            .padding(.top)
            .alert("Inspection Required", isPresented: $showCancelAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You cannot end journey without filling Post-Trip Inspection list")
            }
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
                  


struct PreTripInspectionChecklistView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    let onSave: ([TripInspectionItem: Bool], String) -> Void

    @State private var inspectionItems: [TripInspectionItem: Bool] = Dictionary(
        uniqueKeysWithValues: TripInspectionItem.allCases.map { ($0, false) }
    )
    @State private var preTripNote: String = ""
    
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
                
                Section(header: Text("Pre-Trip Inspection Checklist")) {
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
                    TextEditor(text: $preTripNote)
                        .frame(minHeight: 100)
                        .overlay(
                            Group {
                                if preTripNote.isEmpty {
                                    Text("Enter the issue in vehicle")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 8)
                                }
                            },
                            alignment: .topLeading
                        )
                        .onChange(of: preTripNote) { newValue in
                            print("Pre-Trip Note updated: \(newValue)")
                        }
                }
            }
            .navigationTitle("Pre-Trip Inspection")
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
                        print("Save pressed, passing: inspectionItems: \(inspectionItems), note: \(preTripNote)")
                        
                        onSave(inspectionItems, preTripNote) // Pass current state
                        dismiss()
                    }
                    .disabled(!isAnyItemChecked)
                    .foregroundColor(isAnyItemChecked ? .primaryGradientStart : .gray)
                }
            }
        }
    }
}




// Update PostTripInspectionChecklistView initialization
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
