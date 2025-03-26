import SwiftUI
import Foundation

enum StaffRole {
    case driver
    case maintenance
}

enum DriverStatus: String, Codable {
    case available = "Available"
    case onTrip = "On Trip"
    case inactive = "Inactive"
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
                                    .fill((driver.status == .available) ? Color.green : Color.gray)
                                    .frame(width: 4, height: 4)
                                Text(driver.status.rawValue)
                                    .font(.caption)
                                    .foregroundColor((driver.status == .available) ? .green : .gray)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((driver.status == .available) ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
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
    @State private var selectedFilter = "All"
    @State private var selectedRole = 0 // 0 for drivers, 1 for maintenance
    let filters = ["All", DriverStatus.available.rawValue, DriverStatus.onTrip.rawValue, DriverStatus.inactive.rawValue]
    @State private var showingAddStaff = false
    
    var filteredStaff: [Driver] {
        let roleFiltered = viewModel.drivers.filter { driver in
//            selectedRole == 0 ? driver.role == .driver : driver.role == .maintenancePersonal
            true
        }

        let searchResults = roleFiltered.filter { staff in
            searchText.isEmpty ||
            staff.meta_data.fullName.localizedCaseInsensitiveContains(searchText) ||
            String(staff.employeeID).localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case DriverStatus.available.rawValue:
            return searchResults.filter { $0.status == .available && $0.activeStatus }
        case DriverStatus.onTrip.rawValue:
            return searchResults.filter { $0.status == .onTrip && $0.activeStatus }
        case DriverStatus.inactive.rawValue:
            return searchResults.filter { !$0.activeStatus }
        default:
            return searchResults.filter { $0.activeStatus }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Role Picker
            Picker("Staff Type", selection: $selectedRole) {
                Text("Drivers").tag(0)
//                Text("Maintenance").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            SearchBar(text: $searchText)
            
            FilterSection(
                title: "",
                filters: filters,
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
            // Empty onAppear since data is initialized in ViewModel
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
                InfoRow(title: "Employee ID", value: String(driver.employeeID))
                InfoRow(title: "License Number", value: driver.licenseNumber)
                InfoRow(title: "Total Trips", value: "\(driver.totalTrips)")
            }
            
            Section("Contact") {
                InfoRow(title: "Email", value: driver.meta_data.email)
                if isEditing {
                    TextField("Phone", text: $editedPhone)
                        .keyboardType(.phonePad)
                    
                } else {
                    InfoRow(title: "Phone", value: editedPhone)
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
                                    .foregroundColor(.blue)
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
            Text("Are you sure you want to make this driver as Inactive?")
        }
        .onAppear {
            editedPhone = driver.meta_data.phone
        }
    }
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

                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    if showEmailError {
                        Text("Invalid email address")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    if showPhoneError {
                        Text("Invalid phone number")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    TextField("License Number", text: $licenseNumber)
                        .textContentType(.name)
                }
                
                Section("Generated Password") {
                    Text(generatedPassword)
                        .foregroundColor(.gray)
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
                        if isValidEmail(email) && isValidPhone(phone) {
                            let newDriver = Driver(meta_data: UserMetaData(id: UUID(),
                                                                           fullName: fullName,
                                                                           email: email,
                                                                           phone: phone,
                                                                           role: .driver,
                                                                           employeeID: Int(employeeId) ?? -1,
                                                                           firstTimeLogin: true,
                                                                           createdAt: .now,
                                                                           activeStatus: true),
                                                   licenseNumber: licenseNumber,
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
                        } else {
                            showEmailError = !isValidEmail(email)
                            showPhoneError = !isValidPhone(phone)
                        }
                    }
                    .foregroundColor(Color.primaryGradientEnd)
                    .disabled(!isValidEmail(email) || !isValidPhone(phone))
                }
            }
        }
        .onAppear {
            generatedPassword = generatePassword()
        }
    }
}

func isValidEmail(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
}

func isValidPhone(_ phone: String) -> Bool {
    let phoneRegEx = "^[0-9+][0-9]{9,14}$" // Allows + prefix and 10-15 digits
    let phonePred = NSPredicate(format:"SELF MATCHES %@", phoneRegEx)
    return phonePred.evaluate(with: phone)
}


#Preview{
    StaffView()
}
