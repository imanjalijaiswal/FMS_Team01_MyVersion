import SwiftUI
import Foundation

enum DriverStatus: String, Codable {
    case available = "Available"
    case onTrip = "On Trip"
}

struct Driver: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let totalTrips: Int
    let licenseNumber: String
    let emailId: String
    let driverID: String
    let phoneNumber: String
    let status: DriverStatus
    let workingStatus: Bool
    
    static func == (lhs: Driver, rhs: Driver) -> Bool {
        lhs.id == rhs.id
    }
}

class DriverViewModel: ObservableObject {
    @Published var drivers: [Driver] = []
    @Published var assignedTrips: [AssignedTrip] = []
    
    func addDriver(_ driver: Driver) {
        drivers.append(driver)
    }
    
    func removeDriver(_ driver: Driver) {
        let inactiveDriver = Driver(
            name: driver.name,
            totalTrips: driver.totalTrips,
            licenseNumber: driver.licenseNumber,
            emailId: driver.emailId,
            driverID: driver.driverID,
            phoneNumber: driver.phoneNumber,
            status: .available,
            workingStatus: false
        )
        
        drivers.removeAll { $0.id == driver.id }
        drivers.append(inactiveDriver)
    }
    
    func enableDriver(_ driver: Driver) {
        let activeDriver = Driver(
            name: driver.name,
            totalTrips: driver.totalTrips,
            licenseNumber: driver.licenseNumber,
            emailId: driver.emailId,
            driverID: driver.driverID,
            phoneNumber: driver.phoneNumber,
            status: .available,
            workingStatus: true
        )
        
        drivers.removeAll { $0.id == driver.id }
        drivers.append(activeDriver)
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
                    Text(driver.name)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(driver.workingStatus ? .primary : .red)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(driver.phoneNumber)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if driver.workingStatus {
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

struct DriversView: View {
    @StateObject private var viewModel = DriverViewModel()
    
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    let filters = ["All", "Available", "On Trip", "Inactive"]
    @State private var showingAddDriver = false
    
    var filteredDrivers: [Driver] {
        let searchResults = viewModel.drivers.filter { driver in
            searchText.isEmpty ||
            driver.name.localizedCaseInsensitiveContains(searchText) ||
            driver.driverID.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case "Available":
            return searchResults.filter { $0.status == .available && $0.workingStatus }
        case "On Trip":
            return searchResults.filter { $0.status == .onTrip && $0.workingStatus }
        case "Inactive":
            return searchResults.filter { !$0.workingStatus }
        default:
            return searchResults.filter { $0.workingStatus }
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
                    ForEach(filteredDrivers) { driver in
                        DriverRowView(driver: driver, viewModel: viewModel)
                        if driver != filteredDrivers.last {
                            Divider()
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Drivers")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddDriver = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddDriver) {
            AddDriverView(viewModel: viewModel)
        }
        .onAppear {
            if viewModel.drivers.isEmpty {
                viewModel.drivers = [
                    Driver(name: "John Doe", totalTrips: 125, licenseNumber: "DL123456", emailId: "john@example.com", driverID: "EMP001", phoneNumber: "+1234567890", status: .available, workingStatus: true),
                    Driver(name: "Jane Smith", totalTrips: 98, licenseNumber: "DL789012", emailId: "jane@example.com", driverID: "EMP002", phoneNumber: "+0987654321", status: .available, workingStatus: true),
                    Driver(name: "Mike Johnson", totalTrips: 156, licenseNumber: "DL345678", emailId: "mike@example.com", driverID: "EMP003", phoneNumber: "+1122334455", status: .available, workingStatus: true),
                    Driver(name: "Sarah Wilson", totalTrips: 112, licenseNumber: "DL456789", emailId: "sarah@example.com", driverID: "EMP004", phoneNumber: "+2233445566", status: .available, workingStatus: true),
                    Driver(name: "David Brown", totalTrips: 143, licenseNumber: "DL567890", emailId: "david@example.com", driverID: "EMP005", phoneNumber: "+3344556677", status: .available, workingStatus: true),
                    Driver(name: "Emma Davis", totalTrips: 87, licenseNumber: "DL678901", emailId: "emma@example.com", driverID: "EMP006", phoneNumber: "+4455667788", status: .available, workingStatus: true),
                    Driver(name: "James Wilson", totalTrips: 165, licenseNumber: "DL789012", emailId: "james@example.com", driverID: "EMP007", phoneNumber: "+5566778899", status: .available, workingStatus: true),
                    Driver(name: "Linda Taylor", totalTrips: 134, licenseNumber: "DL890123", emailId: "linda@example.com", driverID: "EMP008", phoneNumber: "+6677889900", status: .available, workingStatus: true),
                    Driver(name: "Robert Martin", totalTrips: 145, licenseNumber: "DL901234", emailId: "robert@example.com", driverID: "EMP009", phoneNumber: "+7788990011", status: .available, workingStatus: true),
                    Driver(name: "Mary Anderson", totalTrips: 98, licenseNumber: "DL012345", emailId: "mary@example.com", driverID: "EMP010", phoneNumber: "+8899001122", status: .available, workingStatus: true)
                ]
            }
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
                    
                    Text(driver.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .padding(.vertical)
            }
            
            Section("Driver Info") {
                InfoRow(title: "Employee ID", value: driver.driverID)
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
                if driver.workingStatus {
                    Button(action: {
                        showingDisableAlert = true
                    }) {
                        Text("Disable Driver")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Button(action: {
                        viewModel.enableDriver(driver)
                        dismiss()
                    }) {
                        Text("Enable Driver")
                            .foregroundColor(.green)
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
        .alert("Disable Driver", isPresented: $showingDisableAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                viewModel.removeDriver(driver)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to disable this driver? This action cannot be undone.")
        }
        .onAppear {
            editedEmail = driver.emailId
            editedPhone = driver.phoneNumber
        }
    }
}

struct AddDriverView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: DriverViewModel
    
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
                    TextField("Employee ID", text: $employeeId)
                        .textContentType(.name)
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if isValidEmail(email) && isValidPhone(phone) {
                            let newDriver = Driver(
                                name: fullName,
                                totalTrips: 0,
                                licenseNumber: licenseNumber,
                                emailId: email,
                                driverID: employeeId,
                                phoneNumber: phone,
                                status: .available,
                                workingStatus: true
                            )
                            
                            viewModel.addDriver(newDriver)
                            viewModel.sendWelcomeEmail(to: email, password: generatedPassword)
                            
                            showEmailError = false
                            dismiss()
                        } else {
                            showEmailError = !isValidEmail(email)
                            showPhoneError = !isValidPhone(phone)
                        }
                    }
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
