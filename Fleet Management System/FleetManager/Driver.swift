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

//struct Driver: Identifiable, Equatable,Codable {
//    let id : UUID
//    let fullName: String
//    let totalTrips: Int
//    let licenseNumber: String
//    let email: String
//    let driverID: String
//    let phoneNumber: String
//    let status: DriverStatus
//    let workingStatus: Bool
//    let role: Role
//    
//    static func == (lhs: Driver, rhs: Driver) -> Bool {
//        lhs.id == rhs.id
//    }
//}

class DriverViewModel: ObservableObject {
    static let shared = DriverViewModel() // Singleton instance
    
    @Published var drivers: [Driver] = []
    @Published var vehicles: [Vehicle] = []
    @Published var trips: [Trip] = []
    
//    private init() {
        // Initialize with sample data
//        let sampleDrivers = [
//            Driver(id: UUID(), fullName: "John Doe", totalTrips: 125, licenseNumber: "DL123456", email: "john@example.com", driverID: "EMP001", phoneNumber: "+1234567890", status: .available, workingStatus: true, role: .driver),
//            Driver(id: UUID(), fullName: "Jane Smith", totalTrips: 98, licenseNumber: "DL789012", email: "jane@example.com", driverID: "EMP002", phoneNumber: "+0987654321", status: .available, workingStatus: true, role: .driver)
//        ]
//        let sampleVehicles = [
//            Vehicle(id: 1, make: "Tata Motors", model: "Tata Prima", vinNumber: "1HGCM82633A123456", licenseNumber: "TN01AB1234", fuelType: .diesel, loadCapacity: 25, insurancePolicyNumber: "INS123456", insuranceExpiryDate: Date(), pucCertificateNumber: "PUC123456", pucExpiryDate: Date(), rcNumber: "RC123456", rcExpiryDate: Date(), currentCoordinate: "Bangalore", status: .available, activeStatus: true),
//            Vehicle(id: 2, make: "BharatBenz", model: "BharatBenz 3723R", vinNumber: "2FMZA52233B234567", licenseNumber: "KA02CD5678", fuelType: .diesel, loadCapacity: 37, insurancePolicyNumber: "INS234567", insuranceExpiryDate: Date(), pucCertificateNumber: "PUC234567", pucExpiryDate: Date(), rcNumber: "RC234567", rcExpiryDate: Date(), currentCoordinate: "Chennai", status: .available, activeStatus: true),
//            Vehicle(id: 3, make: "Ashok Leyland", model: "Ashok Leyland 2820", vinNumber: "3VWFA21233M345678", licenseNumber: "MH03EF9012", fuelType: .diesel, loadCapacity: 28, insurancePolicyNumber: "INS345678", insuranceExpiryDate: Date(), pucCertificateNumber: "PUC345678", pucExpiryDate: Date(), rcNumber: "RC345678", rcExpiryDate: Date(), currentCoordinate: "Mumbai", status: .available, activeStatus: true)
//        ]
//        vehicles = sampleVehicles
//        drivers = sampleDrivers
//    } // Private initializer to enforce singleton pattern
    
    func addDriver(_ driver: Driver) {
        drivers.append(driver)
    }
    
    func removeDriver(_ driver: Driver) {
        var inactiveDriver = driver
        inactiveDriver.meta_data.activeStatus = false
        drivers.removeAll { $0 == driver }
        drivers.append(inactiveDriver)
    }
    
    func enableDriver(_ driver: Driver) {
        var activeDriver = driver
        activeDriver.meta_data.activeStatus = true
        drivers.removeAll { $0 == driver }
        drivers.append(activeDriver)
    }
    
    func updateTripStatus(_ trip: Trip, to newStatus: TripStatus) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].status = newStatus
        }
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }
    
    func removeVehicle(_ vehicle: Vehicle) {
        let inactiveVehicle = vehicle
        
        vehicles.removeAll { $0.id == vehicle.id }
        vehicles.append(inactiveVehicle)
    }
    
    func enableVehicle(_ vehicle: Vehicle) {
        let activeVehicle = vehicle
        
        vehicles.removeAll { $0.id == vehicle.id }
        vehicles.append(activeVehicle)
    }
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        // Update driver status to onTrip
        for driverId in trip.assignedDriverIDs {
            if let index = drivers.firstIndex(where: { $0.id == driverId }) {
                var driver = drivers[index]
//                driver.totalTrips += 1
                driver.status = .onTrip
                drivers[index] = driver
            }
        }
        // Update vehicle status to inUse
        if let index = vehicles.firstIndex(where: { $0.id == trip.assigneVehicleID }) {
            var vehicle = vehicles[index]
            vehicle.status = .assigned
            vehicles[index] = vehicle
        }
    }
    
    func getFilteredTrips(status: TripStatus?) -> [Trip] {
        if let status = status {
            return trips.filter { $0.status == status }
        }
        return trips
    }
    
    func sendWelcomeEmail(to email: String, password: String) {
        print("Sending welcome email to: \(email)")
        print("Email content: Welcome to Fleet Management System!")
        print("Your login credentials are:")
        print("Email: \(email)")
        print("Password: \(password)")
    }
}

struct DriverRowView: View {
    let driver: Driver
    @ObservedObject var viewModel: DriverViewModel
    
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
    @StateObject var viewModel = DriverViewModel.shared
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
    let driver: Driver
    @ObservedObject var viewModel: DriverViewModel
    @State private var isEditing = false
    @State private var editedEmail = ""
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
                if isEditing {
                    TextField("Email", text: $editedEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    if showEmailError {
                        Text("Invalid email address")
                            .foregroundColor(.red)
                    }
                    TextField("Phone", text: $editedPhone)
                        .keyboardType(.phonePad)
                } else {
                    InfoRow(title: "Email", value: editedEmail)
                    InfoRow(title: "Phone", value: editedPhone)
                }
            }
            
            Section {
                if driver.activeStatus {
                    Button(action: {
                        showingDisableAlert = true
                    }) {
                        Text("Make Inactive")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
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
                            if isValidEmail(editedEmail) {
                                isEditing.toggle()
                            } else {
                                showEmailError = true
                            }
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
            editedEmail = driver.meta_data.email
            editedPhone = driver.meta_data.phone
        }
    }
}
                        

struct AddDriverView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DriverViewModel
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
                            //TODO: add new driver to database and auto set employeeID
                            viewModel.addDriver(newDriver)
                            viewModel.sendWelcomeEmail(to: email, password: generatedPassword)
                            
                            showEmailError = false
                            dismiss()
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
