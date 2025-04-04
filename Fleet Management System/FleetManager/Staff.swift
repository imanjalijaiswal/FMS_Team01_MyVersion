//
//  ExampleView.swift
//  SomeProject
//
//  Created by You on 3/20/25.
//

import SwiftUI
import Foundation

enum StaffRole {
    case driver
    case maintenance
}

enum DriverStatus: String, Codable {
    case available = "Available"
    case onTrip = "On Trip"
    case Offline = "Offline"
}

enum MaintenancePersonnelStatus: String, Codable {
    case available = "Available"
    case onDuty = "On Duty"
    case offDuty = "Off Duty"
}

struct DriverRowView: View {
    let driver: Driver
    @ObservedObject var viewModel: IFEDataController
    
    var body: some View {
        NavigationLink(destination: DriverDetailView(driver: driver, viewModel: viewModel).navigationBarBackButtonHidden(false)) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(driver.activeStatus ?
                                     Color.foregroundColorForDriver(driver: driver) : .red)
                    .padding(6)
                    .background(driver.activeStatus ? Color.foregroundColorForDriver(driver: driver).opacity(0.1) : .red.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(driver.meta_data.fullName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(driver.activeStatus ? .primary : .red)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(driver.meta_data.phone)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if driver.activeStatus {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.foregroundColorForDriver(driver: driver))
                                    .frame(width: 4, height: 4)
                                Text(!driver.meta_data.firstTimeLogin ? driver.status.rawValue : "Offline")
                                    .font(.caption)
                                    .foregroundColor(Color.foregroundColorForDriver(driver: driver))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.foregroundColorForDriver(driver: driver).opacity(0.1))
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

struct MaintenancePersonnelRowView: View {
    let personnel: MaintenancePersonnel
    @ObservedObject var viewModel: IFEDataController
    
    var statusText: String {
        if personnel.meta_data.firstTimeLogin {
            return "Offline"
        } else {
            return "Available"
        }
    }
    
    var body: some View {
        NavigationLink(destination: MaintenancePersonnelDetailView(personnel: personnel, viewModel: viewModel).navigationBarBackButtonHidden(false)) {
            HStack(spacing: 12) {
                Image(systemName: "wrench.fill")
                    .font(.system(size: 32))
                    .foregroundColor(Color.setMaintaienceColor(maintaiencePersonal: personnel))
                    .padding(6)
                    .background(Color.setMaintaienceColor(maintaiencePersonal: personnel).opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(personnel.meta_data.fullName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(personnel.activeStatus ? .primary : .red)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(personnel.meta_data.phone)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if personnel.activeStatus {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.setMaintaienceColor(maintaiencePersonal: personnel))
                                    .frame(width: 4, height: 4)
                                Text(statusText)
                                    .font(.caption)
                                    .foregroundColor(Color.setMaintaienceColor(maintaiencePersonal: personnel))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.setMaintaienceColor(maintaiencePersonal: personnel).opacity(0.1))
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

struct StaffView: View {
    @StateObject var viewModel = IFEDataController.shared
    @State private var searchText = ""
    @State private var selectedFilter = ""
    @State private var selectedRole = 0
    @State private var showingAddStaff = false
    @State private var isRefreshing = false
    @State private var viewRefreshTrigger = UUID()
    
    // Separate filters for drivers and maintenance
    let driverFilters = ["All", DriverStatus.available.rawValue, DriverStatus.onTrip.rawValue, "Inactive", DriverStatus.Offline.rawValue]
    let maintenanceFilters = ["All", "Available", "Inactive", "Offline"]
    
    private var availableCount: Int {
        selectedRole == 0 ?
            viewModel.drivers.filter { $0.status == .available && $0.activeStatus && !$0.meta_data.firstTimeLogin }.count :
            viewModel.maintenancePersonnels.filter { $0.activeStatus && !$0.meta_data.firstTimeLogin }.count
    }
    
    private var onTripCount: Int {
        selectedRole == 0 ?
            viewModel.drivers.filter { $0.status == .onTrip && $0.activeStatus && !$0.meta_data.firstTimeLogin }.count :
            0
    }
    
    private var inactiveCount: Int {
        selectedRole == 0 ?
            viewModel.drivers.filter { !$0.activeStatus }.count :
            viewModel.maintenancePersonnels.filter { !$0.activeStatus }.count
    }
    
    private var offlineCount: Int {
        selectedRole == 0 ?
            viewModel.drivers.filter { $0.meta_data.firstTimeLogin }.count :
            viewModel.maintenancePersonnels.filter { $0.meta_data.firstTimeLogin }.count
    }
    
    private var allCount: Int {
        selectedRole == 0 ? viewModel.drivers.count : viewModel.maintenancePersonnels.count
    }
    
    private var filtersWithCount: [String] {
        if selectedRole == 0 {
            return [
                "All (\(allCount))",
                "\(DriverStatus.available.rawValue) (\(availableCount))",
                "\(DriverStatus.onTrip.rawValue) (\(onTripCount))",
                "Inactive (\(inactiveCount))",
                "\(DriverStatus.Offline.rawValue) (\(offlineCount))"
            ]
        } else {
            return [
                "All (\(allCount))",
                "Available (\(availableCount))",
                "Inactive (\(inactiveCount))",
                "Offline (\(offlineCount))"
            ]
        }
    }
    
    var filteredStaff: [Driver] {
        let roleFiltered = viewModel.drivers.filter { driver in
            true
        }

        let searchResults = roleFiltered.filter { staff in
            searchText.isEmpty ||
            staff.meta_data.fullName.localizedCaseInsensitiveContains(searchText) ||
            String(staff.employeeID).localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case _ where selectedFilter.contains(DriverStatus.available.rawValue):
            return searchResults.filter { $0.status == .available && $0.activeStatus && !$0.meta_data.firstTimeLogin }
        case _ where selectedFilter.contains(DriverStatus.onTrip.rawValue):
            return searchResults.filter { $0.status == .onTrip && $0.activeStatus && !$0.meta_data.firstTimeLogin }
        case _ where selectedFilter.contains("Inactive"):
            return searchResults.filter { !$0.activeStatus }
        case _ where selectedFilter.contains(DriverStatus.Offline.rawValue):
            return searchResults.filter { $0.meta_data.firstTimeLogin }
        default:
            let availableDrivers = searchResults.filter{ $0.status == .available && $0.activeStatus && !$0.meta_data.firstTimeLogin }
            let onTripDrivers = searchResults.filter { $0.status == .onTrip && $0.activeStatus && !$0.meta_data.firstTimeLogin }
            let inactiveDrivers = searchResults.filter { !$0.activeStatus }
            let offlineDrivers = searchResults.filter { $0.activeStatus && $0.meta_data.firstTimeLogin }
            
            var results: [Driver] = []
            
            results.append(contentsOf: availableDrivers)
            results.append(contentsOf: onTripDrivers)
            results.append(contentsOf: inactiveDrivers)
            results.append(contentsOf: offlineDrivers)
            
            return results
        }
    }
    
    var filteredMaintenancePersonnel: [MaintenancePersonnel] {
        let searchResults = viewModel.maintenancePersonnels.filter { personnel in
            searchText.isEmpty ||
            personnel.meta_data.fullName.localizedCaseInsensitiveContains(searchText) ||
            String(personnel.employeeID).localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case _ where selectedFilter.contains("Available"):
            return searchResults.filter { $0.activeStatus && !$0.meta_data.firstTimeLogin }
        case _ where selectedFilter.contains("Inactive"):
            return searchResults.filter { !$0.activeStatus }
        case _ where selectedFilter.contains("Offline"):
            return searchResults.filter { $0.meta_data.firstTimeLogin }
        default:
            return searchResults
        }
    }
    
    func refreshData() {
        self.isRefreshing = true
        
        Task {
            await viewModel.loadDrivers()
            await viewModel.loadMaintenancePersonnels()
            await viewModel.loadVehicleCompanies()
            await viewModel.loadServiceCenters()
            
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
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 32)
                        .frame(width: 100)
                        .cornerRadius(16)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Picker("Staff Type", selection: $selectedRole) {
                Text("Drivers").tag(0)
                Text("Maintenance").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: selectedRole) { _, newValue in
                // Reset selected filter when switching between roles
                selectedFilter = filtersWithCount[0]
            }
            
            SearchBar(text: $searchText)
            
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
                PullToRefresh(coordinateSpaceName: "staffPullToRefresh", onRefresh: refreshData, isRefreshing: isRefreshing)
                
                if isRefreshing {
                    // Skeleton View
                    VStack(spacing: 12) {
                        ForEach(0..<10, id: \.self) { _ in
                            contentInsideView()
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // Regular content view
                    VStack(spacing: 12) {
                        if selectedRole == 0 {
                            ForEach(filteredStaff) { staff in
                                DriverRowView(driver: staff, viewModel: viewModel)
                                if staff != filteredStaff.last {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            ForEach(filteredMaintenancePersonnel) { personnel in
                                MaintenancePersonnelRowView(personnel: personnel, viewModel: viewModel)
                                if personnel != filteredMaintenancePersonnel.last {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .id(viewRefreshTrigger)
                }
            }
            .coordinateSpace(name: "staffPullToRefresh")
        }
        .id(viewRefreshTrigger)
        .navigationTitle("Staff")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddStaff = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(.primaryGradientEnd)
                }
            }
        }
        .sheet(isPresented: $showingAddStaff) {
            if selectedRole == 0 {
                AddDriverView(viewModel: viewModel, staffRole: .driver)
            } else {
                AddMaintenancePersonnelView(viewModel: viewModel)
            }
        }
        .background(.white)
        .onAppear {
            if selectedFilter.isEmpty {
                selectedFilter = filtersWithCount[0]
            }
        }
    }
}

struct DriverDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var driver: Driver
    @ObservedObject var viewModel: IFEDataController
    @State private var isEditing = false
    @State private var editedPhone = ""
    @State private var showEmailError = false
    @State private var showingDisableAlert = false
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.foregroundColorForDriver(driver: driver))
                    
                    Text(driver.meta_data.fullName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical)
            }
            
            Section("Driver Info") {
                InfoRow(title: "Employee ID", value: String(driver.employeeID), textColor: isEditing ? .gray : .primary)
                InfoRow(title: "License Number", value: driver.licenseNumber, textColor: isEditing ? .gray : .primary)
                InfoRow(title: "Total Trips", value: "\(driver.totalTrips)", textColor: isEditing ? .gray : .primary)
            }

            Section("Contact") {
                InfoRow(title: "Email", value: driver.meta_data.email, textColor: isEditing ? .gray : .primary)

                if isEditing {
                    VStack(alignment: .leading) {
                        Text("Phone")
                           // .foregroundColor(.gray) // Label similar to InfoRow
                            .font(.headline)
                        TextField("editingPhone", text: $editedPhone)
                            .keyboardType(.phonePad)
                            .textFieldStyle(RoundedBorderTextFieldStyle()) // Enhances visibility
                    }
                } else {
                    InfoRow(title: "Phone", value: editedPhone.isEmpty ? "Not available" : editedPhone, textColor: .primary)
                }
            }


            
            Section {
                if driver.activeStatus {
                    Button(action: {
                        showingDisableAlert = true
                    }) {
                        Text("Make Inactive")
                            .foregroundColor(driver.status == .onTrip ? .gray : .red)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .disabled(driver.status == .onTrip)
                } else {
                    Button(action: {
                        viewModel.enableDriver(driver)
                        dismiss()
                    })
                    {
                                Text("Make Active")
                                    .foregroundColor(.primaryGradientStart)
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                            }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    withAnimation {
                        if isEditing {
                            viewModel.updateDriverPhone(driver, with: editedPhone)
                            isEditing.toggle()
                        } else {
                            isEditing.toggle()
                        }
                    }
                }
                
            }
        }
        .alert("Make Driver Inactive", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Inactive", role: .destructive) {
                viewModel.removeDriver(driver)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to make this driver Inactive ?")
        }
        .onAppear {
            editedPhone = driver.meta_data.phone
        }
    }
}

struct MaintenancePersonnelDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State var personnel: MaintenancePersonnel
    @ObservedObject var viewModel: IFEDataController
    @State private var isEditing = false
    @State private var editedPhone = ""
    @State private var showEmailError = false
    @State private var showingDisableAlert = false
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "wrench.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Color.setMaintaienceColor(maintaiencePersonal: personnel))
                    
                    Text(personnel.meta_data.fullName)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical)
            }
            
            Section("Personnel Info") {
                InfoRow(title: "Employee ID", value: String(personnel.employeeID), textColor: isEditing ? .gray : .primary)
                InfoRow(title: "Total Repairs", value: "\(personnel.totalRepairs)", textColor: isEditing ? .gray : .primary)
            }
            
            Section("Contact") {
                InfoRow(title: "Email", value: personnel.meta_data.email, textColor: isEditing ? .gray : .primary)
                
                if isEditing {
                    VStack(alignment: .leading) {
                        Text("Phone")
                            .font(.headline)
                        TextField("Phone", text: $editedPhone)
                            .keyboardType(.phonePad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                } else {
                    InfoRow(title: "Phone", value: editedPhone.isEmpty ? "Not available" : editedPhone, textColor: .primary)
//                    InfoRow(title: "Service Center", value: personnel.serviceCenterID ? "Not available" : editedPhone, textColor: .primary)
                }
            }
            
            Section {
                if personnel.activeStatus {
                    Button(action: {
                        viewModel.removeMaintenancePersonnel(personnel)
                        showingDisableAlert = true
                    }) {
                        Text("Make Inactive")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Button(action: {
                        viewModel.enableMaintenancePersonnel(personnel)
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
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    withAnimation {
                        if isEditing {
                            isEditing.toggle()
                        } else {
                            isEditing.toggle()
                        }
                    }
                }
                
            }
        }
        .alert("Make Personnel Inactive", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Inactive", role: .destructive) {
                dismiss()
            }
        } message: {
            Text("Are you sure you want to make this maintenance personnel Inactive?")
        }
        .onAppear {
            editedPhone = personnel.meta_data.phone
//            editedCenter =
        }
    }
}

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

func isValidPhone(_ phone: String) -> Bool {
    let phoneRegEx = "^[0-9]{10}$" // Exactly 10 digits
    let phonePred = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
    return phonePred.evaluate(with: phone)
}

func isValidFullName(_ name: String) -> Bool {
    let nameRegEx = "^[a-zA-Z\\s]+$"
    let namePred = NSPredicate(format:"SELF MATCHES %@", nameRegEx)
    return namePred.evaluate(with: name)
}

func isValidLicense(_ license: String) -> Bool {
    // Check if license is 15 characters
    guard license.count == 15 else { return false }
    
    // Regular expression for format: 2 letters, followed by 13 numbers
    let licenseRegEx = "^[A-Z]{2}[0-9]{13}$"
    let licensePred = NSPredicate(format: "SELF MATCHES %@", licenseRegEx)
    return licensePred.evaluate(with: license)
}

struct AddDriverView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IFEDataController
    let staffRole: Role
    
    @State private var employeeId = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var generatedPassword = ""
    @State private var showEmailError = false
    @State private var showPhoneError = false
    @State private var showNameError = false
    @State private var showEmailExistsError = false
    @State private var showPhoneExistsError = false
    @State private var showLicenseError = false
    @State private var showLicenseExistsError = false
    
    private func isEmailExists(_ email: String) -> Bool {
        // Check if email exists in drivers
        let existsInDrivers = viewModel.drivers.contains {
            $0.meta_data.email.lowercased() == email.lowercased()
        }
        
        // Check if email exists in maintenance personnel
        let existsInMaintenance = viewModel.maintenancePersonnels.contains {
            $0.meta_data.email.lowercased() == email.lowercased()
        }
        
        // Check if email exists in fleet manager (current user)
        let existsInManager = viewModel.user?.meta_data.email.lowercased() == email.lowercased()
        
        return existsInDrivers || existsInMaintenance || existsInManager
    }
    
    private func isPhoneExists(_ phone: String) -> Bool {
        return viewModel.drivers.contains { $0.meta_data.phone == phone }
    }
    
    private func isLicenseExists(_ license: String) -> Bool {
           return viewModel.drivers.contains { $0.licenseNumber == license }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && isValidFullName("\(firstName) \(lastName)") &&
        !email.isEmpty && isValidEmail(email) && !isEmailExists(email) &&
        !phone.isEmpty && isValidPhone(phone) && !isPhoneExists(phone) &&
        !licenseNumber.isEmpty && isValidLicense(licenseNumber) && !isLicenseExists(licenseNumber)
    }
    
    func generatePassword() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let specialChars = "!@#$%^&*"
        
        var password = ""
        password += String((0..<3).map { _ in letters.randomElement()! })
        password += String((0..<2).map { _ in numbers.randomElement()! })
        password += String((0..<2).map { _ in specialChars.randomElement()! })
        password += String((0..<3).map { _ in letters.randomElement()! })
        
        return String(password.shuffled())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Driver Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .onChange(of: firstName) { _, newValue in
                                showNameError = !newValue.isEmpty && !isValidFullName(newValue)
                            }
                        if showNameError {
                            Text("Please enter only letters")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .onChange(of: lastName) { _, newValue in
                                showNameError = !firstName.isEmpty && !lastName.isEmpty && !isValidFullName("\(firstName) \(lastName)")
                            }
                        if showNameError {
                            Text("Please enter a valid name (letters only)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) { _, newValue in
                                showEmailError = !newValue.isEmpty && !isValidEmail(newValue)
                                showEmailExistsError = !newValue.isEmpty && isEmailExists(newValue)
                            }
                        if showEmailError {
                            Text("Invalid email address")
                                .foregroundColor(.red)
                                .font(.caption)
                        } else if showEmailExistsError {
                            Text("This email is already registered")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Phone Number", text: $phone)
                            .keyboardType(.numberPad)
                            .onChange(of: phone) { _, newValue in
                                showPhoneError = !newValue.isEmpty && !isValidPhone(newValue)
                                showPhoneExistsError = !newValue.isEmpty && isPhoneExists(newValue)
                                if newValue.count > 10 {
                                    phone = String(newValue.prefix(10))
                                }
                            }
                        if showPhoneError {
                            Text("Please enter a valid 10-digit phone number")
                                .foregroundColor(.red)
                                .font(.caption)
                        } else if showPhoneExistsError {
                            Text("This phone number is already registered")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("License Number (Example: KA0120241234567)", text: $licenseNumber)
                            .textContentType(.name)
                            .onChange(of: licenseNumber) { _, newValue in
                                // Remove any spaces and convert to uppercase
                                let formatted = newValue.replacingOccurrences(of: " ", with: "").uppercased()
                                
                                // Limit to 15 characters
                                if formatted.count > 15 {
                                    licenseNumber = String(formatted.prefix(15))
                                } else {
                                    licenseNumber = formatted
                                }
                                
                                showLicenseError = !licenseNumber.isEmpty && !isValidLicense(licenseNumber)
                                showLicenseExistsError = !licenseNumber.isEmpty && isLicenseExists(licenseNumber)
                            }
                            .textInputAutocapitalization(.characters)
                        
                        if showLicenseError {
                            Text("Format: 2 letters followed by 13 numbers\n(Example: KA0120241234567)")
                                .foregroundColor(.red)
                                .font(.caption)
                        } else if showLicenseExistsError {
                            Text("This license number is already registered")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Add Driver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.primaryGradientEnd)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if isFormValid {
                            let newDriver = Driver(meta_data: UserMetaData(id: UUID(),
                                                                         fullName: "\(firstName) \(lastName)",
                                                                         email: email,
                                                                         phone: phone,
                                                                         role: .driver,
                                                                         employeeID: Int(employeeId) ?? -1,
                                                                         firstTimeLogin: true,
                                                                         createdAt: .now,
                                                                         activeStatus: true),
                                                 licenseNumber: licenseNumber.uppercased(),
                                                 totalTrips: 0,
                                                 status: .available)
                            Task {
                                // Make sure to save the fleet manager ID before adding the driver
                                if let currentUser = viewModel.user, currentUser.role == .fleetManager {
                                    AuthManager.shared.saveActiveFleetManager(id: currentUser.id)
                                }
                                
                                await viewModel.addDriver(newDriver, password: generatedPassword)
                                viewModel.sendWelcomeEmail(to: email, password: generatedPassword)

                                
                                // Ensure we still have the fleet manager's session
                                if viewModel.user == nil || viewModel.user?.role != .fleetManager {
                                    if let fleetManagerId = AuthManager.shared.getActiveFleetManagerID() {
                                        try? await AuthManager.shared.restoreFleetManagerSession()
                                    }
                                }
                                
                                showEmailError = false

                                dismiss()
                            }
                        }
                    }
                    .foregroundColor(isFormValid ? Color.primaryGradientEnd : Color.gray)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
            generatedPassword = generatePassword()
        }
    }
}

struct AddMaintenancePersonnelView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IFEDataController
    
    @State private var employeeId = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var generatedPassword = ""
    @State private var showEmailError = false
    @State private var showPhoneError = false
    @State private var showNameError = false
    @State private var showEmailExistsError = false
    @State private var showPhoneExistsError = false
    @State private var serviceCenter: Int = 0
    
    var availableServiceCenterLocations: [Int: String] {
        var availableServiceCenters = viewModel.serviceCenters.filter { !$0.isAssigned }
        
        var centers: [Int: String] = Dictionary(uniqueKeysWithValues: availableServiceCenters.compactMap { center in
            guard let location = viewModel.serviceCenterLocations[center.id] else { return nil }
            return (center.id, location)
        })

        // Add key 0 with a default value
        centers[0] = "Select Service Center"

        return centers
    }
    
    private func isEmailExists(_ email: String) -> Bool {
        // Check if email exists in maintenance personnel
        let existsInMaintenance = viewModel.maintenancePersonnels.contains {
            $0.meta_data.email.lowercased() == email.lowercased()
        }
        
        // Check if email exists in drivers
        let existsInDrivers = viewModel.drivers.contains {
            $0.meta_data.email.lowercased() == email.lowercased()
        }
        
        // Check if email exists in fleet manager (current user)
        let existsInManager = viewModel.user?.meta_data.email.lowercased() == email.lowercased()
        
        return existsInMaintenance || existsInDrivers || existsInManager
    }
    
    private func isPhoneExists(_ phone: String) -> Bool {
        return viewModel.maintenancePersonnels.contains { $0.meta_data.phone == phone }
    }
    
    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty &&
        isValidFullName("\(firstName) \(lastName)") &&
        !email.isEmpty && isValidEmail(email) && !isEmailExists(email) &&
        !phone.isEmpty && isValidPhone(phone) && !isPhoneExists(phone) &&
        (serviceCenter != 0)
    }
    
    func generatePassword() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let specialChars = "!@#$%^&*"
        
        var password = ""
        password += String((0..<3).map { _ in letters.randomElement()! })
        password += String((0..<2).map { _ in numbers.randomElement()! })
        password += String((0..<2).map { _ in specialChars.randomElement()! })
        password += String((0..<3).map { _ in letters.randomElement()! })
        
        return String(password.shuffled())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Maintenance Personnel Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)
                            .onChange(of: firstName) { _, newValue in
                                showNameError = !newValue.isEmpty && !isValidFullName(newValue)
                            }
                        if showNameError {
                            Text("Please enter only letters")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                            .onChange(of: lastName) { _, newValue in
                                showNameError = !firstName.isEmpty && !lastName.isEmpty &&
                                              !isValidFullName("\(firstName) \(lastName)")
                            }
                        if showNameError {
                            Text("Please enter a valid name (letters only)")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .onChange(of: email) { _, newValue in
                                showEmailError = !newValue.isEmpty && !isValidEmail(newValue)
                                showEmailExistsError = !newValue.isEmpty && isEmailExists(newValue)
                            }
                        if showEmailError {
                            Text("Invalid email address")
                                .foregroundColor(.red)
                                .font(.caption)
                        } else if showEmailExistsError {
                            Text("This email is already registered")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Phone Number", text: $phone)
                            .keyboardType(.numberPad)
                            .onChange(of: phone) { _, newValue in
                                showPhoneError = !newValue.isEmpty && !isValidPhone(newValue)
                                showPhoneExistsError = !newValue.isEmpty && isPhoneExists(newValue)
                                if newValue.count > 10 {
                                    phone = String(newValue.prefix(10))
                                }
                            }
                        if showPhoneError {
                            Text("Please enter a valid 10-digit phone number")
                                .foregroundColor(.red)
                                .font(.caption)
                        } else if showPhoneExistsError {
                            Text("This phone number is already registered")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    Picker("Service Center", selection: $serviceCenter) {
                        ForEach(availableServiceCenterLocations.sorted(by: { $0.key < $1.key }), id: \.key) { key, center in
                            Text(center).tag(key) // Use the key as the tag
                        }
                    }

                }
            }
            .navigationTitle("Add Maintenance Personnel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.primaryGradientEnd)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if isFormValid {
                            Task {
                                let newPersonnel = MaintenancePersonnel(
                                    meta_data: UserMetaData(
                                        id: UUID(),
                                        fullName: "\(firstName) \(lastName)",
                                        email: email,
                                        phone: phone,
                                        role: .maintenancePersonnel,
                                        employeeID: Int(employeeId) ?? -1,
                                        firstTimeLogin: true,
                                        createdAt: .now,
                                        activeStatus: true
                                    ),
                                    totalRepairs: 0,
                                    serviceCenterID: self.serviceCenter
                                )
                                
                                await viewModel.addMaintenancePersonnel(newPersonnel, password: generatedPassword)
                                viewModel.sendWelcomeEmail(to: email, password: generatedPassword)
                                
                                let index = viewModel.serviceCenters.firstIndex(where: {
                                    $0.id == self.serviceCenter
                                })
                                viewModel.serviceCenters[index!].isAssigned = true
                                dismiss()
                            }
                        }
                    }
                    .foregroundColor(isFormValid ? Color.primaryGradientEnd : Color.gray)
                    .disabled(!isFormValid)
                }
            }
        }
        .onAppear {
//            if !availableServiceCenterLocations.isEmpty {
//                serviceCenter = "Select Service Center"
//            }
            generatedPassword = generatePassword()
        }
    }
}

struct MaintenancePersonnelListView: View {
    @ObservedObject var viewModel: IFEDataController
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.maintenancePersonnels) { personnel in
                    MaintenancePersonnelRowView(personnel: personnel, viewModel: viewModel)
                    if personnel != viewModel.maintenancePersonnels.last {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
