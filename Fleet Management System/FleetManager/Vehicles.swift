import SwiftUI
import Foundation

struct Vehicle: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let model: String
    let companyName: String
    let yearOfManufacture: Int
    let vin: String
    let plateNumber: String
    let fuelType: String?
    let loadCapacity: String
    let insuranceNumber: String?
    let insuranceExpiry: Date?
    let pucNumber: String?
    let pucExpiry: Date?
    let rcNumber: String?
    let rcExpiry: Date?
    let currentLocation: String
    let isAvailable: Bool
    let isActive: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Vehicle, rhs: Vehicle) -> Bool {
        lhs.id == rhs.id
    }
}

class VehicleViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }
    
    func removeVehicle(_ vehicle: Vehicle) {
        let inactiveVehicle = Vehicle(
            number: vehicle.number,
            model: vehicle.model,
            companyName: vehicle.companyName,
            yearOfManufacture: vehicle.yearOfManufacture,
            vin: vehicle.vin,
            plateNumber: vehicle.plateNumber,
            fuelType: vehicle.fuelType,
            loadCapacity: vehicle.loadCapacity,
            insuranceNumber: vehicle.insuranceNumber,
            insuranceExpiry: vehicle.insuranceExpiry,
            pucNumber: vehicle.pucNumber,
            pucExpiry: vehicle.pucExpiry,
            rcNumber: vehicle.rcNumber,
            rcExpiry: vehicle.rcExpiry,
            currentLocation: vehicle.currentLocation,
            isAvailable: false,
            isActive: false
        )
        
        vehicles.removeAll { $0.id == vehicle.id }
        vehicles.append(inactiveVehicle)
    }
    
    func enableVehicle(_ vehicle: Vehicle) {
        let activeVehicle = Vehicle(
            number: vehicle.number,
            model: vehicle.model,
            companyName: vehicle.companyName,
            yearOfManufacture: vehicle.yearOfManufacture,
            vin: vehicle.vin,
            plateNumber: vehicle.plateNumber,
            fuelType: vehicle.fuelType,
            loadCapacity: vehicle.loadCapacity,
            insuranceNumber: vehicle.insuranceNumber,
            insuranceExpiry: vehicle.insuranceExpiry,
            pucNumber: vehicle.pucNumber,
            pucExpiry: vehicle.pucExpiry,
            rcNumber: vehicle.rcNumber,
            rcExpiry: vehicle.rcExpiry,
            currentLocation: vehicle.currentLocation,
            isAvailable: true,
            isActive: true
        )
        
        vehicles.removeAll { $0.id == vehicle.id }
        vehicles.append(activeVehicle)
    }
}

struct VehicleRowView: View {
    let vehicle: Vehicle
    @ObservedObject var viewModel: VehicleViewModel
    
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
                        .foregroundColor(vehicle.isActive ? .primary : .red)
                    
                    Text(vehicle.plateNumber)
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(vehicle.currentLocation)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if vehicle.isAvailable && vehicle.isActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 4, height: 4)
                                Text("Available")
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
    @ObservedObject var viewModel: VehicleViewModel
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
                InfoRow(title: "Company Name", value: vehicle.companyName)
                InfoRow(title: "Year of Manufacture", value: String(vehicle.yearOfManufacture))
            } header: {
                Text("Basic Details")
            }
            
            Section {
                InfoRow(title: "VIN", value: vehicle.vin)
                InfoRow(title: "License Plate", value: vehicle.plateNumber)
                if let fuelType = vehicle.fuelType {
                    InfoRow(title: "Fuel Type", value: fuelType)
                }
                InfoRow(title: "Load Capacity", value: vehicle.loadCapacity)
                InfoRow(title: "Current Location", value: vehicle.currentLocation)
            } header: {
                Text("Vehicle Specifications")
            }
            
            Section {
                if let insuranceNumber = vehicle.insuranceNumber {
                    InfoRow(title: "Policy Number", value: insuranceNumber)
                }
                if isEditing {
                    DatePicker(
                        "Insurance Expiry Date",
                        selection: $insuranceExpiry,
                        displayedComponents: .date
                    )
                } else if let insuranceExpiry = vehicle.insuranceExpiry {
                    InfoRow(title: "Expiry Date", value: insuranceExpiry.formatted(date: .long, time: .omitted))
                }
            } header: {
                Text("Insurance Details")
            }
            
            Section {
                if let pucNumber = vehicle.pucNumber {
                    InfoRow(title: "PUC Number", value: pucNumber)
                }
                if isEditing {
                    DatePicker(
                        "PUC Expiry Date",
                        selection: $pucExpiry,
                        displayedComponents: .date
                    )
                } else if let pucExpiry = vehicle.pucExpiry {
                    InfoRow(title: "Expiry Date", value: pucExpiry.formatted(date: .long, time: .omitted))
                }
            } header: {
                Text("PUC Details")
            }
            
            Section {
                if let rcNumber = vehicle.rcNumber {
                    InfoRow(title: "RC Number", value: rcNumber)
                }
                if isEditing {
                    DatePicker(
                        "RC Expiry Date",
                        selection: $rcExpiry,
                        displayedComponents: .date
                    )
                } else if let rcExpiry = vehicle.rcExpiry {
                    InfoRow(title: "Expiry Date", value: rcExpiry.formatted(date: .long, time: .omitted))
                }
            } header: {
                Text("RC Details")
            }
            
            Section {
                if vehicle.isActive {
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
            if let date = vehicle.insuranceExpiry {
                insuranceExpiry = date
            }
            if let date = vehicle.pucExpiry {
                pucExpiry = date
            }
            if let date = vehicle.rcExpiry {
                rcExpiry = date
            }
        }
    }
}

struct VehiclesView: View {
    @StateObject private var viewModel = VehicleViewModel()
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    let filters = ["All", "Available", "On Trip", "Inactive"]
    @State private var showingAddVehicle = false
    
    var filteredVehicles: [Vehicle] {
        let searchResults = viewModel.vehicles.filter { vehicle in
            searchText.isEmpty ||
            vehicle.plateNumber.localizedCaseInsensitiveContains(searchText) ||
            vehicle.model.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case "Available":
            return searchResults.filter { $0.isAvailable && $0.isActive }
        case "On Trip":
            return searchResults.filter { !$0.isAvailable && $0.isActive }
        case "Inactive":
            return searchResults.filter { !$0.isActive }
        default:
            return searchResults.filter { $0.isActive }
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
            if viewModel.vehicles.isEmpty {
                viewModel.vehicles = [
                    Vehicle(number: "TN01AB1234", model: "Tata Prima", companyName: "Tata Motors", yearOfManufacture: 2022, vin: "1HGCM82633A123456", plateNumber: "TN01AB1234", fuelType: "Diesel", loadCapacity: "25 tons", insuranceNumber: "INS123456", insuranceExpiry: Date(), pucNumber: "PUC123456", pucExpiry: Date(), rcNumber: "RC123456", rcExpiry: Date(), currentLocation: "Bangalore", isAvailable: true, isActive: true),
                    Vehicle(number: "KA02CD5678", model: "BharatBenz 3723R", companyName: "BharatBenz", yearOfManufacture: 2021, vin: "2FMZA52233B234567", plateNumber: "KA02CD5678", fuelType: "Diesel", loadCapacity: "37 tons", insuranceNumber: "INS234567", insuranceExpiry: Date(), pucNumber: "PUC234567", pucExpiry: Date(), rcNumber: "RC234567", rcExpiry: Date(), currentLocation: "Chennai", isAvailable: true, isActive: true),
                    Vehicle(number: "MH03EF9012", model: "Ashok Leyland 2820", companyName: "Ashok Leyland", yearOfManufacture: 2023, vin: "3VWFA21233M345678", plateNumber: "MH03EF9012", fuelType: "Diesel", loadCapacity: "28 tons", insuranceNumber: "INS345678", insuranceExpiry: Date(), pucNumber: "PUC345678", pucExpiry: Date(), rcNumber: "RC345678", rcExpiry: Date(), currentLocation: "Mumbai", isAvailable: true, isActive: true),
                    Vehicle(number: "DL04GH3456", model: "Eicher Pro 6037", companyName: "Eicher", yearOfManufacture: 2022, vin: "4VWFA21233M456789", plateNumber: "DL04GH3456", fuelType: "Diesel", loadCapacity: "35 tons", insuranceNumber: "INS456789", insuranceExpiry: Date(), pucNumber: "PUC456789", pucExpiry: Date(), rcNumber: "RC456789", rcExpiry: Date(), currentLocation: "Delhi", isAvailable: true, isActive: true),
                    Vehicle(number: "TN05IJ6789", model: "Tata Signa 2825.K", companyName: "Tata Motors", yearOfManufacture: 2022, vin: "5VWFA21233M567890", plateNumber: "TN05IJ6789", fuelType: "Diesel", loadCapacity: "30 tons", insuranceNumber: "INS567890", insuranceExpiry: Date(), pucNumber: "PUC567890", pucExpiry: Date(), rcNumber: "RC567890", rcExpiry: Date(), currentLocation: "Coimbatore", isAvailable: true, isActive: true),
                    Vehicle(number: "KA06KL0123", model: "BharatBenz 2823R", companyName: "BharatBenz", yearOfManufacture: 2021, vin: "6FMZA52233B678901", plateNumber: "KA06KL0123", fuelType: "Diesel", loadCapacity: "38 tons", insuranceNumber: "INS678901", insuranceExpiry: Date(), pucNumber: "PUC678901", pucExpiry: Date(), rcNumber: "RC678901", rcExpiry: Date(), currentLocation: "Mysore", isAvailable: true, isActive: true),
                    Vehicle(number: "MH07MN4567", model: "Ashok Leyland 3116", companyName: "Ashok Leyland", yearOfManufacture: 2023, vin: "7VWFA21233M789012", plateNumber: "MH07MN4567", fuelType: "Diesel", loadCapacity: "31 tons", insuranceNumber: "INS789012", insuranceExpiry: Date(), pucNumber: "PUC789012", pucExpiry: Date(), rcNumber: "RC789012", rcExpiry: Date(), currentLocation: "Pune", isAvailable: true, isActive: true),
                    Vehicle(number: "DL08PQ7890", model: "Eicher Pro 6049", companyName: "Eicher", yearOfManufacture: 2022, vin: "8VWFA21233M890123", plateNumber: "DL08PQ7890", fuelType: "Diesel", loadCapacity: "40 tons", insuranceNumber: "INS890123", insuranceExpiry: Date(), pucNumber: "PUC890123", pucExpiry: Date(), rcNumber: "RC890123", rcExpiry: Date(), currentLocation: "Gurgaon", isAvailable: true, isActive: true),
                    Vehicle(number: "TN09RS1234", model: "Tata Prima 3128.K", companyName: "Tata Motors", yearOfManufacture: 2023, vin: "9VWFA21233M901234", plateNumber: "TN09RS1234", fuelType: "Diesel", loadCapacity: "32 tons", insuranceNumber: "INS901234", insuranceExpiry: Date(), pucNumber: "PUC901234", pucExpiry: Date(), rcNumber: "RC901234", rcExpiry: Date(), currentLocation: "Salem", isAvailable: true, isActive: true),
                    Vehicle(number: "KA10TU5678", model: "BharatBenz 4023T", companyName: "BharatBenz", yearOfManufacture: 2022, vin: "0FMZA52233B012345", plateNumber: "KA10TU5678", fuelType: "Diesel", loadCapacity: "40 tons", insuranceNumber: "INS012345", insuranceExpiry: Date(), pucNumber: "PUC012345", pucExpiry: Date(), rcNumber: "RC012345", rcExpiry: Date(), currentLocation: "Bangalore", isAvailable: true, isActive: true)
                ]
            }
        }
    }
}

struct VehicleDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: VehicleViewModel
    
    @State private var model = ""
    @State private var companyName = ""
    @State private var yearOfManufacture = ""
    @State private var vin = ""
    @State private var plateNumber = ""
    @State private var fuelType = ""
    @State private var loadCapacity = ""
    @State private var insuranceNumber = ""
    @State private var insuranceExpiry = Date()
    @State private var pucNumber = ""
    @State private var pucExpiry = Date()
    @State private var rcNumber = ""
    @State private var rcExpiry = Date()
    @State private var currentLocation = ""
    @State private var selectedLocation: String? = nil
    
    var isFormValid: Bool {
        !model.isEmpty &&
        !companyName.isEmpty &&
        !yearOfManufacture.isEmpty &&
        !vin.isEmpty &&
        !plateNumber.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Required Details") {
                    TextField("Model", text: $model)
                        .textContentType(.none)
                    TextField("Company Name", text: $companyName)
                        .textContentType(.organizationName)
                    TextField("Year of Manufacture", text: $yearOfManufacture)
                        .keyboardType(.numberPad)
                    TextField("VIN", text: $vin)
                        .textContentType(.none)
                        .textInputAutocapitalization(.characters)
                    TextField("License Plate Number", text: $plateNumber)
                        .textContentType(.none)
                        .textInputAutocapitalization(.characters)
                }
                
                Section("Additional Details") {
                    TextField("Fuel Type", text: $fuelType)
                    TextField("Load Capacity", text: $loadCapacity)
                    LocationSearchBar(
                        text: $currentLocation,
                        placeholder: "Current Location",
                        selectedLocation: $selectedLocation
                    )
                }
                
                Section("Insurance Details") {
                    TextField("Insurance Policy Number", text: $insuranceNumber)
                    DatePicker(
                        "Insurance Expiry Date",
                        selection: $insuranceExpiry,
                        displayedComponents: [.date]
                    )
                }
                
                Section("PUC Details") {
                    TextField("PUC Certificate Number", text: $pucNumber)
                    DatePicker(
                        "PUC Expiry Date",
                        selection: $pucExpiry,
                        displayedComponents: [.date]
                    )
                }
                
                Section("RC Details") {
                    TextField("RC Number", text: $rcNumber)
                    DatePicker(
                        "RC Expiry Date",
                        selection: $rcExpiry,
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
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let newVehicle = Vehicle(
                            number: plateNumber,
                            model: model,
                            companyName: companyName,
                            yearOfManufacture: Int(yearOfManufacture) ?? 0,
                            vin: vin,
                            plateNumber: plateNumber,
                            fuelType: fuelType.isEmpty ? nil : fuelType,
                            loadCapacity: loadCapacity,
                            insuranceNumber: insuranceNumber.isEmpty ? nil : insuranceNumber,
                            insuranceExpiry: insuranceNumber.isEmpty ? nil : insuranceExpiry,
                            pucNumber: pucNumber.isEmpty ? nil : pucNumber,
                            pucExpiry: pucNumber.isEmpty ? nil : pucExpiry,
                            rcNumber: rcNumber.isEmpty ? nil : rcNumber,
                            rcExpiry: rcNumber.isEmpty ? nil : rcExpiry,
                            currentLocation: currentLocation.isEmpty ? "Not Available" : currentLocation,
                            isAvailable: true,
                            isActive: true
                        )
                        
                        viewModel.addVehicle(newVehicle)
                        dismiss()
                    }
                }
            }
        }
    }
}
