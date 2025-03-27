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


struct DriverRowView: View {
    let driver: Driver
    @ObservedObject var viewModel: IFEDataController
    
    var body: some View {
        NavigationLink(destination: DriverDetailView(driver: driver, viewModel: viewModel)) {
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
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
                                    .fill(!driver.meta_data.firstTimeLogin ? ((driver.status == .available) ? Color.green : Color.gray) : Color.red)
                                    .frame(width: 4, height: 4)
                                Text(!driver.meta_data.firstTimeLogin ? driver.status.rawValue : "Offline")
                                    .font(.caption)
                                    .foregroundColor(!driver.meta_data.firstTimeLogin ? ((driver.status == .available) ? .green : .gray) : .red)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(!driver.meta_data.firstTimeLogin ? ((driver.status == .available) ? Color.green.opacity(0.1) : Color.gray.opacity(0.1)) : Color.red.opacity(0.1))
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
    let filters = ["All", DriverStatus.available.rawValue, DriverStatus.onTrip.rawValue, "Inactive", DriverStatus.Offline.rawValue]
    @State private var showingAddStaff = false
    
    private var availableCount: Int {
        viewModel.drivers.filter { $0.status == .available && $0.activeStatus && !$0.meta_data.firstTimeLogin }.count
    }
    
    private var onTripCount: Int {
        viewModel.drivers.filter { $0.status == .onTrip && $0.activeStatus && !$0.meta_data.firstTimeLogin }.count
    }
    
    private var inactiveCount: Int {
        viewModel.drivers.filter { !$0.activeStatus }.count
    }
    
    private var offlineCount: Int {
        viewModel.drivers.filter { $0.meta_data.firstTimeLogin }.count
    }
    
    private var allCount: Int {
        viewModel.drivers.count
    }
    
    private var filtersWithCount: [String] {
        [
            "All (\(allCount))",
            "\(DriverStatus.available.rawValue) (\(availableCount))",
            "\(DriverStatus.onTrip.rawValue) (\(onTripCount))",
            "Inactive (\(inactiveCount))",
            "\(DriverStatus.Offline.rawValue) (\(offlineCount))"
        ]
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
            return searchResults.filter { _ in true }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Picker("Staff Type", selection: $selectedRole) {
                Text("Drivers").tag(0)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            SearchBar(text: $searchText)
            
            FilterSection(
                title: "",
                filters: filtersWithCount,
                selectedFilter: $selectedFilter
            )
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(filteredStaff) { staff in
                        DriverRowView(driver: staff, viewModel: viewModel)
                        if staff != filteredStaff.last {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
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
            AddDriverView(viewModel: viewModel, staffRole: .driver)
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
                        .foregroundColor(.gray)
                    
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
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var licenseNumber = ""
    @State private var generatedPassword = ""
    @State private var showEmailError = false
    @State private var showPhoneError = false
    @State private var showNameError = false
    @State private var showLicenseError = false
    @State private var showEmailExistsError = false
    @State private var showPhoneExistsError = false
    @State private var showLicenseExistsError = false
    
    private func isEmailExists(_ email: String) -> Bool {
        return viewModel.drivers.contains { $0.meta_data.email.lowercased() == email.lowercased() }
    }
    
    private func isPhoneExists(_ phone: String) -> Bool {
        return viewModel.drivers.contains { $0.meta_data.phone == phone }
    }
    
    private func isLicenseExists(_ license: String) -> Bool {
           return viewModel.drivers.contains { $0.licenseNumber == license }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && isValidFullName(fullName) &&
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
                        TextField("Full Name", text: $fullName)
                            .textContentType(.name)
                            .onChange(of: fullName) { _, newValue in
                                showNameError = !newValue.isEmpty && !isValidFullName(newValue)
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
                                                                         fullName: fullName,
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
                                await viewModel.addDriver(newDriver, password: generatedPassword)
                                viewModel.sendWelcomeEmail(to: email, password: generatedPassword)
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

#Preview{
    StaffView()
}
