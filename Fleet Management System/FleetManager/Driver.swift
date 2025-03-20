import SwiftUI
import Foundation

struct Driver: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let totalTrips: Int
    let licenseNumber: String
    let emailId: String
    let employeeId: String
    let phoneNumber: String
    let isAvailable: Bool
    let isActive: Bool
    
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
            employeeId: driver.employeeId,
            phoneNumber: driver.phoneNumber,
            isAvailable: false,
            isActive: false
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
            employeeId: driver.employeeId,
            phoneNumber: driver.phoneNumber,
            isAvailable: true,
            isActive: true
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
                        .foregroundColor(driver.isActive ? .primary : .red)
                    
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(driver.phoneNumber)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if driver.isActive {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(driver.isAvailable ? Color.green : Color.gray)
                                    .frame(width: 4, height: 4)
                                Text(driver.isAvailable ? "Available" : "On Trip")
                                    .font(.caption)
                                    .foregroundColor(driver.isAvailable ? .green : .gray)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(driver.isAvailable ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
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
            driver.employeeId.localizedCaseInsensitiveContains(searchText)
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
                    Driver(name: "John Doe", totalTrips: 125, licenseNumber: "DL123456", emailId: "john@example.com", employeeId: "EMP001", phoneNumber: "+1234567890", isAvailable: true, isActive: true),
                    Driver(name: "Jane Smith", totalTrips: 98, licenseNumber: "DL789012", emailId: "jane@example.com", employeeId: "EMP002", phoneNumber: "+0987654321", isAvailable: true, isActive: true),
                    Driver(name: "Mike Johnson", totalTrips: 156, licenseNumber: "DL345678", emailId: "mike@example.com", employeeId: "EMP003", phoneNumber: "+1122334455", isAvailable: true, isActive: true),
                    Driver(name: "Sarah Wilson", totalTrips: 112, licenseNumber: "DL456789", emailId: "sarah@example.com", employeeId: "EMP004", phoneNumber: "+2233445566", isAvailable: true, isActive: true),
                    Driver(name: "David Brown", totalTrips: 143, licenseNumber: "DL567890", emailId: "david@example.com", employeeId: "EMP005", phoneNumber: "+3344556677", isAvailable: true, isActive: true),
                    Driver(name: "Emma Davis", totalTrips: 87, licenseNumber: "DL678901", emailId: "emma@example.com", employeeId: "EMP006", phoneNumber: "+4455667788", isAvailable: true, isActive: true),
                    Driver(name: "James Wilson", totalTrips: 165, licenseNumber: "DL789012", emailId: "james@example.com", employeeId: "EMP007", phoneNumber: "+5566778899", isAvailable: true, isActive: true),
                    Driver(name: "Linda Taylor", totalTrips: 134, licenseNumber: "DL890123", emailId: "linda@example.com", employeeId: "EMP008", phoneNumber: "+6677889900", isAvailable: true, isActive: true),
                    Driver(name: "Robert Martin", totalTrips: 145, licenseNumber: "DL901234", emailId: "robert@example.com", employeeId: "EMP009", phoneNumber: "+7788990011", isAvailable: true, isActive: true),
                    Driver(name: "Mary Anderson", totalTrips: 98, licenseNumber: "DL012345", emailId: "mary@example.com", employeeId: "EMP010", phoneNumber: "+8899001122", isAvailable: true, isActive: true)
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
                InfoRow(title: "Employee ID", value: driver.employeeId)
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
                if driver.isActive {
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
                                employeeId: employeeId,
                                phoneNumber: phone,
                                isAvailable: true,
                                isActive: true
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
