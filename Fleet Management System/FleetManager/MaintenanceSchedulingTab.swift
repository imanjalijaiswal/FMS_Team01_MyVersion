import SwiftUI

struct MaintenanceSchedulingView: View {
    @State private var showScheduleForm = false
    @State private var searchText = ""
    @State private var selectedFilter = ""
    @StateObject private var viewModel = IFEDataController.shared
    
    private var scheduledCount: Int {
            viewModel.managerAssignedMaintenanceTasks.filter { $0.status == .scheduled }.count
        }
        
    private var inProgressCount: Int {
            viewModel.managerAssignedMaintenanceTasks.filter { $0.status == .inProgress }.count
        }
        
    private var completedCount: Int {
            viewModel.managerAssignedMaintenanceTasks.filter { $0.status == .completed }.count
        }
        
    private var totalCount: Int {
            viewModel.managerAssignedMaintenanceTasks.count
        }
        
        private var filters: [String] {
            [
                "All (\(totalCount))",
                "Scheduled (\(scheduledCount))",
                "In Progress (\(inProgressCount))",
                "Completed (\(completedCount))"
            ]
        }

    
    var filteredTasks: [MaintenanceTask] {
        let searchResults = viewModel.managerAssignedMaintenanceTasks.filter { task in
            if searchText.isEmpty { return true }
            
            return task.assignedTo.uuidString.localizedCaseInsensitiveContains(searchText) ||
                   String(task.vehicleID).localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case "In Progress":
            return searchResults.filter { $0.status == .inProgress }
        case "Scheduled":
            return searchResults.filter { $0.status == .scheduled }
        case "Completed":
            return searchResults.filter { $0.status == .completed }
        default:
            return searchResults.filter { _ in true }
        }
    }

    var body: some View {
        NavigationStack {
           VStack(spacing: 16) {
                SearchBar(text: $searchText)
                    .padding(.top, 8)
                
                FilterSection(
                    title: "",
                    filters: filters,
                    selectedFilter: $selectedFilter
                )
                
                ScrollView {
                    VStack(spacing: 16) {
                        if filteredTasks.isEmpty {
                            Text("No maintenance tasks available")
                            .foregroundColor(.gray)
                            .padding()
                        } else {
                            ForEach(filteredTasks) { task in
                                MaintenanceTaskCard(task: task)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Maintenance")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showScheduleForm = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primaryGradientEnd)
                    }
                }
            }
            .background(Color.white)
            .sheet(isPresented: $showScheduleForm) {
                MaintenanceScheduleFormView(viewModel: viewModel) { _ in
                }
                .background(Color(.systemGray6))
            }
        }
        .onAppear {
            if selectedFilter.isEmpty {
                selectedFilter = filters[0]
            }
        }
    }
}

struct MaintenanceTaskCard: View {
    let task: MaintenanceTask
    @StateObject private var viewModel = IFEDataController.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    HStack{
                        Text("Task ID:")
                            .font(.subheadline)
                        
                        Text("#\(task.taskID)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    if let personnel = viewModel.maintenancePersonnels.first(where: { $0.id == task.assignedTo }) {
                        Text(personnel.meta_data.fullName)
                            .font(.headline)
                    } else {
                        Text("Unknown Personnel")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                Text(task.status.rawValue)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(15)
            }

            // Vehicle Details section
            VStack(alignment: .leading, spacing: 4) {
                Text("Vehicle Details:")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let vehicle = viewModel.vehicles.first(where: { $0.id == task.vehicleID }) {
                    Text("\(vehicle.make) \(vehicle.model)")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    
                    Text(vehicle.licenseNumber)
                        .font(.subheadline)
                        .foregroundColor(.black)
                } else {
                    Text("Vehicle not found")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            // Add created date section
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                Text(task.createdAt.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct MaintenanceScheduleFormView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedPersonnel = UUID() // Changed to UUID
    @State private var selectedVehicle: Vehicle? = nil
    @State private var notes = ""
    @State private var showVehicleSelectionSheet = false
    @State private var showPersonnelSelectionSheet = false
    @State private var showSuccessAlert = false
    @State private var isDoneEnabled = false
    @State private var text:String = ""
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yyyy, h:mm a"
        return formatter
    }()
    
    @ObservedObject var viewModel: IFEDataController
    var onScheduleComplete: ((MaintenanceTask) -> Void)? = nil

    var vehicleDisplayText: String {
        if let vehicle = selectedVehicle {
            return "\(vehicle.make) \(vehicle.model)"
        }
        return "Select Vehicle"
    }

    var isFormValid: Bool {
        selectedVehicle != nil && selectedPersonnel != UUID()
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // Personnel Selection Card
                    Button(action: { showPersonnelSelectionSheet = true }) {
                        HStack {
                            Text("Maintenance Personnel")
                                .foregroundColor(.primary)
                            Spacer()
                            if let personnel = viewModel.maintenancePersonnels.first(where: { $0.id == selectedPersonnel }) {
                                Text(personnel.meta_data.fullName)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Select Personnel")
                                    .foregroundColor(.gray)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    
                    // Vehicle Selection Card
                    Button(action: { showVehicleSelectionSheet = true }) {
                        HStack {
                            Text("Vehicle")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(vehicleDisplayText)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    
                    // Notes Card
                    TextField("Maintenance Description", text: $notes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                
                }
                .padding()
            }
            .background(Color(.systemGray6))
            .sheet(isPresented: $showPersonnelSelectionSheet) {
                MaintenancePersonnelSelectionView(selectedPersonnel: $selectedPersonnel, viewModel: viewModel)
            }
            .sheet(isPresented: $showVehicleSelectionSheet) {
                VehicleSelectionView(viewModel: viewModel, selectedVehicle: $selectedVehicle)
            }
            .navigationTitle("Schedule Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.primaryGradientEnd)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        handleDoneButton()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(!isFormValid ? Color.gray : Color.primaryGradientStart)
                    .fontWeight(.regular)
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Maintenance has been scheduled successfully")
            }
        }
    }
    
    private func handleDoneButton() {
        if let vehicle = selectedVehicle {
            if let index = viewModel.vehicles.firstIndex(where: { $0.id == vehicle.id }) {
                viewModel.vehicles[index].status = .underMaintenance
            }
            
            let maintenanceNotes = notes.isEmpty ? "" : notes
            
            Task {
                if let newTask = await viewModel.assignNewMaintenanceTask(
                    by: viewModel.user?.id ?? UUID(),
                    to: selectedPersonnel,
                    for: vehicle.id,
                    ofType: .regularMaintenance,
                    maintenanceNotes
                ) {
                    onScheduleComplete?(newTask)
                    await viewModel.loadManagerAssignedMaintenanceTasks()
                    showSuccessAlert = true
                }
            }
        }
    }
}


//to select maintenancePersonnel in SchedulingForm
struct MaintenancePersonnelSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedPersonnel: UUID
    @ObservedObject var viewModel: IFEDataController
    @State private var searchText = ""
    @State private var temporarySelectedPersonnel: UUID? // Holds selection until confirmed
    
    var availablePersonnel: [MaintenancePersonnel] {
        let personnel = viewModel.maintenancePersonnels
        
        if searchText.isEmpty {
            return personnel
        }
        
        return personnel.filter { personnel in
            personnel.meta_data.fullName.lowercased().contains(searchText.lowercased()) ||
            String(personnel.meta_data.employeeID).contains(searchText) ||
            personnel.meta_data.phone.contains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.vertical, 8)
                
                if availablePersonnel.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(searchText.isEmpty ? "No available personnel" : "No matching personnel")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(availablePersonnel) { personnel in
                                Button(action: {
                                    if temporarySelectedPersonnel == personnel.id {
                    
                                        temporarySelectedPersonnel = nil
                                    } else {
                                        // Select new personnel
                                        temporarySelectedPersonnel = personnel.id
                                    }
                                }) {
                                    PersonnelRowView(
                                        personnel: personnel,
                                        isSelected: temporarySelectedPersonnel == personnel.id
                                    )
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color.white)
                }
            }
            .navigationTitle("Select Personnel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGradientEnd)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let personnel = temporarySelectedPersonnel {
                            selectedPersonnel = personnel
                        }
                        dismiss()
                    }
                    .disabled(temporarySelectedPersonnel == nil)
                    .foregroundColor(temporarySelectedPersonnel == nil ? .gray : .primaryGradientStart)
                }
            }
            .toolbarBackground(Color(.white), for: .navigationBar)
            .background(Color.white)
        }
    }
}

struct PersonnelRowView: View {
    let personnel: MaintenancePersonnel
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(personnel.meta_data.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("ID: \(personnel.meta_data.employeeID)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack {
                    Label(personnel.meta_data.phone, systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }
}
