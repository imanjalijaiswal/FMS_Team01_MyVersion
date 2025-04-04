//
//  ExampleView.swift
//  SomeProject
//
//  Created by You on 3/20/25.
//

import SwiftUI
import Foundation

struct VehicleRowView: View {
    var vehicle: Vehicle
    @ObservedObject var viewModel: IFEDataController
    @State private var address: String = "Fetching address..."
    
    var body: some View {
        NavigationLink(destination: VehicleDetailView(vehicle: vehicle, viewModel: viewModel)) {
            HStack(spacing: 12) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 25))
                    .foregroundColor(Color.setForegroundColor(vehicle: vehicle))
                    .padding(6)
                    .background(Color.setForegroundColor(vehicle: vehicle).opacity(0.1))
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
                            
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        if vehicle.status == .available && vehicle.activeStatus {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.setForegroundColor(vehicle: vehicle))
                                    .frame(width: 4, height: 4)
                                Text(vehicle.status.rawValue)
                                    .font(.caption)
                                    .foregroundColor(Color.setForegroundColor(vehicle: vehicle))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.setForegroundColor(vehicle: vehicle).opacity(0.1))
                            .cornerRadius(8)
                        }
                        else if vehicle.status == .assigned && vehicle.activeStatus {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.setForegroundColor(vehicle: vehicle))
                                    .frame(width: 4, height: 4)
                                Text(vehicle.status.rawValue)
                                    .font(.caption)
                                    .foregroundColor(Color.setForegroundColor(vehicle: vehicle))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.setForegroundColor(vehicle: vehicle).opacity(0.1))
                            .cornerRadius(8)
                        }
                        else if vehicle.status == .underMaintenance && vehicle.activeStatus {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.setForegroundColor(vehicle: vehicle))
                                    .frame(width: 4, height: 4)
                                Text("Maintenance")
                                    .font(.caption)
                                    .foregroundColor(Color.setForegroundColor(vehicle: vehicle))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.setForegroundColor(vehicle: vehicle).opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .onAppear {
                getAddress(from: vehicle.currentCoordinate) { result in
                    if let result = result {
                        address = result
                    } else {
                        address = "Address not found"
                    }
                }
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
    @ObservedObject var viewModel: IFEDataController
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    @State private var insuranceExpiry = Date()
    @State private var pucExpiry = Date()
    @State private var rcExpiry = Date()
    @State private var showAlert = false
    @State private var showingDisableAlert = false
    @State private var address: String = "Fetching address..."
    @State private var insurancePolicyNumber = ""
    @State private var insuranceError: String? = nil
    
    var body: some View {
        List {
            Section {
                InfoRow(title: "Vehicle ID", value: String(vehicle.id))
                InfoRow(title: "Model", value: vehicle.model)
                InfoRow(title: "Company Name", value: vehicle.make)
            } header: {
                Text("Basic Details")
            }
            
            Section {
                InfoRow(title: "VIN", value: vehicle.vinNumber)
                InfoRow(title: "License Plate", value: vehicle.licenseNumber)
                InfoRow(title: "Fuel Type", value: vehicle.fuelType.rawValue)
                InfoRow(title: "Load Capacity", value: "\(vehicle.loadCapacity) tons")
                InfoRow(title: "Current Location", value: address)
            } header: {
                Text("Vehicle Specifications")
            }
            
            Section {
                InfoRow(title: "Policy Number", value: vehicle.insurancePolicyNumber)
                if isEditing {
                    DatePicker("Insurance Expiry Date", selection: $insuranceExpiry, displayedComponents: .date)
                } else {
                    InfoRow(title: "Expiry Date", value: vehicle.insuranceExpiryDate.formatted(date: .long, time: .omitted))
                }
            } header: {
                Text("Insurance Details")
            }
            
            Section {
                InfoRow(title: "PUC Number", value: vehicle.pucCertificateNumber)
                if isEditing {
                    DatePicker("PUC Expiry Date", selection: $pucExpiry, displayedComponents: .date)
                } else {
                    InfoRow(title: "Expiry Date", value: vehicle.pucExpiryDate.formatted(date: .long, time: .omitted))
                }
            } header: {
                Text("PUC Details")
            }
            
            Section {
                InfoRow(title: "RC Number", value: vehicle.rcNumber)
                if isEditing {
                    DatePicker("RC Expiry Date", selection: $rcExpiry, displayedComponents: .date)
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
                        Text("Make Inactive")
                            .foregroundColor((vehicle.status == .assigned || vehicle.status == .underMaintenance) ? .gray : .red)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .disabled(vehicle.status == .assigned || vehicle.status == .underMaintenance)
                } else {
                    Button(action: {
                        viewModel.enableVehicle(vehicle)
                        dismiss()
                    }) {
                        Text("Make Active")
                            .foregroundColor(.primaryGradientStart)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .navigationTitle("Vehicle Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action:  {
                    if isEditing {
                        var newVehicle = vehicle
                        newVehicle.pucExpiryDate = pucExpiry
                        newVehicle.insuranceExpiryDate = insuranceExpiry
                        newVehicle.rcExpiryDate = rcExpiry
                        viewModel.updateVehicleExpiryDates(vehicle, with: newVehicle)
                        showAlert = true
                    }
                    isEditing.toggle()
                })
                {
                    Text(isEditing ? "Save" : "Edit")
                        .foregroundColor(.primaryGradientStart)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss() // Dismiss the current view
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color.primaryGradientStart) // Apply custom color
                        Text("Back")
                            .foregroundColor(Color.primaryGradientStart) // Apply custom color
                    }
                }
            }
        }
        .alert("Make Vehicle Inactive", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Inactive", role: .destructive) {
                viewModel.removeVehicle(vehicle)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to make this vehicle Inactive ?")
        }
        .onAppear {
            insuranceExpiry = vehicle.insuranceExpiryDate
            pucExpiry = vehicle.pucExpiryDate
            rcExpiry = vehicle.rcExpiryDate
            
            getAddress(from: vehicle.currentCoordinate) { result in
                if let result = result {
                    address = result
                } else {
                    address = "Address not found"
                }
            }
        }
    }
}

struct VehiclesView: View {
    @StateObject var viewModel = IFEDataController.shared
    @State private var searchText = ""
    @State private var selectedFilter = ""
    @State private var showingAddVehicle = false
    @State private var isRefreshing = false
    @State private var viewRefreshTrigger = UUID()
    
    private var availableCount: Int {
        viewModel.vehicles.filter { $0.status == .available && $0.activeStatus }.count
    }
    
    private var assignedCount: Int {
        viewModel.vehicles.filter { $0.status == .assigned }.count
    }
    
    private var inactiveCount: Int {
        viewModel.vehicles.filter { !$0.activeStatus }.count
    }
    
    private var underMaintenanceCount: Int {
        viewModel.vehicles.filter { $0.status == .underMaintenance && $0.activeStatus }.count
    }
    
    private var allCount: Int {
        viewModel.vehicles.count
    }
    
    private var filtersWithCount: [String] {
        return [
            "All (\(allCount))",
            "Available (\(availableCount))",
            "Assigned (\(assignedCount))",
            "Inactive (\(inactiveCount))",
            "\(VehicleStatus.underMaintenance.rawValue) (\(underMaintenanceCount))"
        ]
    }
    
    var filteredVehicles: [Vehicle] {
        let searchResults = viewModel.vehicles.filter { vehicle in
            searchText.isEmpty ||
            vehicle.model.localizedCaseInsensitiveContains(searchText) ||
            vehicle.licenseNumber.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case _ where selectedFilter.contains("Available"):
            return searchResults.filter { $0.status == .available && $0.activeStatus }
        case _ where selectedFilter.contains("Assigned"):
            return searchResults.filter { $0.status == .assigned }
        case _ where selectedFilter.contains("Inactive"):
            return searchResults.filter { !$0.activeStatus }
        case _ where selectedFilter.contains(VehicleStatus.underMaintenance.rawValue):
            return searchResults.filter { $0.status == .underMaintenance && $0.activeStatus }
        default:
            let availableVehicles = searchResults.filter{ $0.status == .available && $0.activeStatus }
            let assignedVehicles = searchResults.filter { $0.status == .assigned }
            let inactiveVehicles = searchResults.filter { !$0.activeStatus }
            let underMaintenanceVehicles = searchResults.filter { $0.status == .underMaintenance && $0.activeStatus }
            
            var results: [Vehicle] = []
            
            results.append(contentsOf: availableVehicles)
            results.append(contentsOf: assignedVehicles)
            results.append(contentsOf: underMaintenanceVehicles)
            results.append(contentsOf: inactiveVehicles)
            
            return results
        }
    }
    
    func refreshData() {
        self.isRefreshing = true
        
        Task {
            await viewModel.loadVehicles()
            
            DispatchQueue.main.async {
                self.isRefreshing = false
                self.viewRefreshTrigger = UUID() // Force view update
            }
        }
    }
    
    // Skeleton filter view
    var skeletonFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 32)
                        .frame(width: 120)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }
    
    // Skeleton vehicle row view
    var skeletonVehicleView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 150, height: 16)
                        .cornerRadius(8)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 100, height: 12)
                        .cornerRadius(6)
                    
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 150, height: 12)
                            .cornerRadius(6)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 80, height: 20)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 8, height: 16)
                    .cornerRadius(4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SearchBar(text: $searchText)
                .padding(.top, 8)
            
            if isRefreshing {
                // Skeleton filters during loading
                skeletonFilterView
            } else {
                // Real filters when not loading
                FilterSection(
                    title: "",
                    filters: filtersWithCount,
                    selectedFilter: $selectedFilter
                )
                .id(viewRefreshTrigger)
            }
            
            ScrollView {
                PullToRefresh(coordinateSpaceName: "vehiclesPullToRefresh", onRefresh: refreshData, isRefreshing: isRefreshing)
                
                if isRefreshing {
                    // Skeleton View for vehicles
                    VStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { _ in
                            skeletonVehicleView
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                } else {
                    // Regular content view
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
                    .id(viewRefreshTrigger)
                }
            }
            .coordinateSpace(name: "vehiclesPullToRefresh")
        }
        .id(viewRefreshTrigger)
        .navigationTitle("Vehicles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddVehicle = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.primaryGradientEnd)
                }
            }
        }
        .sheet(isPresented: $showingAddVehicle) {
            VehicleDetailsView(viewModel: viewModel)
        }
        .onAppear {
            if selectedFilter.isEmpty {
                selectedFilter = filtersWithCount[0]
            }
        }
    }
}

struct VehicleDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IFEDataController
    
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
    @State private var selectedAdress: String? = nil
    @State private var licenseError: String? = nil
    @State private var pucError: String? = nil
    @State private var rcError: String? = nil
    @State private var insuranceError: String? = nil
    @State private var loadCapacityError: String? = nil
    @State private var duplicateLicenseError: String? = nil
    @State private var duplicateRCError: String? = nil
    @State private var duplicatePUCError: String? = nil
    @State private var vinError: String? = nil
    @State private var duplicateVINError: String? = nil
    @State private var duplicateInsuranceError: String? = nil
    
    
    func isValidLicensePlate(_ license: String) -> Bool {
        let pattern = "^[A-Z]{2}[0-9]{2}[A-Z]{2}[0-9]{4}$"
        let licensePredicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return licensePredicate.evaluate(with: license.replacingOccurrences(of: "-", with: ""))
    }
    
    func isValidInsurancePolicy(_ policy: String) -> Bool {
        // Format: Allow alphanumeric characters, length 10-17
        let pattern = "^[A-Z0-9]{10,17}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: policy.uppercased())
    }
    
    func isValidRCNumber(_ number: String) -> Bool {
        let pattern = "^[A-Z]{2}[0-9]{2}[A-Z0-9]{11}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: number.replacingOccurrences(of: "-", with: "").uppercased())
    }
    
    func isValidPUCNumber(_ number: String) -> Bool {
        // Format: AAA followed by 7-14 numbers (total length 10-17)
        let pattern = "^[A-Z]{3}[0-9]{7,14}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: number.uppercased())
    }
    
    func isValidLoadCapacity(_ value: String) -> Bool {
        let numberSet = CharacterSet(charactersIn: "0123456789.")
        let stringSet = CharacterSet(charactersIn: value)
        return stringSet.isSubset(of: numberSet)
    }
    
    func isValidVIN(_ vin: String) -> Bool {
        let pattern = "^[A-HJ-NPR-Z0-9]{17}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: vin.uppercased())
    }
    
    func isLicenseNumberUnique(_ license: String) -> Bool {
        return !viewModel.vehicles.contains { $0.licenseNumber.uppercased() == license.uppercased() }
    }
    
    func isRCNumberUnique(_ number: String) -> Bool {
        return !viewModel.vehicles.contains { $0.rcNumber.uppercased() == number.uppercased() }
    }
    
    func isPUCNumberUnique(_ number: String) -> Bool {
        return !viewModel.vehicles.contains { $0.pucCertificateNumber.uppercased() == number.uppercased() }
    }
    
    func isVINUnique(_ vin: String) -> Bool {
        return !viewModel.vehicles.contains { $0.vinNumber.uppercased() == vin.uppercased() }
    }
    
    func isInsurancePolicyUnique(_ policy: String) -> Bool {
        return !viewModel.vehicles.contains { $0.insurancePolicyNumber.uppercased() == policy.uppercased() }
    }
    
    var isFormValid: Bool {
        !model.isEmpty &&
        !make.isEmpty &&
        !vinNumber.isEmpty &&
        !licenseNumber.isEmpty &&
        !loadCapacity.isEmpty &&
        !insurancePolicyNumber.isEmpty &&
        !pucCertificateNumber.isEmpty &&
        !rcNumber.isEmpty &&
        selectedLocation != nil &&
        licenseError == nil &&
        pucError == nil &&
        rcError == nil &&
        insuranceError == nil &&
        loadCapacityError == nil &&
        duplicateLicenseError == nil &&
        duplicateRCError == nil &&
        duplicatePUCError == nil &&
        duplicateVINError == nil &&
        duplicateInsuranceError == nil &&
        vinError == nil &&
        isValidVIN(vinNumber) &&
        isValidLoadCapacity(loadCapacity) &&
        Float(loadCapacity) != nil &&
        isLicenseNumberUnique(licenseNumber) &&
        isRCNumberUnique(rcNumber) &&
        isPUCNumberUnique(pucCertificateNumber) &&
        isVINUnique(vinNumber) &&
        isInsurancePolicyUnique(insurancePolicyNumber)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Required Details") {
                    TextField("Model", text: $model)
                        .textContentType(.none)
                    
                    Picker("Company Name", selection: $make) {
                        ForEach(viewModel.vehicleCompanies, id: \.self) { company in
                            Text(company).tag(company)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("VIN", text: $vinNumber)
                            .textContentType(.none)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: vinNumber, initial: false) { _, newValue in
                                if !newValue.isEmpty {
                                    if !isValidVIN(newValue) {
                                        vinError = "Please enter a valid 17-character VIN (e.g., MB1HT4B1XP1234567)"
                                        duplicateVINError = nil
                                    } else if !isVINUnique(newValue) {
                                        duplicateVINError = "This VIN is already registered"
                                        vinError = nil
                                    } else {
                                        vinError = nil
                                        duplicateVINError = nil
                                    }
                                } else {
                                    vinError = nil
                                    duplicateVINError = nil
                                }
                            }
                        
                        if let error = vinError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        } else if let error = duplicateVINError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("License Plate Number", text: $licenseNumber)
                            .textContentType(.none)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: licenseNumber, initial: false) { _, newValue in
                                if !newValue.isEmpty {
                                    if !isValidLicensePlate(newValue) {
                                        licenseError = "Please enter a valid Indian license plate (e.g., MH01AB1234)"
                                        duplicateLicenseError = nil
                                    } else if !isLicenseNumberUnique(newValue) {
                                        duplicateLicenseError = "This license plate is already registered"
                                        licenseError = nil
                                    } else {
                                        licenseError = nil
                                        duplicateLicenseError = nil
                                    }
                                } else {
                                    licenseError = nil
                                    duplicateLicenseError = nil
                                }
                            }
                        
                        if let error = licenseError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        } else if let error = duplicateLicenseError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                }
                
                Section("Additional Details") {
                    Picker("Fuel Type", selection: $selectedFuelType) {
                        ForEach([FuelType.diesel, .petrol, .electric, .hybrid], id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Load Capacity (tons)", text: $loadCapacity)
                            .keyboardType(.decimalPad)
                            .onChange(of: loadCapacity, initial: false) { _, newValue in
                                if !newValue.isEmpty {
                                    if !isValidLoadCapacity(newValue) {
                                        loadCapacityError = "Please enter numbers only"
                                    } else if Float(newValue) == nil {
                                        loadCapacityError = "Please enter a valid number"
                                    } else {
                                        loadCapacityError = nil
                                    }
                                } else {
                                    loadCapacityError = nil
                                }
                            }
                        
                        if let error = loadCapacityError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    
                    LocationSearchBar(
                        text: $currentCoordinate,
                        placeholder: "Current Location",
                        selectedLocation: $selectedLocation,
                        selectedCoordinates: $selectedAdress
                    )
                    
                }
                
                Section("Insurance Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Insurance Policy Number", text: $insurancePolicyNumber)
                            .textContentType(.none)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: insurancePolicyNumber, initial: false) { _, newValue in
                                if !newValue.isEmpty {
                                    if !isValidInsurancePolicy(newValue) {
                                        insuranceError = "Please enter a valid insurance number (10-17 alphanumeric characters)"
                                        duplicateInsuranceError = nil
                                    } else if !isInsurancePolicyUnique(newValue) {
                                        duplicateInsuranceError = "This insurance policy number already exists"
                                        insuranceError = nil
                                    } else {
                                        insuranceError = nil
                                        duplicateInsuranceError = nil
                                    }
                                } else {
                                    insuranceError = nil
                                    duplicateInsuranceError = nil
                                }
                            }
                        
                        if let error = insuranceError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        } else if let error = duplicateInsuranceError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    DatePicker(
                        "Insurance Expiry Date",
                        selection: $insuranceExpiryDate,
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: [.date]
                    )
                }
                
                Section("PUC Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("PUC Certificate Number", text: $pucCertificateNumber)
                            .textContentType(.none)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: pucCertificateNumber, initial: false) { _, newValue in
                                if !newValue.isEmpty {
                                    if !isValidPUCNumber(newValue) {
                                        pucError = "Please enter a valid PUC number (3 letters followed by 7-14 numbers)"
                                        duplicatePUCError = nil
                                    } else if !isPUCNumberUnique(newValue) {
                                        duplicatePUCError = "This PUC number is already registered"
                                        pucError = nil
                                    } else {
                                        pucError = nil
                                        duplicatePUCError = nil
                                    }
                                } else {
                                    pucError = nil
                                    duplicatePUCError = nil
                                }
                            }
                        
                        if let error = pucError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        } else if let error = duplicatePUCError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    DatePicker(
                        "PUC Expiry Date",
                        selection: $pucExpiryDate,
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: [.date]
                    )
                }
                
                Section("RC Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("RC Number", text: $rcNumber)
                            .textContentType(.none)
                            .textInputAutocapitalization(.characters)
                            .onChange(of: rcNumber, initial: false) { _, newValue in
                                if !newValue.isEmpty {
                                    if !isValidRCNumber(newValue) {
                                        rcError = "Invalid RC number (current: \(newValue.count) chars, required: 15 chars). Format: MH01XXXXX12345"
                                        duplicateRCError = nil
                                    } else if !isRCNumberUnique(newValue) {
                                        duplicateRCError = "This RC number is already registered"
                                        rcError = nil
                                    } else {
                                        rcError = nil
                                        duplicateRCError = nil
                                    }
                                } else {
                                    rcError = nil
                                    duplicateRCError = nil
                                }
                            }
                        
                        if let error = rcError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        } else if let error = duplicateRCError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                    }
                    DatePicker(
                        "RC Expiry Date",
                        selection: $rcExpiryDate,
                        in: Calendar.current.startOfDay(for: Date())...,
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
                        Task {
                            if let coordinates = await getCoordinates(from: currentCoordinate) {
                                print("Coordinates: \(coordinates)")
                                selectedAdress = coordinates
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
                                    currentCoordinate: selectedAdress!.isEmpty ? "0, 0" : selectedAdress!,
                                    status: .available,
                                    activeStatus: true
                                )
                                
                                viewModel.addVehicle(newVehicle)
                                dismiss()
                            } else {
                                print("Failed to get coordinates")
                            }
                        }
                        
                    }
                    .foregroundColor(isFormValid ? Color.primaryGradientEnd : Color.gray)
                    .disabled(!isFormValid)
                }
            }
            .onAppear {
                if !viewModel.vehicleCompanies.isEmpty {
                    make = viewModel.vehicleCompanies[0]
                }
            }
        }
    }
}


