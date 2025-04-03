import SwiftUI
import MapKit

struct SOSTabView: View {
    @Binding var sosSelectedSegment: Int
    let isSosLoading: Bool
    let filteredSOSTasks: [MaintenanceTask]
    let vehicleLicenseMap: [Int: String]
    let userPhoneMap: [UUID: String]
    let userNameMap: [UUID: String]
    let onShowProfile: () -> Void
    let onTrackTask: (MaintenanceTask) -> Void
    let onRefresh: () -> Void
    let isRefreshing: Bool
    
    @State private var refreshTrigger = UUID()
    
    private var activeTasks: [MaintenanceTask] {
        let active = filteredSOSTasks.filter { $0.status != .completed }
        print("DEBUG: Active tasks for current segment: \(active.count)")
        for task in active {
            print("  Active Task ID: \(task.id), Status: \(task.status.rawValue)")
        }
        return active
    }
    
    private var completedTasks: [MaintenanceTask] {
        let completed = filteredSOSTasks.filter { $0.status == .completed }
        print("DEBUG: Completed tasks for current segment: \(completed.count)")
        for task in completed {
            print("  Completed Task ID: \(task.id), Status: \(task.status.rawValue)")
        }
        return completed
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with fixed size and constrained font size
            HStack {
                Text("SOS")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGradientStart)
                
                Spacer()
                
                Button(action: {
                    onRefresh()
                    refreshTrigger = UUID()
                    print("DEBUG: filteredSOSTasks after refresh: \(filteredSOSTasks)")
                }) {
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
                    .frame(height: 48)
                    .padding(.horizontal)
                
                HStack(spacing: 0) {
                    // Pre-inspect Tab
                    Button(action: { 
                        // Force a reload when changing segments
                        onRefresh()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            sosSelectedSegment = 0 
                            refreshTrigger = UUID() // Refresh when changing segments
                        }
                    }) {
                        VStack {
                            Text("Pre-inspect")
                                .font(.system(size: 14, weight: sosSelectedSegment == 0 ? .semibold : .regular))
                                .foregroundColor(sosSelectedSegment == 0 ? .white : .black)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    sosSelectedSegment == 0 ?
                                        RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.primaryGradientStart)
                                        : RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }
                    
                    // Post-inspect Tab
                    Button(action: { 
                        // Force a reload when changing segments
                        onRefresh()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            sosSelectedSegment = 1 
                            refreshTrigger = UUID() // Refresh when changing segments
                        }
                    }) {
                        VStack {
                            Text("Post-inspect")
                                .font(.system(size: 14, weight: sosSelectedSegment == 1 ? .semibold : .regular))
                                .foregroundColor(sosSelectedSegment == 1 ? .white : .black)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    sosSelectedSegment == 1 ?
                                        RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.primaryGradientStart)
                                        : RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                    }
                    
                    // Emergency Tab
                    Button(action: { 
                        // Force a reload when changing segments
                        onRefresh()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            sosSelectedSegment = 2 
                            refreshTrigger = UUID() // Refresh when changing segments
                        }
                    }) {
                        VStack {
                            Text("Emergency")
                                .font(.system(size: 14, weight: sosSelectedSegment == 2 ? .semibold : .regular))
                                .foregroundColor(sosSelectedSegment == 2 ? .white : .black)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    sosSelectedSegment == 2 ?
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
            
            if isSosLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
                Spacer()
            } else {
                ScrollView {
                    PullToRefresh(coordinateSpaceName: "sosRefresh", onRefresh: {
                        onRefresh()
                        refreshTrigger = UUID()
                        print("DEBUG: filteredSOSTasks after pull-to-refresh: \(filteredSOSTasks)")
                    }, isRefreshing: isRefreshing)
                    
                    LazyVStack(spacing: 16) {
                        if filteredSOSTasks.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.primaryGradientStart.opacity(0.6))
                                
                                Text("No SOS tasks available")
                                    .font(.headline)
                                    .foregroundColor(.primaryGradientStart)
                                
                                Text("You don't have any SOS tasks at the moment")
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
                            // Active Tasks Section
                            if !activeTasks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Active Tasks")
                                        .font(.headline)
                                        .foregroundColor(.primaryGradientStart)
                                        .padding(.horizontal)
                                    
                                    ForEach(activeTasks) { task in
                                        SOSTaskCard(
                                            task: task,
                                            vehicleLicense: vehicleLicenseMap[task.vehicleID],
                                            assignerPhone: userPhoneMap[task.assignedBy],
                                            assignerName: userNameMap[task.assignedBy],
                                            onTrack: {
                                                onTrackTask(task)
                                            },
                                            onResolve: {
                                                onRefresh() // Refresh after resolving
                                                refreshTrigger = UUID()
                                            }
                                        )
                                        .id("\(task.id)-\(task.status.rawValue)-\(refreshTrigger)")  // Use unique ID with refresh trigger
                                    }
                                }
                            }
                            
                            // Completed Tasks Section
                            if !completedTasks.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Completed Tasks")
                                        .font(.headline)
                                        .foregroundColor(.primaryGradientStart)
                                        .padding(.horizontal)
                                        .padding(.top, activeTasks.isEmpty ? 0 : 16)
                                    
                                    ForEach(completedTasks) { task in
                                        SOSTaskCard(
                                            task: task,
                                            vehicleLicense: vehicleLicenseMap[task.vehicleID],
                                            assignerPhone: userPhoneMap[task.assignedBy],
                                            assignerName: userNameMap[task.assignedBy],
                                            onTrack: {
                                                onTrackTask(task)
                                            },
                                            onResolve: {
                                                onRefresh() // Refresh after resolving
                                                refreshTrigger = UUID()
                                            }
                                        )
                                        .id("\(task.id)-\(task.status.rawValue)-\(refreshTrigger)")  // Use unique ID with refresh trigger
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .id(refreshTrigger) // Force LazyVStack to refresh
                }
                .coordinateSpace(name: "sosRefresh")
                .id(refreshTrigger)
                .onAppear {
                    // Force refresh when view appears
                    refreshTrigger = UUID()
                    print("DEBUG: View appeared, forcing refresh with new trigger: \(refreshTrigger)")
                    
                    // Log current task statuses
                    print("DEBUG: Current task statuses on view appear:")
                    for task in filteredSOSTasks {
                        print("  Task \(task.id): Status: \(task.status.rawValue), Type: \(task.type.rawValue)")
                    }
                }
            }
        }
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
        .onChange(of: sosSelectedSegment) { _ in
            // Force refresh when segment changes
            refreshTrigger = UUID()
            print("DEBUG: Segment changed, forcing refresh with new trigger: \(refreshTrigger)")
        }
    }
}

struct SOSTaskCard: View {
    let task: MaintenanceTask
    let vehicleLicense: String?
    let assignerPhone: String?
    let assignerName: String?
    let onTrack: () -> Void
    let onResolve: () -> Void
    @State private var showingResolutionSheet = false
    @State private var selectedIssueType = MaintenanceExpenseType.laborsCost
    @State private var resolutionNotes = ""
    @State private var isResolving = false
    @State private var isConnecting = false
    @State private var isTracking = false
    @State private var showingResolutionDetails = false
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    private let dataController = IFEDataController.shared
    
    // Break down the body into smaller components
    private var headerView: some View {
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
    }
    
    private var taskInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            if let assignerName = assignerName {
                HStack(spacing: 5) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.primaryGradientStart)
                    Text(assignerName)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            if let phone = assignerPhone {
                HStack(spacing: 5) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.primaryGradientStart)
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            if task.status != .completed {
                // Connect Button
                Button(action: {
                    Task {
                        await connectButtonAction()
                    }
                }) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .padding(.trailing, 5)
                        } else {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.white)
                        }
                        Text(isConnecting ? "Connecting..." : "Connect")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .disabled(isConnecting)
                
                // Track Button
                Button(action: {
                    Task {
                        await trackButtonAction()
                    }
                }) {
                    HStack {
                        if isTracking {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .padding(.trailing, 5)
                        } else {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                        }
                        Text(isTracking ? "Tracking..." : "Track")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isTracking)
                
                // Resolve Button
                Button(action: {
                    Task {
                        await resolveButtonAction()
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Resolve")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primaryGradientStart)
                    .cornerRadius(8)
                }
            } else {
                // View Resolution Button for completed tasks
                Button(action: {
                    showingResolutionDetails = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.white)
                        Text("View Resolution")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.primaryGradientStart)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func connectButtonAction() async {
        isConnecting = true
        do {
            // Update task status to in progress
            await dataController.makeMaintenanceTaskInProgress(by: task.id)
            
            if let phone = assignerPhone {
                let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                
                if let url = URL(string: "tel://\(cleanPhone)") {
                    await MainActor.run {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        } else {
                            print("Cannot open URL: \(url)")
                        }
                    }
                }
            }
            
            await MainActor.run {
                isConnecting = false
                successMessage = "Task marked as In Progress and call initiated"
                showingSuccessAlert = true
            }
        } catch {
            await MainActor.run {
                isConnecting = false
            }
        }
    }
    
    private func trackButtonAction() async {
        isTracking = true
        do {
            // Update task status to in progress
            await dataController.makeMaintenanceTaskInProgress(by: task.id)
            
            await MainActor.run {
                onTrack()
                isTracking = false
                successMessage = "Task marked as In Progress and tracking started"
                showingSuccessAlert = true
            }
        } catch {
            await MainActor.run {
                isTracking = false
            }
        }
    }
    
    private func resolveButtonAction() async {
        do {
            // Update task status to in progress before showing resolution sheet
            await dataController.makeMaintenanceTaskInProgress(by: task.id)
            await MainActor.run {
                showingResolutionSheet = true
            }
        } catch {
            print("Error updating task status: \(error)")
        }
    }
    
    private var resolutionSheetView: some View {
        NavigationView {
            Form {
                Section(header: Text("Issue Note")) {
                    Text(task.issueNote)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Section(header: Text("Issue Type")) {
                    Picker("Issue Type", selection: $selectedIssueType) {
                        Text("Mechanical").tag(MaintenanceExpenseType.laborsCost)
                        Text("Electrical").tag(MaintenanceExpenseType.partsCost)
                        Text("Tire").tag(MaintenanceExpenseType.otherCost)
                    }
                }
                
                Section(header: Text("Resolution Notes")) {
                    TextEditor(text: $resolutionNotes)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: {
                        Task {
                            await markAsResolved()
                        }
                    }) {
                        if isResolving {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Completing Task...")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        } else {
                            Text("Mark as Resolved")
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGradientStart)
                    .cornerRadius(8)
                    .disabled(isResolving)
                }
            }
            .navigationTitle("Resolve Issue")
            .navigationBarItems(trailing: Button("Cancel") {
                showingResolutionSheet = false
            }
            .foregroundColor(.primaryGradientStart))
        }
    }
    
    private func markAsResolved() async {
        isResolving = true
        do {
            // Create invoice with resolution details
            await dataController.createInvoiceForMaintenanceTask(
                by: task.id,
                expenses: [selectedIssueType: 0.0],
                resolutionNotes
            )
            
            await MainActor.run {
                isResolving = false
                showingResolutionSheet = false
                successMessage = "Task completed successfully! Resolution details have been saved."
                showingSuccessAlert = true
                onResolve()
            }
        } catch {
            await MainActor.run {
                isResolving = false
            }
        }
    }
    
    private var resolutionDetailsHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let completionDate = task.completionDate {
                Text("Resolved on: \(completionDate.formatted(.dateTime.day().month().year().hour().minute()))")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.bottom)
    }
    
    private var issueTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Maintenance Type")
                .font(.headline)
                .foregroundColor(.primaryGradientStart)
            
            Text(task.type.rawValue)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var repairNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repair Notes")
                .font(.headline)
                .foregroundColor(.primaryGradientStart)
            
            Text(task.repairNote.isEmpty ? "No repair notes provided" : task.repairNote)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
    }
    
    private var resolutionDetailsView: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with completion date
                    if let completionDate = task.completionDate {
                        Text("Resolved on: \(completionDate.formatted(.dateTime.day().month().year().hour().minute()))")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .padding(.bottom, 10)
                    }
                    
                    // Issue Note Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issue Note")
                            .font(.headline)
                            .foregroundColor(.primaryGradientStart)
                        
                        Text(task.issueNote)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Maintenance Type Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maintenance Type")
                            .font(.headline)
                            .foregroundColor(.primaryGradientStart)
                        
                        Text(task.type.rawValue)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Issue Type Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Issue Type")
                            .font(.headline)
                            .foregroundColor(.primaryGradientStart)
                        
                        Text(selectedIssueType == .laborsCost ? "Mechanical" :
                             selectedIssueType == .partsCost ? "Electrical" : "Other")
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Repair Notes Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Repair Notes")
                            .font(.headline)
                            .foregroundColor(.primaryGradientStart)
                        
                        Text(task.repairNote.isEmpty ? "No repair notes provided" : task.repairNote)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Resolution Details")
            .navigationBarItems(trailing: Button("Close") {
                showingResolutionDetails = false
            })
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            taskInfoView
            actionButtonsView
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showingResolutionSheet) {
            resolutionSheetView
        }
        .sheet(isPresented: $showingResolutionDetails) {
            resolutionDetailsView
        }
        .alert("Success", isPresented: $showingSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
    }
    
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
} 
