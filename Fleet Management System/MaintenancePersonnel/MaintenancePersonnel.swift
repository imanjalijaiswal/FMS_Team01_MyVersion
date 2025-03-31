//
//  MaintenancePersonnel.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 19/03/25.
//

import Foundation
import SwiftUI
import MapKit

import PDFKit  // For PDF generation

struct MaintenanceView: View {
    @Binding var user: AppUser?
    @Binding var role: Role?
    @State private var selectedTab = 0 // 0 for Maintenance, 1 for SOS
    @State private var selectedSegment = 0 // 0 for Scheduled, 1 for In Progress, 2 for Completed
    @State private var sosSelectedSegment = 0 // 0 for Pre-inspection, 1 for Post-inspection, 2 for Emergency
    @State private var tasks: [MaintenanceTask] = []
    @State private var sosTasks: [MaintenanceTask] = []
    @State private var isLoading = false
    @State private var isSosLoading = false
    @State private var showingCompletionDaysSheet = false
    @State private var showingInvoiceSheet = false
    @State private var selectedTask: MaintenanceTask?
    @State private var completionDays = 1
    @State private var showingProfile = false
    @State private var vehicleLicenseMap: [Int: String] = [:]
    @State private var userPhoneMap: [UUID: String] = [:]
    @State private var userNameMap: [UUID: String] = [:]
    @State private var showingStartWorkConfirmation = false
    @State private var taskToStart: MaintenanceTask?
    @State private var laborCost: String = "0.0"
    @State private var partsCost: String = "0.0"
    @State private var otherCost: String = "0.0"
    @State private var repairNote: String = ""
    @State private var showingInvoicePreview = false
    @State private var generatedInvoice: Invoice?
    @State private var showLocationTracking = false
    
    // Reference to data controllers
    private let dataController = IFEDataController.shared
    
    // Add computed property for total cost
    private var totalCost: Double {
        let laborAmount = Double(laborCost) ?? 0
        let partsAmount = Double(partsCost) ?? 0
        let otherAmount = Double(otherCost) ?? 0
        return laborAmount + partsAmount + otherAmount
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // MAINTENANCE TAB
            MaintenanceTabView(
                selectedSegment: $selectedSegment,
                isLoading: isLoading,
                filteredTasks: filteredTasks,
                vehicleLicenseMap: vehicleLicenseMap,
                onShowProfile: { showingProfile = true },
                onSelectTask: { task in
                    selectedTask = task
                },
                onStartWork: { task in
                    taskToStart = task
                    showingStartWorkConfirmation = true
                },
                onUpdateCompletionDays: { task, days in
                    selectedTask = task
                    updateCompletionDays(days: days)
                },
                onCreateInvoice: { task in
                    selectedTask = task
                    showingInvoiceSheet = true
                }
            )
            .edgesIgnoringSafeArea(.top)
            .tabItem {
                Image(systemName: "wrench.and.screwdriver.fill")
                Text("Maintenance")
            }
            .tag(0)
            
            // SOS TAB
            SOSTabView(
                sosSelectedSegment: $sosSelectedSegment,
                isSosLoading: isSosLoading,
                filteredSOSTasks: filteredSOSTasks,
                vehicleLicenseMap: vehicleLicenseMap,
                userPhoneMap: userPhoneMap,
                userNameMap: userNameMap,
                onShowProfile: { showingProfile = true },
                onTrackTask: { task in
                    selectedTask = task
                    showLocationTracking = true
                }
            )
            .edgesIgnoringSafeArea(.top)
            .tabItem {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("SOS")
            }
            .tag(1)
//            .badge(5)
        }
        .onAppear {
            // Set the TabView appearance to match iOS design
            UITabBar.appearance().backgroundColor = .systemBackground
            
            // Debug print for user details
            print("DEBUG: User ID: \(user?.id.uuidString ?? "nil"), Role: \(user?.role.rawValue ?? "nil")")
            
            loadTasks()
            loadSOSTasks()
        }
        .alert("Start Work", isPresented: $showingStartWorkConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Start Work") {
                if let task = taskToStart {
                    startWork(task: task)
                }
            }
        } message: {
            Text("Are you sure you want to start work on this task?")
        }
        .sheet(isPresented: $showingInvoiceSheet) {
            if let task = selectedTask {
                NavigationView {
                    Form {
                        Section(header: Text("Vehicle Information")) {
                            if let license = vehicleLicenseMap[task.vehicleID] {
                                Text("Vehicle: \(license)")
                            } else {
                                Text("Vehicle ID: \(task.vehicleID)")
                            }
                            Text("Task ID: \(task.taskID)")
                            Text("Type: \(task.type.rawValue)")
                        }
                        
                        Section(header: Text("Cost Breakdown")) {
                            HStack {
                                Text("Labor Cost")
                                Spacer()
                                TextField("0.00", text: $laborCost)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("Parts Cost")
                                Spacer()
                                TextField("0.00", text: $partsCost)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("Other Cost")
                                Spacer()
                                TextField("0.00", text: $otherCost)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            HStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                Spacer()
                                
                                // Break down the complex calculation into steps
                                let calculatedTotal = totalCost
                                Text("₹\(calculatedTotal, specifier: "%.2f")")
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Section(header: Text("Repair Notes")) {
                            TextEditor(text: $repairNote)
                                .frame(height: 100)
                        }
                        
                        Section {
                            Button("Complete Task & Generate Invoice") {
                                completeTaskAndGenerateInvoice(task: task)
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    .navigationTitle("Create Invoice")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingInvoiceSheet = false
                    })
                }
            } else {
                Text("No task selected")
            }
        }
        .sheet(isPresented: $showingInvoicePreview) {
            if let invoice = generatedInvoice {
                InvoicePreviewView(invoice: invoice)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(user: $user, role: $role)
        }
        .sheet(isPresented: $showLocationTracking) {
            Group {
                if let task = selectedTask {
                    let vehicleLicense = vehicleLicenseMap[task.vehicleID] ?? "Unknown Vehicle"

                    NavigationView {
                        LocationTrackingView(
                            task: task,
                            vehicleLicense: vehicleLicense,
                            userPhoneMap: userPhoneMap
                        )
                    }
                } else {
                    Text("Could not load tracking information")
                }
            }
        }


        .accentColor(.blue)
    }
    
    var filteredTasks: [MaintenanceTask] {
        let filtered: [MaintenanceTask]
        switch selectedSegment {
        case 0:
            filtered = tasks.filter { $0.status == .scheduled && $0.type == .regularMaintenance }
            print("DEBUG: Found \(filtered.count) scheduled regular maintenance tasks out of \(tasks.count) total tasks")
            return filtered

        case 1:
            filtered = tasks.filter { $0.status == .inProgress && $0.type == .regularMaintenance }
            print("DEBUG: Found \(filtered.count) in-progress tasks out of \(tasks.count) total tasks")
            return filtered
        case 2:
            filtered = tasks.filter { $0.status == .completed && $0.type == .regularMaintenance }
            print("DEBUG: Found \(filtered.count) completed tasks out of \(tasks.count) total tasks")
            return filtered
        default:
            print("DEBUG: Invalid segment selection: \(selectedSegment)")
            return []
        }
    }
    
    var filteredSOSTasks: [MaintenanceTask] {
        let filtered: [MaintenanceTask]
        switch sosSelectedSegment {
        case 0: // Pre-inspection
            filtered = sosTasks.filter { $0.type == .preInspectionMaintenance }
            print("DEBUG: Found \(filtered.count) pre-inspection tasks out of \(sosTasks.count) total SOS tasks")
            return filtered
        case 1: // Post-inspection
            filtered = sosTasks.filter { $0.type == .postInspectionMaintenance }
            print("DEBUG: Found \(filtered.count) post-inspection tasks out of \(sosTasks.count) total SOS tasks")
            return filtered
        case 2: // Emergency
            filtered = sosTasks.filter { $0.type == .emergencyMaintenance }
            print("DEBUG: Found \(filtered.count) emergency tasks out of \(sosTasks.count) total SOS tasks")
            return filtered
        default:
            print("DEBUG: Invalid SOS segment selection: \(sosSelectedSegment)")
            return []
        }
    }
    
    func loadTasks() {
        guard let user = user else {
            print("DEBUG: Cannot load tasks - user is nil")
            return
        }
        
        print("DEBUG: Loading tasks for user \(user.id.uuidString) with role \(user.role.rawValue)")
        isLoading = true
        
        Task {
            do {
                print("DEBUG: Making direct API call to get tasks")
                let directTasks = try await RemoteController.shared.getMaintenancePersonnelTasks(by: user.id)
                print("DEBUG: Direct API call returned \(directTasks.count) tasks")
                
                // Only include Regular Maintenance tasks
                let regularTasks = directTasks.filter { task in
                    task.type == .regularMaintenance
                }
                print("DEBUG: Filtered regular maintenance tasks: \(regularTasks.count) out of \(directTasks.count) total tasks")
                
                // Load all vehicle license numbers
                for task in regularTasks {
                    if let vehicle = await dataController.getRegisteredVehicle(by: task.vehicleID) {
                        DispatchQueue.main.async {
                            self.vehicleLicenseMap[task.vehicleID] = vehicle.licenseNumber
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.tasks = regularTasks
                    self.isLoading = false
                }
            } catch {
                print("DEBUG ERROR: Failed to load tasks directly: \(error.localizedDescription)")
                
                // Try to get regular tasks from data controller
                let controllerTasks = dataController.personnelTasks
                let regularTasks = controllerTasks.filter { task in
                    task.type == .regularMaintenance
                }
                
                DispatchQueue.main.async {
                    self.tasks = regularTasks
                    self.isLoading = false
                }
            }
        }
    }
    
    func loadSOSTasks() {
        guard let user = user else {
            print("DEBUG: Cannot load SOS tasks - user is nil")
            return
        }
        
        print("DEBUG: Loading SOS tasks for user \(user.id.uuidString) with role \(user.role.rawValue)")
        isSosLoading = true
        
        Task {
            do {
                print("DEBUG: Making direct API call to get SOS tasks")
                let directTasks = try await RemoteController.shared.getMaintenancePersonnelTasks(by: user.id)
                print("DEBUG: Direct API call returned \(directTasks.count) tasks")
                
                // Load all vehicle license numbers and user phone numbers
                for task in directTasks {
                    if let vehicle = await dataController.getRegisteredVehicle(by: task.vehicleID) {
                        DispatchQueue.main.async {
                            self.vehicleLicenseMap[task.vehicleID] = vehicle.licenseNumber
                        }
                    }
                    
                    if let userData = await dataController.getUserMetaData(by: task.assignedBy) {
                        DispatchQueue.main.async {
                            let phoneNumber = userData.phone  // Access 'phone' directly as a property
                            self.userPhoneMap[task.assignedBy] = phoneNumber
                            self.userNameMap[task.assignedBy] = userData.fullName
                        }
                    }
                }

                // Filter for SOS related tasks (pre-inspection, post-inspection, emergency)
                // Break the complex predicate into simpler logic
                let sosTaskTypes: [MaintenanceTaskType] = [.preInspectionMaintenance, .postInspectionMaintenance, .emergencyMaintenance]
                let sosTasks = directTasks.filter { task in
                    sosTaskTypes.contains(task.type)
                }

                
                DispatchQueue.main.async {
                    self.sosTasks = sosTasks
                    self.isSosLoading = false
                }
            } catch {
                print("DEBUG ERROR: Failed to load SOS tasks directly: \(error.localizedDescription)")
                
                // Try to get SOS tasks from data controller
                let controllerTasks = dataController.personnelTasks.filter {
                    $0.type == .preInspectionMaintenance || $0.type == .postInspectionMaintenance || $0.type == .emergencyMaintenance
                }
                
                DispatchQueue.main.async {
                    self.sosTasks = controllerTasks
                    self.isSosLoading = false
                }
            }
        }
    }
    
    func startWork(task: MaintenanceTask) {
        print("DEBUG: Starting work on task #\(task.taskID)")
        Task {
            // Use dataController.makeMaintenanceTaskInProgress for updating task status
            await dataController.makeMaintenanceTaskInProgress(by: task.id)
            print("DEBUG: Made task in-progress, now reloading tasks")
            await dataController.loadPersonnelTasks() // Reload tasks from data controller
            
            let updatedTasksFromController = dataController.personnelTasks
            
            // Create a mutable copy of the current tasks
            var updatedTasks = self.tasks
            
            // Find and update the specific task in our local array
            if let index = updatedTasks.firstIndex(where: { $0.id == task.id }) {
                updatedTasks[index].status = .inProgress
                print("DEBUG: Updated task status locally")
            }
            
            // Try to get the latest tasks from API
            do {
                let apiTasks = try await RemoteController.shared.getMaintenancePersonnelTasks(by: user?.id ?? UUID())
                print("DEBUG: Reloaded \(apiTasks.count) tasks from API after starting work")
                
                DispatchQueue.main.async {
                    self.tasks = apiTasks
                    
                    // Verify the task status was updated properly in the fetched data
                    if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                        if self.tasks[index].status != .inProgress {
                            print("DEBUG: API returned task with incorrect status, fixing locally")
                            self.tasks[index].status = .inProgress
                        }
                    } else {
                        print("DEBUG: Task not found in API response, using local update")
                        self.tasks = updatedTasks
                    }
                    
                    // Immediately switch to the In Progress tab
                    self.selectedSegment = 1
                    print("DEBUG: Switched to In Progress tab. Tasks count: \(self.tasks.count), Filtered tasks: \(self.filteredTasks.count)")
                }
            } catch {
                print("DEBUG ERROR: Failed to reload tasks from API: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    // Use our already updated tasks array
                    self.tasks = updatedTasks
                    
                    // Immediately switch to the In Progress tab
                    self.selectedSegment = 1
                    print("DEBUG: Switched to In Progress tab (after API error). Tasks count: \(self.tasks.count), Filtered tasks: \(self.filteredTasks.count)")
                }
            }
        }
    }
    
    func updateCompletionDays(days: Int) {
        guard let task = selectedTask else {
            print("DEBUG: Cannot update completion days - selectedTask is nil")
            return
        }
        
        print("DEBUG: Updating completion days for task #\(task.taskID) to \(days) days")
        Task {
            if let date = Calendar.current.date(byAdding: .day, value: days, to: Date()) {
                // Use dataController.updateMaintenanceTaskEstimatedDate for updating completion date
                await dataController.updateMaintenanceTaskEstimatedDate(by: task.id, date)
                print("DEBUG: Updated completion date, now reloading tasks")
                await dataController.loadPersonnelTasks() // Reload tasks from data controller
                
                DispatchQueue.main.async {
                    self.tasks = dataController.personnelTasks
                    print("DEBUG: Reloaded \(self.tasks.count) tasks after updating completion days")
                }
            }
        }
    }
    
    func completeTaskAndGenerateInvoice(task: MaintenanceTask) {
        // Create expense dictionary
        var expenses: [MaintenanceExpenseType: Double] = [:]
        expenses[.laborsCost] = Double(laborCost) ?? 0
        expenses[.partsCost] = Double(partsCost) ?? 0
        expenses[.otherCost] = Double(otherCost) ?? 0
        
        Task {
            // 1. Update task with expenses and repair note
            await dataController.createInvoiceForMaintenanceTask(by: task.id, expenses: expenses, repairNote)
            
            await dataController.loadPersonnelTasks()
            
            // 4. Try to generate invoice
            if let updatedTask = dataController.personnelTasks.first(where: { $0.id == task.id }),
               let invoice = await updatedTask.generateInvoice() {
                DispatchQueue.main.async {
                    self.generatedInvoice = invoice
                    self.showingInvoiceSheet = false
                    self.showingInvoicePreview = true
                }
            } else {
                print("Failed to generate invoice")
            }
            
            // 5. Update local tasks list
            DispatchQueue.main.async {
                self.tasks = dataController.personnelTasks
            }
        }
    }
}

struct MaintenanceTaskCard: View {
    let task: MaintenanceTask
    let vehicleLicense: String?
    let onStartWork: () -> Void
    let onDaysSelected: (Int) -> Void
    let onCreateInvoice: () -> Void
    @State private var completionDays = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Common header for all card types
            HStack {
                if let license = vehicleLicense {
                    Text("Vehicle: \(license)")
                        .font(.headline)
                } else {
                    Text("Vehicle ID: \(task.vehicleID)")
                        .font(.headline)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    
                    Text(task.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.top, 5)
            
            Text("Task ID: \(task.taskID)")
                .foregroundColor(.secondary)
            
            HStack(spacing: 5) {
                Image(systemName: "wrench.fill")
                    .foregroundColor(.blue)
                Text(task.type.rawValue)
                    .foregroundColor(.secondary)
            }
            
            // Content specific to status
            if task.status == .scheduled {
                scheduledTaskContent
            } else if task.status == .inProgress {
                inProgressTaskContent
            } else if task.status == .completed {
                completedTaskContent
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    // UI for scheduled tasks
    private var scheduledTaskContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Estimated Date: \(task.estimatedCompletionDate?.formatted(.dateTime.day().month(.abbreviated).year()) ?? "Not Set")")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Complete in:")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    ForEach(1...7, id: \.self) { day in
                        Button(action: {
                            completionDays = day
                            onDaysSelected(day)
                        }) {
                            HStack {
                                Text("\(day) day\(day > 1 ? "s" : "")")
                                
                                Spacer()
                                
                                if day == completionDays {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("\(completionDays) day\(completionDays > 1 ? "s" : "")")
                            .foregroundColor(.primary)
                        
                        Spacer(minLength: 8)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 5)
            
            Button(action: onStartWork) {
                Text("Start Work")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.top, 5)
        }
    }
    
    // UI for in-progress tasks
    private var inProgressTaskContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Due: \(task.estimatedCompletionDate?.formatted(.dateTime.day().month(.abbreviated).year()) ?? "Not Set")")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Button(action: onCreateInvoice) {
                    Text("Create Invoice")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 5)
        }
    }
    
    // UI for completed tasks
    private var completedTaskContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let completionDate = task.completionDate {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Completed: \(completionDate.formatted(.dateTime.day().month(.abbreviated).year()))")
                        .foregroundColor(.secondary)
                }
            }
            
            // Show expenses if available
            if let expenses = task.expenses, !expenses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cost Breakdown:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(Array(expenses.keys), id: \.self) { key in
                            if let value = expenses[key], value > 0 {
                                HStack {
                                    Text(key.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("₹\(value, specifier: "%.2f")")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    HStack {
                        Text("Total")
                            .fontWeight(.medium)
                        Spacer()
                        Text("₹\(totalExpense, specifier: "%.2f")")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 5)
                }
                .padding(.top, 5)
            }
        }
    }
    
    // Helper computed properties
    private var statusColor: Color {
        switch task.status {
        case .scheduled:
            return .blue
        case .inProgress:
            return .orange
        case .completed:
            return .green
        }
    }
    
    private var totalExpense: Double {
        guard let expenses = task.expenses else { return 0 }
        return expenses.values.reduce(0, +)
    }
}

struct SOSTaskCard: View {
    let task: MaintenanceTask
    let vehicleLicense: String?
    let assignerPhone: String?
    let assignerName: String?
    let onTrack: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Common header for all card types
            HStack {
                if let license = vehicleLicense {
                    Text("Vehicle: \(license)")
                        .font(.headline)
                } else {
                    Text("Vehicle ID: \(task.vehicleID)")
                        .font(.headline)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(typeColor)
                        .frame(width: 10, height: 10)
                    
                    Text(task.type.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(typeColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(typeColor.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.top, 5)
            
            Text("Task ID: \(task.taskID)")
                .foregroundColor(.secondary)
            
            if let name = assignerName {
                HStack(spacing: 5) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("Driver: \(name)")
                        .foregroundColor(.secondary)
                }
            }
            
            if let phone = assignerPhone {
                HStack(spacing: 5) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.green)
                    Text("Contact: \(phone)")
                        .foregroundColor(.secondary)
                }
            }
            
            if let date = task.estimatedCompletionDate {
                HStack(spacing: 5) {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("Due: \(date.formatted(.dateTime.day().month(.abbreviated).year()))")
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            HStack(spacing: 10) {
                Button(action: {
                    // Connect functionality would go here
                }) {
                    Text("Connect")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Button(action: onTrack) {
                    Text("Track")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(typeColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var typeColor: Color {
        switch task.type {
        case .preInspectionMaintenance:
            return .blue
        case .postInspectionMaintenance:
            return .orange
        case .emergencyMaintenance:
            return .red
        default:
            return .gray
        }
    }
}

struct InvoicePreviewView: View {
    let invoice: Invoice
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text("INVOICE")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Date: \(invoice.createdAt.formatted(.dateTime.day().month().year()))")
                            Text("Invoice #: INV-\(invoice.taskID)")
                        }
                    }
                    .padding(.bottom)
                    
                    // Vehicle Information
                    Group {
                        Text("Vehicle Details")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Vehicle lN: \(invoice.vehicleLicenseNumber)")
                                Text("Service Type: \(invoice.type.rawValue)")
                                Text("Task ID: \(invoice.taskID)")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Costs
                    Group {
                        Text("Cost Breakdown")
                            .font(.headline)
                        
                        VStack(spacing: 15) {
                            ForEach(Array(invoice.expenses.keys), id: \.self) { key in
                                if let value = invoice.expenses[key] {
                                    HStack {
                                        Text(key.rawValue)
                                        Spacer()
                                        Text("₹\(value, specifier: "%.2f")")
                                    }
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text("₹\(invoice.totalExpense, specifier: "%.2f")")
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total")
                                    .fontWeight(.bold)
                                Spacer()
                                let finalAmount = invoice.totalExpense * 1.18
                                Text("₹\(finalAmount, specifier: "%.2f")")
                                    .fontWeight(.bold)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Notes
                    Group {
                        Text("Issue Description")
                            .font(.headline)
                        
                        Text(invoice.issueNote.isEmpty ? "No issue description provided" : invoice.issueNote)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Text("Repair Notes")
                            .font(.headline)
                        
                        Text(invoice.repairNote.isEmpty ? "No repair notes provided" : invoice.repairNote)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Footer
                    VStack(alignment: .center, spacing: 5) {
                        Text("Thank you for your business")
                            .font(.headline)
                        Text("Fleet Management System")
                            .font(.subheadline)
                        Text("Contact: vk092731@gmail.com")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Invoice Preview")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct MaintenanceTabView: View {
    @Binding var selectedSegment: Int
    let isLoading: Bool
    let filteredTasks: [MaintenanceTask]
    let vehicleLicenseMap: [Int: String]
    let onShowProfile: () -> Void
    let onSelectTask: (MaintenanceTask) -> Void
    let onStartWork: (MaintenanceTask) -> Void
    let onUpdateCompletionDays: (MaintenanceTask, Int) -> Void
    let onCreateInvoice: (MaintenanceTask) -> Void

    //  Computed property for categoryName
    var categoryName: String {
        switch selectedSegment {
        case 0: return "Assigned"
        case 1: return "In Progress"
        default: return "Completed"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Maintenance")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: onShowProfile) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundColor(.blue)
                        .padding(.trailing)
                }
            }
            .padding(.bottom, 10)
            .padding(.top, 70)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 45)
                
                HStack(spacing: 0) {
                    SegmentButton(text: "Assigned", isSelected: selectedSegment == 0) {
                        selectedSegment = 0
                    }
                    
//                    SegmentButton(text: "In Progress", isSelected: selectedSegment == 1) {
//                        selectedSegment = 1
//                    }
//                    
//                    SegmentButton(text: "Completed", isSelected: selectedSegment == 2) {
//                        selectedSegment = 2
//                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredTasks.isEmpty {
                            Text("No tasks available")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            ForEach(filteredTasks) { task in
                                MaintenanceTaskCard(
                                    task: task,
                                    vehicleLicense: vehicleLicenseMap[task.vehicleID],
                                    onStartWork: {
                                        onStartWork(task)
                                    },
                                    onDaysSelected: { days in
                                        onUpdateCompletionDays(task, days)
                                    },
                                    onCreateInvoice: {
                                        onCreateInvoice(task)
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SOSTabView: View {
    @Binding var sosSelectedSegment: Int
    let isSosLoading: Bool
    let filteredSOSTasks: [MaintenanceTask]
    let vehicleLicenseMap: [Int: String]
    let userPhoneMap: [UUID: String]
    let userNameMap: [UUID: String]
    let onShowProfile: () -> Void
    let onTrackTask: (MaintenanceTask) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Title
            HStack {
                Text("SOS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: onShowProfile) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundColor(.blue)
                        .padding(.trailing)
                }
            }
            .padding(.bottom, 10)
            .padding(.top, 70)
            
            // Segment Controller for SOS
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemGray5))
                    .frame(height: 45)
                
                HStack(spacing: 0) {
                    SegmentButton(text: "Pre-inspect", isSelected: sosSelectedSegment == 0) {
                        sosSelectedSegment = 0
                    }
                    
                    SegmentButton(text: "Post-inspect", isSelected: sosSelectedSegment == 1) {
                        sosSelectedSegment = 1
                    }
                    
//                    SegmentButton(text: "Emergency", isSelected: sosSelectedSegment == 2) {
//                        sosSelectedSegment = 2
//                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            
            if isSosLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if filteredSOSTasks.isEmpty {
                            Text("No tasks available")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            ForEach(filteredSOSTasks) { task in
                                SOSTaskCard(
                                    task: task,
                                    vehicleLicense: vehicleLicenseMap[task.vehicleID],
                                    assignerPhone: userPhoneMap[task.assignedBy],
                                    assignerName: userNameMap[task.assignedBy],
                                    onTrack: {
                                        onTrackTask(task)
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SegmentButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.headline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .black : .gray)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .padding(4)
                        }
                    }
                )
        }
    }
}

struct LocationTrackingView: View {
    let task: MaintenanceTask
    let vehicleLicense: String?
    let userPhoneMap: [UUID: String]
    @Environment(\.dismiss) var dismiss
    @State private var vehicleLocation: CLLocationCoordinate2D?
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var vehicleAddress: String = "Fetching address..."
    @State private var region = MKCoordinateRegion()
    @State private var isLoadingLocation = true
    @State private var driverName: String = "Loading..."
    
    // DataController reference
    private let dataController = IFEDataController.shared
    
    var body: some View {
        ZStack {
            // Map View
            if let vehicleLocation = vehicleLocation {
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: [AnnotationItem(coordinate: vehicleLocation, title: vehicleLicense ?? "Vehicle")]) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        VStack {
                            Text(item.title)
                                .font(.caption)
                                .padding(4)
                                .background(Color.white)
                                .cornerRadius(4)
                            
                            Image(systemName: "car.fill")
                                .foregroundColor(.red)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)
            } else {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                    .overlay {
                        if isLoadingLocation {
                            ProgressView("Loading location...")
                        } else {
                            Text("Could not load vehicle location")
                        }
                    }
            }
            
            // Bottom Panel
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.blue)
                        
                        Text(vehicleLicense ?? "Vehicle \(task.vehicleID)")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(alertTypeColor)
                                .frame(width: 10, height: 10)
                            
                            Text(task.type.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(alertTypeColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                                Text("Driver: \(driverName)")
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.gray)
                                Text(vehicleAddress)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                            
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(task.issueNote)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                        }
                    }
                    
                    HStack(spacing: 20) {
                        Button(action: getDirections) {
                            Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: centerMap) {
                            Label("Center", systemImage: "scope")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
                .padding()
            }
        }
        .navigationTitle("Location Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("Close") {
            dismiss()
        })
        .onAppear {
            fetchVehicleLocation()
            getUserLocation()
            fetchDriverName()
        }
    }
    
    private var alertTypeColor: Color {
        switch task.type {
        case .preInspectionMaintenance:
            return .blue
        case .postInspectionMaintenance:
            return .orange
        case .emergencyMaintenance:
            return .red
        default:
            return .gray
        }
    }
    
    private func fetchVehicleLocation() {
        isLoadingLocation = true
        
        Task {
            if let vehicle = await dataController.getRegisteredVehicle(by: task.vehicleID) {
                let coordinateStrings = vehicle.currentCoordinate.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                
                if coordinateStrings.count == 2, 
                   let latitude = Double(coordinateStrings[0]), 
                   let longitude = Double(coordinateStrings[1]) {
                    
                    DispatchQueue.main.async {
                        self.vehicleLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        self.centerMap()
                        self.isLoadingLocation = false
                        self.fetchAddress(from: vehicle.currentCoordinate)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoadingLocation = false
                }
            }
        }
    }
    
    private func getUserLocation() {
        // This would use CoreLocation's CLLocationManager in a real implementation
        // For this example, we'll set a default location
        self.userLocation = CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090) // Default Delhi location
    }
    
    private func fetchAddress(from coordinate: String) {
        getAddress(from: coordinate) { address in
            if let address = address {
                DispatchQueue.main.async {
                    self.vehicleAddress = address
                }
            } else {
                DispatchQueue.main.async {
                    self.vehicleAddress = "Address not available"
                }
            }
        }
    }
    
    private func fetchDriverName() {
        Task {
            // First try to get user metadata for the person who assigned this task
            if let userData = await dataController.getUserMetaData(by: task.assignedBy) {
                DispatchQueue.main.async {
                    self.driverName = userData.fullName
                }
            } else {
                // If no user metadata is found, check if we have a phone number
                if let phone = userPhoneMap[task.assignedBy] {
                    DispatchQueue.main.async {
                        self.driverName = "Driver (Contact: \(phone))"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.driverName = "Unknown Driver"
                    }
                }
            }
        }
    }
    
    private func centerMap() {
        if let location = vehicleLocation {
            self.region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func getDirections() {
        if let location = vehicleLocation {
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: location))
            mapItem.name = vehicleLicense ?? "Vehicle Location"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
    }
}

// Helper struct for the map annotation
struct AnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
}
