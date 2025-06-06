//
//  MaintenancePersonnel.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 19/03/25.
//

import Foundation
import SwiftUI
import MapKit
import PDFKit

struct MaintenanceView: View {
    @Binding var user: AppUser?
    @Binding var role: Role?
    @State private var selectedTab = 0 // 0 for Maintenance, 1 for sos
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
    @State private var isLoadingInvoice = false
    @State private var viewRefreshTrigger = UUID() // Add refresh trigger for views
    @State private var isInvoiceFormLoading = false // New state for invoice form loading
    @State private var isInvoiceGenerating = false // Add new state
    @State private var isRefreshing = false // Add state for pull-to-refresh
    
    // Reference to data controllers
    private let dataController = IFEDataController.shared
    
    // Add computed property for total cost
    private var totalCost: Double {
        let laborAmount = Double(laborCost) ?? 0
        let partsAmount = Double(partsCost) ?? 0
        let otherAmount = Double(otherCost) ?? 0
        return laborAmount + partsAmount + otherAmount
    }
    
    // Check if any cost has been entered
    private var hasAnyCostEntered: Bool {
        let laborAmount = Double(laborCost) ?? 0
        let partsAmount = Double(partsCost) ?? 0
        let otherAmount = Double(otherCost) ?? 0
        return laborAmount > 0 || partsAmount > 0 || otherAmount > 0
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
                    self.isInvoiceFormLoading = true
                    self.selectedTask = task
                    self.showingInvoiceSheet = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.isInvoiceFormLoading = false
                    }
                },
                onRefresh: {
                    self.isRefreshing = true
                    self.refreshAllTasks()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.isRefreshing = false
                    }
                },
                isRefreshing: isRefreshing
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
                },
                onRefresh: {
                    self.isRefreshing = true
                    self.refreshAllTasks()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.isRefreshing = false
                    }
                },
                isRefreshing: isRefreshing
            )
            .edgesIgnoringSafeArea(.top)
            .tabItem {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("SOS")
            }
            .tag(1)
        }
        .accentColor(.primaryGradientEnd)
        .onAppear {
            // Set the TabView appearance to match iOS design
            UITabBar.appearance().backgroundColor = .systemBackground
            
            // Debug print for user details
            print("DEBUG: User ID: \(user?.id.uuidString ?? "nil"), Role: \(user?.role.rawValue ?? "nil")")
            
            loadTasks()
            loadSOSTasks()
        }
        .onChange(of: selectedTab) { newTab in
            // Force reload when switching to SOS tab
            if newTab == 1 {
                loadSOSTasks()
                print("DEBUG: Forced reload of SOS tasks when switching to SOS tab")
            }
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
            NavigationView {
                if isInvoiceFormLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .font(.headline)
                            .padding(.top, 20)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
                } else if let task = selectedTask {
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
                            Button(action: {
                                completeTaskAndGenerateInvoice(task: task)
                            }) {
                                if isLoadingInvoice {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("Generating Invoice...")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                } else {
                                    Text("Complete Task & Generate Invoice")
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(hasAnyCostEntered ? Color.primaryGradientStart : Color.primaryGradientStart.opacity(0.5))
                            .cornerRadius(8)
                            .disabled(!hasAnyCostEntered || isLoadingInvoice)
                        }
                    }
                    .navigationTitle("Create Invoice")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingInvoiceSheet = false
                    }
                    .foregroundColor(.primaryGradientStart))
                    .disabled(isLoadingInvoice)
                } else {
                    Text("No task selected")
                }
            }
        }
        .sheet(isPresented: $showingInvoicePreview) {
            if let invoice = generatedInvoice {
                LoadingInvoicePreview(invoice: invoice)
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
        
        // Print all tasks with their statuses before filtering
        print("DEBUG: All SOS tasks before filtering:")
        for task in sosTasks {
            print("  SOS Task ID: \(task.id), Type: \(task.type.rawValue), Status: \(task.status.rawValue)")
        }
        
        switch sosSelectedSegment {
        case 0: // Pre-inspection
            filtered = sosTasks.filter { $0.type == .preInspectionMaintenance }
            print("DEBUG: Found \(filtered.count) pre-inspection tasks out of \(sosTasks.count) total SOS tasks")
            
            // Print filtered tasks
            for task in filtered {
                print("  Filtered Pre-inspection Task: ID: \(task.id), Status: \(task.status.rawValue)")
            }
            
            return filtered
        case 1: // Post-inspection
            filtered = sosTasks.filter { $0.type == .postInspectionMaintenance }
            print("DEBUG: Found \(filtered.count) post-inspection tasks out of \(sosTasks.count) total SOS tasks")
            
            // Print filtered tasks
            for task in filtered {
                print("  Filtered Post-inspection Task: ID: \(task.id), Status: \(task.status.rawValue)")
            }
            
            return filtered
        case 2: // Emergency
            filtered = sosTasks.filter { $0.type == .emergencyMaintenance }
            print("DEBUG: Found \(filtered.count) emergency tasks out of \(sosTasks.count) total SOS tasks")
            
            // Print filtered tasks
            for task in filtered {
                print("  Filtered Emergency Task: ID: \(task.id), Status: \(task.status.rawValue)")
            }
            
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
                print("DEBUG: Making direct API call to get SOS tasks from Supabase")
                
                // Force reload from Supabase - ensure no cached data is used
                try await dataController.loadPersonnelTasks()
                
                // Get tasks directly from the fresh data in dataController
                let directTasks = dataController.personnelTasks
                print("DEBUG: Direct API call returned \(directTasks.count) tasks from Supabase")
                
                // Load all vehicle license numbers and user phone numbers
                for task in directTasks {
                    print("DEBUG: Task ID: \(task.id), Status: \(task.status.rawValue), Type: \(task.type.rawValue)")
                    
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
                print("DEBUG: Filtered SOS tasks: \(sosTasks.count) out of \(directTasks.count) total tasks")
                
                // Print status distribution to help diagnose issues
                let scheduled = sosTasks.filter { $0.status == .scheduled }.count
                let inProgress = sosTasks.filter { $0.status == .inProgress }.count
                let completed = sosTasks.filter { $0.status == .completed }.count
                print("DEBUG: SOS task status breakdown - Scheduled: \(scheduled), In Progress: \(inProgress), Completed: \(completed)")
                
                DispatchQueue.main.async {
                    // Clear existing tasks before updating to prevent stale data
                    self.sosTasks.removeAll()
                    
                    // Assign the fresh tasks from Supabase
                    self.sosTasks = sosTasks
                    self.isSosLoading = false
                    print("DEBUG: SOS tasks updated, isSosLoading set to false")
                    
                    // Reset the view refresh trigger to force UI update
                    self.viewRefreshTrigger = UUID()
                }
            } catch {
                print("DEBUG ERROR: Failed to load SOS tasks directly: \(error.localizedDescription)")
                
                // Try to get fresh tasks again with a different approach
                Task {
                    do {
                        // Try to directly fetch from RemoteController as a backup
                        print("DEBUG: Attempting direct fetch from RemoteController")
                        let backupTasks = try await RemoteController.shared.getMaintenancePersonnelTasks(by: user.id)
                        
                        let sosTaskTypes: [MaintenanceTaskType] = [.preInspectionMaintenance, .postInspectionMaintenance, .emergencyMaintenance]
                        let sosTasks = backupTasks.filter { sosTaskTypes.contains($0.type) }
                        
                        DispatchQueue.main.async {
                            self.sosTasks = sosTasks
                            self.isSosLoading = false
                            print("DEBUG: SOS tasks updated from direct RemoteController fetch, count: \(sosTasks.count)")
                            self.viewRefreshTrigger = UUID()
                        }
                    } catch {
                        print("DEBUG: Both fetch methods failed. Using cached data as last resort.")
                        // Only use cached data as a last resort
                        let controllerTasks = dataController.personnelTasks.filter {
                            $0.type == .preInspectionMaintenance || $0.type == .postInspectionMaintenance || $0.type == .emergencyMaintenance
                        }
                        
                        DispatchQueue.main.async {
                            self.sosTasks = controllerTasks
                            self.isSosLoading = false
                            print("DEBUG: SOS tasks updated from cached data, isSosLoading set to false")
                            self.viewRefreshTrigger = UUID()
                        }
                    }
                }
            }
        }
    }
    
    func startWork(task: MaintenanceTask) {
        print("DEBUG: Starting work on task #\(task.taskID)")
        
        // Modify task status directly on main thread to ensure UI updates
        DispatchQueue.main.async {
            // 1. First create a modified task with the new status and estimated completion date
            var updatedTask = task
            updatedTask.status = .inProgress
            updatedTask.estimatedCompletionDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            
            // 2. Find and replace the existing task in the array
            var newTasks = self.tasks.filter { $0.id != task.id }
            newTasks.append(updatedTask)
            
            // 3. Update the tasks array with the new collection
            self.tasks = newTasks
            
            // 4. Generate a new refresh trigger to force UI updates
            self.viewRefreshTrigger = UUID()
            
            print("DEBUG: Local task status updated to .inProgress. Task count: \(self.tasks.count)")
            
            // 5. Log the status of all tasks to verify
            for t in self.tasks {
                print("DEBUG: Task #\(t.taskID) status: \(t.status.rawValue)")
            }
            
            // 6. Immediately switch to In Progress tab to show the updated task
            self.selectedSegment = 1
            
            // 7. Log filtered tasks to verify they're being updated correctly
            let inProgressTasks = self.tasks.filter { $0.status == .inProgress && $0.type == .regularMaintenance }
            print("DEBUG: Number of tasks with .inProgress status: \(inProgressTasks.count)")
            
            // 8. Force a UI update after a short delay to ensure everything is processed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.viewRefreshTrigger = UUID()
            }
        }
        
        // Update the server in the background
        Task {
            do {
                // Update both status and estimated completion date
                await dataController.makeMaintenanceTaskInProgress(by: task.id)
                if let date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
                    await dataController.updateMaintenanceTaskEstimatedDate(by: task.id, date)
                }
                print("DEBUG: Task status and estimated date updated on server")
                
                // Refresh data from server
                await dataController.loadPersonnelTasks()
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    // Create a new array with server data but ensure our task is properly updated
                    var refreshedTasks = dataController.personnelTasks
                    
                    // Double-check that our task has the correct status and estimated date
                    if let idx = refreshedTasks.firstIndex(where: { $0.id == task.id }) {
                        if refreshedTasks[idx].status != .inProgress {
                            print("DEBUG: Fixing task status from server data")
                            refreshedTasks[idx].status = .inProgress
                            refreshedTasks[idx].estimatedCompletionDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                        }
                    } else {
                        // If task isn't in refreshed data, keep our modified version
                        print("DEBUG: Task not found in server data, preserving local change")
                        let updatedTask = task
                        var localCopy = updatedTask
                        localCopy.status = .inProgress
                        localCopy.estimatedCompletionDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                        refreshedTasks.append(localCopy)
                    }
                    
                    // Update tasks and force refresh
                    self.tasks = refreshedTasks
                    self.viewRefreshTrigger = UUID()
                    
                    // Keep the In Progress tab selected
                    self.selectedSegment = 1
                }
            } catch {
                print("DEBUG ERROR: Failed to update task status on server: \(error.localizedDescription)")
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
        // Set loading state
        isLoadingInvoice = true
        
        // Create expense dictionary
        var expenses: [MaintenanceExpenseType: Double] = [:]
        expenses[.laborsCost] = Double(laborCost) ?? 0
        expenses[.partsCost] = Double(partsCost) ?? 0
        expenses[.otherCost] = Double(otherCost) ?? 0
        
        Task {
            do {
                // 1. Update task with expenses and repair note
                await dataController.createInvoiceForMaintenanceTask(by: task.id, expenses: expenses, repairNote)
                
                // 2. Reload tasks to get updated data
                await dataController.loadPersonnelTasks()
                
                // 3. Find the updated task
                if let updatedTask = dataController.personnelTasks.first(where: { $0.id == task.id }) {
                    // 4. Generate invoice
                    if let invoice = await updatedTask.generateInvoice() {
                        DispatchQueue.main.async {
                            self.generatedInvoice = invoice
                            self.showingInvoiceSheet = false
                            
                            // Small delay before showing preview
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.isLoadingInvoice = false
                                self.showingInvoicePreview = true
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isLoadingInvoice = false
                            print("DEBUG: Failed to generate invoice - invoice generation returned nil")
                        }
                    }
                    
                    // 5. Update local task status
                    DispatchQueue.main.async {
                        // Update the status of the task in our local array
                        if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                            var updatedLocalTask = self.tasks[index]
                            updatedLocalTask.status = .completed
                            updatedLocalTask.completionDate = Date()
                            
                            // Replace the task in the array
                            self.tasks.remove(at: index)
                            self.tasks.append(updatedLocalTask)
                            
                            // Update view to reflect changes
                            self.viewRefreshTrigger = UUID()
                            
                            // Switch to Completed segment after a small delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                self.selectedSegment = 2 // Switch to Completed segment
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoadingInvoice = false
                        print("DEBUG: Failed to find updated task after completion")
                    }
                }
                
                // 6. Update local tasks list with data from server
                DispatchQueue.main.async {
                    self.tasks = dataController.personnelTasks
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingInvoice = false
                    print("DEBUG ERROR: Error completing task and generatinxg invoice: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Add a new method for refreshing all tasks
    func refreshAllTasks() {
        // Only refresh if we're not already loading
        if !isLoading && !isSosLoading {
            loadTasks()
            loadSOSTasks()
            
            // Add a delay to allow the tasks to load before printing
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("DEBUG: REFRESH RESULTS - SOS Tasks Array Contents: ")
                for (index, task) in self.sosTasks.enumerated() {
                    print("  Task[\(index)]: ID: \(task.id), Type: \(task.type.rawValue), Status: \(task.status.rawValue), VehicleID: \(task.vehicleID)")
                }
                print("DEBUG: Total SOS Tasks after refresh: \(self.sosTasks.count)")
                
                // Print filtered tasks based on current segment
                let filtered = self.filteredSOSTasks
                print("DEBUG: Filtered SOS Tasks for segment \(self.sosSelectedSegment): \(filtered.count)")
                for (index, task) in filtered.enumerated() {
                    print("  Filtered[\(index)]: ID: \(task.id), Type: \(task.type.rawValue), Status: \(task.status.rawValue)")
                }
            }
        }
    }
}

// Keep MaintenanceTabView and other maintenance-related views
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
    let onRefresh: () -> Void
    let isRefreshing: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with fixed size and constrained font size
            HStack {
                Text("Maintenance")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGradientStart)
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .frame(width: 20, height: 22)
                        .foregroundColor(.primaryGradientStart)
                }
                .padding(.trailing, 10)
                
                Button(action: onShowProfile) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 35, height: 35)
                        .foregroundColor(.primaryGradientStart)
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
            .padding(.bottom, 15)
            
            // Segment control styled to match the reference image
            ZStack(alignment: .top) {
                // Background pill
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color(.systemGray6))
                    .frame(height: 48) // Reduced height from 56
                    .padding(.horizontal)
                
                HStack(spacing: 0) {
                    // Assigned Tab
                    Button(action: { selectedSegment = 0 }) {
                        VStack {
                            Text("Assigned")
                                .font(.system(size: 14, weight: selectedSegment == 0 ? .semibold : .regular)) // Reduced font size
                                .foregroundColor(selectedSegment == 0 ? .white : .black)
                                .padding(.vertical, 12) // Reduced padding
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedSegment == 0 ?
                                        RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.primaryGradientStart)
                                        : RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }
                    
                    // In Progress Tab
                    Button(action: { selectedSegment = 1 }) {
                        VStack {
                            Text("In Progress")
                                .font(.system(size: 14, weight: selectedSegment == 1 ? .semibold : .regular)) // Reduced font size
                                .foregroundColor(selectedSegment == 1 ? .white : .black)
                                .padding(.vertical, 12) // Reduced padding
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedSegment == 1 ?
                                        RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.primaryGradientStart)
                                        : RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }
                    
                    // Completed Tab
                    Button(action: { selectedSegment = 2 }) {
                        VStack {
                            Text("Completed")
                                .font(.system(size: 14, weight: selectedSegment == 2 ? .semibold : .regular)) // Reduced font size
                                .foregroundColor(selectedSegment == 2 ? .white : .black)
                                .padding(.vertical, 12) // Reduced padding
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedSegment == 2 ?
                                        RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.primaryGradientStart)
                                        : RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 10)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    PullToRefresh(coordinateSpaceName: "pullToRefresh", onRefresh: onRefresh, isRefreshing: isRefreshing)
                    
                    LazyVStack(spacing: 16) {
                        if filteredTasks.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "wrench.and.screwdriver")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.primaryGradientStart.opacity(0.6))
                                
                                Text("No tasks available")
                                    .font(.headline)
                                    .foregroundColor(.primaryGradientStart)
                                
                                Text("You don't have any tasks at the moment")
                                    .font(.subheadline)
                                    .foregroundColor(.primaryGradientStart.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color.white.opacity(0.7))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            ForEach(filteredTasks, id: \.id) { task in
                                MaintenanceTaskCardV(
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
                                .id("\(task.id)-\(task.status.rawValue)")
                            }
                        }
                    }
                    .padding()
                }
                .coordinateSpace(name: "pullToRefresh")
                .id(selectedSegment)
            }
        }
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
    }
}

// Add PullToRefresh view for the pull-to-refresh functionality
struct PullToRefresh: View {
    var coordinateSpaceName: String
    var onRefresh: () -> Void
    var isRefreshing: Bool
    
    @State private var refresh: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: .named(coordinateSpaceName)).minY > 50 && !isRefreshing {
                Spacer()
                    .onAppear {
                        onRefresh()
                    }
            } else if isRefreshing {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
            ZStack(alignment: .center) {
                if geo.frame(in: .named(coordinateSpaceName)).minY > 0 && !isRefreshing {
                    ProgressView()
                        .offset(y: -25)
                }
            }
            .frame(width: geo.size.width)
        }
        .padding(.top, -50)
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
        }
        .foregroundColor(.primaryGradientStart))
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

// New loading wrapper view for invoice preview
struct LoadingInvoicePreview: View {
    let invoice: Invoice
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                NavigationView {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(2)
                        Text("Preparing Invoice...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Invoice Preview")
                    .navigationBarTitleDisplayMode(.inline)
                }
            } else {
                InvoicePreviewView(invoice: invoice)
            }
        }
        .onAppear {
            // Add a delay to ensure proper loading state is shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

// Update InvoicePreviewView to remove loading state
struct InvoicePreviewView: View {
    let invoice: Invoice
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text("INVOICE")
                            .font(.title2)
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
                                Text("₹\(invoice.totalExpense, specifier: "%.2f")")
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
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Invoice Preview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            }
            .foregroundColor(.primaryGradientStart))
        }
    }
}

struct MaintenanceTaskCardV: View {
    let task: MaintenanceTask
    let vehicleLicense: String?
    let onStartWork: () -> Void
    let onDaysSelected: (Int) -> Void
    let onCreateInvoice: () -> Void
    @State private var completionDays = 1
    @State private var showingInvoicePreview = false
    @State private var generatedInvoice: Invoice?
    @State private var isLoadingInvoice = false  // Add loading state
    @State private var refreshID = UUID() // Add for immediate UI refresh
    @State private var temporaryEstimatedDate: Date? = nil // For immediate UI update
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Common header for all card types
            HStack {
                if let license = vehicleLicense {
                    Text("\(license)")
                        .font(.subheadline)
                        .foregroundColor(.statusOrange)
                } else {
                    Text("Vehicle ID: \(task.vehicleID)")
                        .font(.subheadline)
                        .foregroundColor(.primaryGradientStart)
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
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 5) {
                Image(systemName: "wrench.fill")
                    .foregroundColor(.primaryGradientStart)
                Text(task.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .id(refreshID) // Force refresh when refreshID changes
        .onAppear {
            // Calculate completionDays from task.estimatedCompletionDate when the view appears
            if let estimatedDate = task.estimatedCompletionDate {
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let estimatedDay = calendar.startOfDay(for: estimatedDate)
                
                if let days = calendar.dateComponents([.day], from: today, to: estimatedDay).day {
                    // Clamp between 1-7 days
                    let clampedDays = max(1, min(7, days))
                    if clampedDays != completionDays {
                        self.completionDays = clampedDays
                        print("DEBUG: Set completionDays to \(clampedDays) based on estimated date \(estimatedDate)")
                    }
                }
            }
        }
    }
    
    // UI for scheduled tasks
    private var scheduledTaskContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .foregroundColor(.primaryGradientStart)
                
                let displayDate = temporaryEstimatedDate ?? task.estimatedCompletionDate
                Text("Estimated Date: \(displayDate?.formatted(.dateTime.day().month(.abbreviated).year()) ?? "Not Set")")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .id("est-date-\(displayDate?.timeIntervalSince1970 ?? 0)")
            }
            
            HStack {
                Text("Complete in:")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Menu {
                    ForEach(1...7, id: \.self) { day in
                        Button(action: {
                            completionDays = day
                            temporaryEstimatedDate = Calendar.current.date(byAdding: .day, value: day, to: Date())
                            refreshID = UUID()
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
                }
                label: {
                    HStack {
                        Text("\(completionDays) day\(completionDays > 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer(minLength: 8)
                        
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white)
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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primaryGradientStart)
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
                    .foregroundColor(.primaryGradientStart)
                Text("Due: \(task.estimatedCompletionDate?.formatted(.dateTime.day().month(.abbreviated).year()) ?? "Not Set")")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
            
            HStack {
                Button(action: onCreateInvoice) {
                    Text("Create Invoice")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.primaryGradientStart)
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
                        .foregroundColor(.statusGreen)
                    Text("Completed: \(completionDate.formatted(.dateTime.day().month(.abbreviated).year()))")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Button(action: {
                isLoadingInvoice = true
                Task {
                    do {
                        if let invoice = await task.generateInvoice() {
                            DispatchQueue.main.async {
                                self.generatedInvoice = invoice
                                self.isLoadingInvoice = false
                                self.showingInvoicePreview = true
                            }
                        } else {
                            print("DEBUG: Failed to generate invoice for task ID: \(task.taskID)")
                            DispatchQueue.main.async {
                                self.isLoadingInvoice = false
                            }
                        }
                    } catch {
                        print("DEBUG: Error generating invoice: \(error)")
                        DispatchQueue.main.async {
                            self.isLoadingInvoice = false
                        }
                    }
                }
            }) {
                HStack {
                    if isLoadingInvoice {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .padding(.trailing, 5)
                    } else {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.white)
                    }
                    Text(isLoadingInvoice ? "Loading..." : "View Invoice")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.primaryGradientStart)
                .cornerRadius(8)
            }
            .disabled(isLoadingInvoice)
            .padding(.top, 5)
            .sheet(isPresented: $showingInvoicePreview) {
                if let invoice = generatedInvoice {
                    InvoicePreviewView(invoice: invoice)
                } else {
                    Text("Could not load invoice")
                        .padding()
                }
            }
        }
    }
    
    // Helper computed properties
    private var statusColor: Color {
        switch task.status {
        case .scheduled:
            return .statusOrange
        case .inProgress:
            return .primaryGradientStart
        case .completed:
            return .statusGreen
        }
    }
    
    private var totalExpense: Double {
        guard let expenses = task.expenses else { return 0 }
        return expenses.values.reduce(0, +)
    }
}
