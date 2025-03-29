//
//  MaintenancePersonnel.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 19/03/25.
//

import Foundation
import SwiftUI

import PDFKit  // For PDF generation

struct MaintenanceView: View {
    @Binding var user: AppUser?
    @Binding var role: Role?
    @State private var selectedTab = 0 // 0 for Maintenance, 1 for SOS
    @State private var selectedSegment = 0 // 0 for Scheduled, 1 for In Progress, 2 for Completed
    @State private var tasks: [MaintenanceTask] = []
    @State private var isLoading = false
    @State private var showingCompletionDaysSheet = false
    @State private var showingInvoiceSheet = false
    @State private var selectedTask: MaintenanceTask?
    @State private var completionDays = 1
    @State private var showingProfile = false
    @State private var vehicleLicenseMap: [Int: String] = [:]
    @State private var showingStartWorkConfirmation = false
    @State private var taskToStart: MaintenanceTask?
    @State private var laborCost: String = "0.0"
    @State private var partsCost: String = "0.0"
    @State private var otherCost: String = "0.0"
    @State private var repairNote: String = ""
    @State private var showingInvoicePreview = false
    @State private var generatedInvoice: Invoice?
    
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
            VStack(spacing: 0) {
                // Navigation Title
                HStack {
                    Text("Maintenance")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.leading)
                    
                    Spacer()
                    
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.blue)
                            .padding(.trailing)
                    }
                }
                .padding(.bottom, 10)
                .padding(.top, 70)
                
                // Segment Controller
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemGray5))
                        .frame(height: 45)
                    
                    HStack(spacing: 0) {
                        Button(action: { selectedSegment = 0 }) {
                            Text("Assigned")
                                .font(.headline)
                                .fontWeight(selectedSegment == 0 ? .semibold : .regular)
                                .foregroundColor(selectedSegment == 0 ? .black : .gray)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Group {
                                        if selectedSegment == 0 {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .padding(4)
                                        }
                                    }
                                )
                        }
                        
                        Button(action: { selectedSegment = 1 }) {
                            Text("In Progress")
                                .font(.headline)
                                .fontWeight(selectedSegment == 1 ? .semibold : .regular)
                                .foregroundColor(selectedSegment == 1 ? .black : .gray)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Group {
                                        if selectedSegment == 1 {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .padding(4)
                                        }
                                    }
                                )
                        }
                        
                        Button(action: { selectedSegment = 2 }) {
                            Text("Completed")
                                .font(.headline)
                                .fontWeight(selectedSegment == 2 ? .semibold : .regular)
                                .foregroundColor(selectedSegment == 2 ? .black : .gray)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Group {
                                        if selectedSegment == 2 {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .padding(4)
                                        }
                                    }
                                )
                        }
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
                            // Debug text to show number of filtered tasks
                            let filteredCount = filteredTasks.count
                            let categoryName = selectedSegment == 0 ? "Assigned" : selectedSegment == 1 ? "In Progress" : "Completed"
//                            Text("DEBUG: \(filteredCount) tasks in \(categoryName) category")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                                .padding(.bottom, 4)
                            
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
                                            taskToStart = task
                                            showingStartWorkConfirmation = true
                                        },
                                        onDaysSelected: { days in
                                            selectedTask = task
                                            updateCompletionDays(days: days)
                                        },
                                        onCreateInvoice: {
                                            selectedTask = task
                                            showingInvoiceSheet = true
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
                    
            }
            .edgesIgnoringSafeArea(.top)
            .tabItem {
                Image(systemName: "wrench.and.screwdriver.fill")
                Text("Maintenance")
            }
            .tag(0)
            
            // SOS TAB
            VStack {
                Text("SOS Feature")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("Coming Soon")
                    .font(.title)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .edgesIgnoringSafeArea(.top)
            .tabItem {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("SOS")
            }
            .tag(1)
            .badge(5)
        }
        .onAppear {
            // Set the TabView appearance to match iOS design
            UITabBar.appearance().backgroundColor = .systemBackground
            
            // Debug print for user details
            print("DEBUG: User ID: \(user?.id.uuidString ?? "nil"), Role: \(user?.role.rawValue ?? "nil")")
            
            loadTasks()
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
        .accentColor(.blue)
    }
    
    var filteredTasks: [MaintenanceTask] {
        let filtered: [MaintenanceTask]
        switch selectedSegment {
        case 0:
            filtered = tasks.filter { $0.status == .scheduled }
            print("DEBUG: Found \(filtered.count) scheduled tasks out of \(tasks.count) total tasks")
            return filtered
        case 1:
            filtered = tasks.filter { $0.status == .inProgress }
            print("DEBUG: Found \(filtered.count) in-progress tasks out of \(tasks.count) total tasks")
            return filtered
        case 2:
            filtered = tasks.filter { $0.status == .completed }
            print("DEBUG: Found \(filtered.count) completed tasks out of \(tasks.count) total tasks")
            return filtered
        default:
            print("DEBUG: Invalid segment selection: \(selectedSegment)")
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
                
                // Load all vehicle license numbers
                for task in directTasks {
                    if let vehicle = await dataController.getRegisteredVehicle(by: task.vehicleID) {
                        DispatchQueue.main.async {
                            self.vehicleLicenseMap[task.vehicleID] = vehicle.licenseNumber
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.tasks = directTasks
                    self.isLoading = false
                }
            } catch {
                print("DEBUG ERROR: Failed to load tasks directly: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.tasks = dataController.personnelTasks
                    self.isLoading = false
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
            
//            Button(action: onCreateInvoice) {
//                HStack {
//                    Image(systemName: "doc.text")
//                    Text("View Invoice")
//                }
//                .fontWeight(.medium)
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 10)
//                .background(Color.green)
//                .cornerRadius(8)
//            }
           // .padding(.top, 5)
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
                            
//                            HStack {
//                                Text("Tax (18%)")
//                                Spacer()
//                                Text("₹\(invoice.totalExpense * 0.18, specifier: "%.2f")")
//                            }
                            
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
                    
                    // Buttons
//                    HStack {
//                        Button("Download PDF") {
//                            generatePDF()
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                        
//                        Button("Email Invoice") {
//                            emailInvoice()
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.green)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                    }
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
    
//    func generatePDF() {
//        // In a real app, this would generate a PDF using PDFKit
//        print("Generating PDF for invoice #\(invoice.taskID)")
//        presentationMode.wrappedValue.dismiss()
//    }
//    
//    func emailInvoice() {
//        // In a real app, this would open an email composer
//        print("Emailing invoice #\(invoice.taskID)")
//        presentationMode.wrappedValue.dismiss()
//    }
}
