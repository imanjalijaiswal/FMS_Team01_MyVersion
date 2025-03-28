import SwiftUI

struct MaintenanceSchedulingView: View {
    @State private var showScheduleForm = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @StateObject private var viewModel = IFEDataController.shared
    @State private var maintenanceSchedules: [MaintenanceSchedule] = [
        MaintenanceSchedule(
            ticketNumber: 1001,
            maintenancePersonnel: "John Smith",
            vehiclePlate: "ABC-123",
            vehicleModel: "Toyota Camry",
            scheduledDateTime: Date().addingTimeInterval(86400),
            status: "Scheduled"
        ),
        MaintenanceSchedule(
            ticketNumber: 1002,
            maintenancePersonnel: "Mike Johnson",
            vehiclePlate: "XYZ-789",
            vehicleModel: "Honda Civic",
            scheduledDateTime: Date().addingTimeInterval(172800),
            status: "In Progress"
        ),
        MaintenanceSchedule(
            ticketNumber: 1003,
            maintenancePersonnel: "Sarah Wilson",
            vehiclePlate: "DEF-456",
            vehicleModel: "Ford F-150",
            scheduledDateTime: Date().addingTimeInterval(259200),
            status: "Scheduled"
        )
    ]
    
    let filters = ["All", "Scheduled", "In Progress"]
    
    var filteredSchedules: [MaintenanceSchedule] {
        let searchResults = maintenanceSchedules.filter { schedule in
            if searchText.isEmpty { return true }
            
            return schedule.maintenancePersonnel.localizedCaseInsensitiveContains(searchText) ||
                   schedule.vehiclePlate.localizedCaseInsensitiveContains(searchText) ||
                   schedule.vehicleModel.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case "In Progress":
            return searchResults.filter { $0.status == "In Progress" }
        case "Scheduled":
            return searchResults.filter { $0.status == "Scheduled" }
        default:
            return searchResults
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
                        if filteredSchedules.isEmpty {
                            Text("No maintenance schedules available")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(filteredSchedules) { schedule in
                                MaintenanceScheduleCard(schedule: schedule)
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
                MaintenanceScheduleFormView(viewModel: viewModel) { newSchedule in
                    maintenanceSchedules.append(newSchedule)
                }
            }
        }
    }
}

struct MaintenanceScheduleCard: View {
    let schedule: MaintenanceSchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(String(format:"#%d", schedule.ticketNumber))
                        .font(.subheadline)
                    
                    Text(schedule.maintenancePersonnel)
                        .font(.headline)
                    
                }
                Spacer()
                Text(schedule.status)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(15)
            }

            HStack {
                Text("Vehicle Details: ")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(schedule.vehicleModel) \n \(schedule.vehiclePlate)")
                    .font(.subheadline)
                    .foregroundColor(.black)
                
            }

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.gray)
                
                Text(schedule.scheduledDateTime.formatted(date: .long, time: .shortened))
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
    @State private var scheduledDateTime = Date()
    @State private var selectedPersonnel = ""
    @State private var selectedVehicle: Vehicle? = nil
    @State private var notes = ""
    @State private var showDatePicker = false
    @State private var showScheduledDatePicker = false
    @State private var showVehicleSelectionSheet = false
    @State private var isDoneEnabled = false
    @State private var showSuccessAlert = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M/yyyy, h:mm a"
        return formatter
    }()
    
    @ObservedObject var viewModel: IFEDataController
    var onScheduleComplete: ((MaintenanceSchedule) -> Void)? = nil

    var vehicleDisplayText: String {
        if let vehicle = selectedVehicle {
            return "\(vehicle.make) \(vehicle.model)"
        }
        return "Select Vehicle"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    VStack {
                        Button(action: { showScheduledDatePicker.toggle() }) {
                            HStack {
                                Text("Scheduled Date & Time")
                                    .foregroundColor(.primary)
                                    .frame(width: 120, alignment: .leading)
                                Spacer()
                                Text(scheduledDateTime.formatted())
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showScheduledDatePicker ? 90 : 0))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if showScheduledDatePicker {
                            DatePicker(
                                "Scheduled Date & Time",
                                selection: $scheduledDateTime,
                                in: Calendar.current.date(byAdding: .day, value: 1, to: Date())!...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .onAppear {
                                scheduledDateTime = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Personnel Selection Card
                    HStack {
                        Text("Maintenance\n Personnel")
                        Spacer()
                        Text(selectedPersonnel.isEmpty ? "Select Personnel" : selectedPersonnel)
                            .foregroundColor(.gray)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                   
                    
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
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    
                    // Notes Card
                    TextField("Maintenance Description", text: $notes)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        
                }
                .padding()
            }
            .sheet(isPresented: $showVehicleSelectionSheet) {
                VehicleSelectionView(viewModel: viewModel, selectedVehicle: $selectedVehicle)
            }
            .background(Color.white)
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
                    .disabled(selectedVehicle == nil)
                    .foregroundColor(selectedVehicle == nil ? Color.gray : Color.primaryGradientStart)
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
        
        // Update vehicle status to under maintenance
        if let vehicle = selectedVehicle {
            // Update the local state immediately after calling the update method
            if let index = viewModel.vehicles.firstIndex(where: { $0.id == vehicle.id }) {
                viewModel.vehicles[index].status = .underMaintenance
            }
            viewModel.updateVehicleStatus(vehicle, with: .underMaintenance)
        }
        
        
        // add new schedule to the maintenance schedules list
        let newSchedule = MaintenanceSchedule(

            
            maintenancePersonnel: "John Smith",
            vehiclePlate: selectedVehicle?.licenseNumber ?? "",
            vehicleModel: selectedVehicle?.model ?? "",
            scheduledDateTime: scheduledDateTime,
            status: "Scheduled"
        )
        
        onScheduleComplete?(newSchedule)

        
        showSuccessAlert = true
    }
}

struct MaintenanceSchedule: Identifiable {
    let id = UUID()

    var ticketNumber: Int = 0
    let maintenancePersonnel: String
    let vehiclePlate: String
    let vehicleModel: String
    let scheduledDateTime: Date
    let status: String
}
