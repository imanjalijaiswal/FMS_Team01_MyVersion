import SwiftUI
import Foundation


struct TripOverviewView: View {
    let task: Trip
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPreTripInspection = false
    @State private var showingPostTripInspection = false
    @State private var hasCompletedPreInspection = false
    @State private var hasCompletedPostInspection = false
    @State private var showPreInspectionAlert = false
    @State private var showPostInspectionAlert = false
    @State private var requiresMaintenance = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                contentView
            }
            .background(Color.cardBackground)
            .navigationTitle("Trip Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {  // ✅ Directly inside .toolbar
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
    }
    
    private var contentView: some View {
        VStack(spacing: 10) {
            TripStatusCard(task: task)
            VehicleDetailsCard(task: task)
            LocationsCard(task: task)
            StartTripButton(task: task,isInspectionCompleted: hasCompletedPreInspection,requiresMaintenance: requiresMaintenance,showInspection: $showingPreTripInspection)
            EndTripButton(task: task, isInspectionCompleted: hasCompletedPostInspection, showInspection: $showingPostTripInspection)
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
            PreTripInspectionChecklistView(trip: task) { inspection in
                let hasAnyFailure = inspection.preInspection.values.contains(false)
                hasCompletedPreInspection = inspection.preInspection.values.contains(true)
                requiresMaintenance = hasAnyFailure // Set maintenance flag if any item is false
            }
        }
    
    private var postTripInspectionSheet: some View {
        PostTripInspectionChecklistView(trip: task) { inspection in
            hasCompletedPostInspection = inspection.postInspection.values.contains(true)
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



struct StartTripButton: View {
    let task: Trip
    let isInspectionCompleted: Bool
    let requiresMaintenance: Bool // New parameter
    @Binding var showInspection: Bool
    @State private var showCancelAlert = false
    
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
                            // Start trip action will be implemented later
                        }
                    }) {
                        Text(isInspectionCompleted ? "Start Trip" : "Pre-Trip Inspection")
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
    
    var body: some View {
        if task.status == .inProgress {
            Button(action: {
                if !isInspectionCompleted {
                    showInspection = true
                } else {
                    // End trip action will be implemented later
                }
            }) {
                Text(isInspectionCompleted ? "End Trip" : "Post-Trip Inspection")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isInspectionCompleted ? Color.primaryGradientStart : Color.primaryGradientStart)
                    .cornerRadius(12)
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
    let onSave: (TripInspection) -> Void
    
    @State private var inspectionItems: [TripInspectionItem: Bool] = Dictionary(
        uniqueKeysWithValues: TripInspectionItem.allCases.map { ($0, false) }
    )
    @State private var preTripNote: String = ""
    
    private var isAnyItemChecked: Bool {
        inspectionItems.values.contains(true)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Pre-Trip Inspection Checklist")) {
                    ForEach(TripInspectionItem.allCases, id: \.self) { item in
                        CheckboxView(
                            title: item.rawValue,
                            isChecked: Binding(
                                get: { inspectionItems[item] ?? false }, // Changed default to false
                                set: { inspectionItems[item] = $0 }
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
                }
            }
            .navigationTitle("Pre-Trip Inspection")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onSave(TripInspection(
                            id: UUID(),
                            preInspection: [:], postInspection: [:], preInspectionNote: " " , postInspectionNote: ""
                        ))
                        dismiss()
                    }
                    .foregroundColor(.primaryGradientStart)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let inspection = TripInspection(
                            id: UUID(),
                            preInspection: inspectionItems,
                            postInspection: [:],
                            preInspectionNote: preTripNote, postInspectionNote: ""
                        )
                        onSave(inspection)
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
    let onSave: (TripInspection) -> Void
    
    @State private var inspectionItems: [TripInspectionItem: Bool] = Dictionary(
        uniqueKeysWithValues: TripInspectionItem.allCases.map { ($0, false) }  // Initialize all as false
    )
    @State private var postTripNote: String = ""
    
    private var isAnyItemChecked: Bool {
        inspectionItems.values.contains(true)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Post-Trip Inspection Checklist")) {
                    ForEach(TripInspectionItem.allCases, id: \.self) { item in
                        CheckboxView(
                            title: item.rawValue,
                            isChecked: Binding(
                                get: { inspectionItems[item] ?? true },
                                set: { inspectionItems[item] = $0 }
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
                }
            }
            .navigationTitle("Post-Trip Inspection")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGradientStart)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let inspection = TripInspection(
                            id: UUID(),
                            preInspection: [:],
                            postInspection: inspectionItems,
                            preInspectionNote: "",
                            postInspectionNote: postTripNote
                        )
                        onSave(inspection)
                        dismiss()
                    }
                    .disabled(!isAnyItemChecked)
                    .foregroundColor(isAnyItemChecked ? .primaryGradientStart : .gray)
                }
            }
        }
    }
}

