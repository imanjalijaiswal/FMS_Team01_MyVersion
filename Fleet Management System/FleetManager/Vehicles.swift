import SwiftUI
import Foundation

struct VehicleRowView: View {
    let vehicle: Vehicle
    @ObservedObject var viewModel: DriverViewModel
    
    var body: some View {
        NavigationLink(destination: VehicleDetailView(vehicle: vehicle, viewModel: viewModel)) {
            HStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.green)
                    .padding(6)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.model)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(vehicle.activeStatus ? .primary : .red)
                    
                    Text(vehicle.licenseNumber)
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(vehicle.currentCoordinate)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if vehicle.status == .available && vehicle.activeStatus {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 4, height: 4)
                                Text(vehicle.status.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @ObservedObject var viewModel: DriverViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var insuranceExpiry = Date()
    @State private var pucExpiry = Date()
    @State private var rcExpiry = Date()
    @State private var showAlert = false
    @State private var showingDisableAlert = false
    
    var body: some View {
        List {
            Section {
                InfoRow(title: "Model", value: vehicle.model)
                InfoRow(title: "Company Name", value: vehicle.make)
                InfoRow(title: "Year of Manufacture", value: String(vehicle.id))
            } header: {
                Text("Basic Details")
            }
            
            Section {
                InfoRow(title: "VIN", value: vehicle.vinNumber)
                InfoRow(title: "License Plate", value: vehicle.licenseNumber)
                InfoRow(title: "Fuel Type", value: vehicle.fuelType.rawValue)
                InfoRow(title: "Load Capacity", value: "\(vehicle.loadCapacity) tons")
                InfoRow(title: "Current Location", value: vehicle.currentCoordinate)
            } header: {
                Text("Vehicle Specifications")
            }
            
            Section {
                InfoRow(title: "Policy Number", value: vehicle.insurancePolicyNumber)
                if isEditing {
                    DatePicker(
                        "Insurance Expiry Date",
                        selection: $insuranceExpiry,
                        displayedComponents: .date
                    )
                } else {
                    InfoRow(title: "Expiry Date", value: vehicle.insuranceExpiryDate.formatted(date: .long, time: .omitted))
                }
            } header: {
                Text("Insurance Details")
            }
            
            Section {
                InfoRow(title: "PUC Number", value: vehicle.pucCertificateNumber)
                if isEditing {
                    DatePicker(
                        "PUC Expiry Date",
                        selection: $pucExpiry,
                        displayedComponents: .date
                    )
                } else {
                    InfoRow(title: "Expiry Date", value: vehicle.pucExpiryDate.formatted(date: .long, time: .omitted))
                }
            } header: {
                Text("PUC Details")
            }
            
            Section {
                InfoRow(title: "RC Number", value: vehicle.rcNumber)
                if isEditing {
                    DatePicker(
                        "RC Expiry Date",
                        selection: $rcExpiry,
                        displayedComponents: .date
                    )
                } else {
                    InfoRow(title: "Expiry Date", value: vehicle.rcExpiryDate.formatted(date: .long, time: .omitted))
                }
            } header: {
                Text("RC Details")
            }
            
            Section {
                if vehicle.activeStatus {
                    Button(action: {
                        showingDisableAlert = true
                    }) {
                        Text("Disable Vehicle")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Button(action: {
                        viewModel.enableVehicle(vehicle)
                        dismiss()
                    }) {
                        Text("Enable Vehicle")
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .navigationTitle("Vehicle Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        showAlert = true
                    }
                    isEditing.toggle()
                }
            }
        }
        .alert("Disable Vehicle", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                viewModel.removeVehicle(vehicle)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to disable this vehicle? This action cannot be undone.")
        }
        .onAppear {
            insuranceExpiry = vehicle.insuranceExpiryDate
            pucExpiry = vehicle.pucExpiryDate
            rcExpiry = vehicle.rcExpiryDate
        }
    }
}

struct VehiclesView: View {
    @StateObject private var viewModel = DriverViewModel.shared
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    let filters = ["All", VehicleStatus.available.rawValue, VehicleStatus.assigned.rawValue, VehicleStatus.inactive.rawValue]
    @State private var showingAddVehicle = false
    
    var filteredVehicles: [Vehicle] {
        let searchResults = viewModel.vehicles.filter { vehicle in
            searchText.isEmpty ||
            vehicle.licenseNumber.localizedCaseInsensitiveContains(searchText) ||
            vehicle.model.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case VehicleStatus.available.rawValue:
            return searchResults.filter { $0.status == .available && $0.activeStatus }
        case VehicleStatus.assigned.rawValue:
            return searchResults.filter { $0.status == .assigned }
        case VehicleStatus.inactive.rawValue:
            return searchResults.filter { !$0.activeStatus }
        default:
            return searchResults.filter { $0.activeStatus }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SearchBar(text: $searchText)
                .padding(.top, 8)
            
            FilterSection(
                title: "",
                filters: filters,
                selectedFilter: $selectedFilter
            )
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(filteredVehicles) { vehicle in
                        VehicleRowView(vehicle: vehicle, viewModel: viewModel)
                        if vehicle != filteredVehicles.last {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Vehicles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddVehicle = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            VehicleDetailsView(viewModel: viewModel)
        }
        .onAppear {
        }
    }
}

struct VehicleDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DriverViewModel
    
    @State private var model = ""
    @State private var make = ""
    @State private var vinNumber = ""
    @State private var licenseNumber = ""
    @State private var selectedFuelType = FuelType.diesel
    @State private var loadCapacity = ""
    @State private var insurancePolicyNumber = ""
    @State private var insuranceExpiryDate = Date()
    @State private var pucCertificateNumber = ""
    @State private var pucExpiryDate = Date()
    @State private var rcNumber = ""
    @State private var rcExpiryDate = Date()
    @State private var currentCoordinate = ""
    @State private var selectedLocation: String? = nil
    
    var isFormValid: Bool {
        !model.isEmpty &&
        !make.isEmpty &&
        !vinNumber.isEmpty &&
        !licenseNumber.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Required Details") {
                    TextField("Model", text: $model)
                        .textContentType(.none)
                    TextField("Company Name", text: $make)
                        .textContentType(.organizationName)
                    TextField("VIN", text: $vinNumber)
                        .textContentType(.none)
                        .textInputAutocapitalization(.characters)
                    TextField("License Plate Number", text: $licenseNumber)
                        .textContentType(.none)
                        .textInputAutocapitalization(.characters)
                }
                
                Section("Additional Details") {
                    Picker("Fuel Type", selection: $selectedFuelType) {
                        ForEach([FuelType.diesel, .petrol, .electric, .hybrid], id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    TextField("Load Capacity (tons)", text: $loadCapacity)
                        .keyboardType(.decimalPad)
                    LocationSearchBar(
                        text: $currentCoordinate,
                        placeholder: "Current Location",
                        selectedLocation: $selectedLocation
                    )
                }
                
                Section("Insurance Details") {
                    TextField("Insurance Policy Number", text: $insurancePolicyNumber)
                    DatePicker(
                        "Insurance Expiry Date",
                        selection: $insuranceExpiryDate,
                        displayedComponents: [.date]
                    )
                }
                
                Section("PUC Details") {
                    TextField("PUC Certificate Number", text: $pucCertificateNumber)
                    DatePicker(
                        "PUC Expiry Date",
                        selection: $pucExpiryDate,
                        displayedComponents: [.date]
                    )
                }
                
                Section("RC Details") {
                    TextField("RC Number", text: $rcNumber)
                    DatePicker(
                        "RC Expiry Date",
                        selection: $rcExpiryDate,
                        displayedComponents: [.date]
                    )
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }.foregroundColor(Color.primaryGradientEnd)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let newVehicle = Vehicle(
                            id: viewModel.vehicles.count + 1,
                            make: make,
                            model: model,
                            vinNumber: vinNumber,
                            licenseNumber: licenseNumber,
                            fuelType: selectedFuelType,
                            loadCapacity: Float(loadCapacity) ?? 0,
                            insurancePolicyNumber: insurancePolicyNumber,
                            insuranceExpiryDate: insuranceExpiryDate,
                            pucCertificateNumber: pucCertificateNumber,
                            pucExpiryDate: pucExpiryDate,
                            rcNumber: rcNumber,
                            rcExpiryDate: rcExpiryDate,
                            currentCoordinate: currentCoordinate.isEmpty ? "Not Available" : currentCoordinate,
                            status: .available,
                            activeStatus: true
                        )
                        
                        viewModel.addVehicle(newVehicle)
                        dismiss()
                    }.foregroundColor(Color.primaryGradientEnd)
                }
            }
        }
    }
}
