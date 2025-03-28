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
    
    // Reference to data controllers
    private let dataController = IFEDataController.shared
    
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
                            Text("DEBUG: \(filteredTasks.count) tasks in \(selectedSegment == 0 ? "Assigned" : selectedSegment == 1 ? "In Progress" : "Completed") category")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.bottom, 4)
                            
                            if filteredTasks.isEmpty {
                                Text("No tasks available")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                            } else {
                                ForEach(filteredTasks) { task in
                                    MaintenanceTaskCard(
                                        task: task,
                                        onStartWork: {
                                            startWork(task: task)
                                        },
                                        onSetCompletionDays: {
                                            selectedTask = task
                                            showingCompletionDaysSheet = true
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
        .sheet(isPresented: $showingCompletionDaysSheet) {
            CompletionDaysView(
                task: selectedTask!,
                completionDays: $completionDays,
                onSave: { days in
                    updateCompletionDays(days: days)
                }
            )
        }
        .sheet(isPresented: $showingInvoiceSheet) {
            Text("Invoice Creation View")
                .font(.title)
                .padding()
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
        
        // Direct API call for debugging
        Task {
            do {
                print("DEBUG: Making direct API call to get tasks")
                let directTasks = try await RemoteController.shared.getMaintenancePersonnelTasks(by: user.id)
                print("DEBUG: Direct API call returned \(directTasks.count) tasks")
                
                // Also try regular data controller method
                print("DEBUG: Calling dataController.loadPersonnelTasks()")
                await dataController.loadPersonnelTasks()
                print("DEBUG: dataController now has \(dataController.personnelTasks.count) tasks")
                
                DispatchQueue.main.async {
                    // Use direct tasks for faster debugging
                    self.tasks = directTasks
                    print("DEBUG: Set self.tasks with \(self.tasks.count) items")
                    self.isLoading = false
                    
                    // Print task statuses for debugging
                    let scheduledCount = self.tasks.filter { $0.status == .scheduled }.count
                    let inProgressCount = self.tasks.filter { $0.status == .inProgress }.count
                    let completedCount = self.tasks.filter { $0.status == .completed }.count
                    print("DEBUG: Task breakdown - Scheduled: \(scheduledCount), In Progress: \(inProgressCount), Completed: \(completedCount)")
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
            
            DispatchQueue.main.async {
                self.tasks = dataController.personnelTasks
                print("DEBUG: Reloaded \(self.tasks.count) tasks after starting work")
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
}

struct MaintenanceTaskCard: View {
    let task: MaintenanceTask
    let onStartWork: () -> Void
    let onSetCompletionDays: () -> Void
    let onCreateInvoice: () -> Void
    @State private var completionDays = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle ID: \(task.vehicleID)")
                .font(.headline)
                .padding(.top, 5)
            
            Text("Task ID: \(task.taskID)")
                .foregroundColor(.secondary)
            
            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Due: \(task.estimatedCompletionDate?.formatted(.dateTime.day()) ?? "Not Set")")
                    .foregroundColor(.secondary)
            }

            
            HStack(spacing: 5) {
                Image(systemName: "wrench.fill")
                    .foregroundColor(.blue)
                Text(task.type.rawValue)
                    .foregroundColor(.secondary)
            }
            
            if task.status == .scheduled {
                HStack {
                    Text("Complete in:")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        Text("\(completionDays) day\(completionDays > 1 ? "s" : "")")
                            .frame(width: 80, alignment: .center)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        VStack(spacing: 0) {
                            Button(action: { if completionDays < 30 { completionDays += 1 } }) {
                                Image(systemName: "chevron.up")
                                    .foregroundColor(.gray)
                                    .padding(2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                            
                            Button(action: { if completionDays > 1 { completionDays -= 1 } }) {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                                    .padding(2)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                    }
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
            } else if task.status == .inProgress {
                HStack {
                    Button(action: onSetCompletionDays) {
                        Text("Set Days")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
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
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct CompletionDaysView: View {
    let task: MaintenanceTask
    @Binding var completionDays: Int
    let onSave: (Int) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Set Completion Days for Task #\(task.taskID)")
                    .font(.headline)
                    .padding()
                
                Stepper("Estimated Days: \(completionDays)", value: $completionDays, in: 1...30)
                    .padding()
                
                Button("Save") {
                    onSave(completionDays)
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
