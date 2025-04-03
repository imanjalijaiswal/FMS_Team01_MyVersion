import SwiftUI

struct DashboardView: View {
    @State var remoteController = RemoteController.shared
    @StateObject private var viewModel = IFEDataController.shared
    @Binding var user: AppUser?
    @Binding var role : Role?
    @State private var showingProfile = false
    @State private var selectedFilter: TaskFilter = .assigned
    @Binding var selectedTab: Int
    @State private var preInspectionCompletedTrips: Set<UUID> = []
    @State private var tripsRequiringMaintenance: Set<UUID> = []
    @State private var isRefreshing = false
    @State private var isActiveTripRefreshing = false
    
    var filteredTrips: [Trip] {
        viewModel.tripsForDriver.filter { task in
            // First check if this trip is the active trip
            let isActiveTrip = task.status == .inProgress || 
                             (preInspectionCompletedTrips.contains(task.id) && 
                              task.status == .scheduled && 
                              !tripsRequiringMaintenance.contains(task.id))
            
            // If it's the active trip, don't show it in filtered list
            if isActiveTrip {
                return false
            }
            
            // Otherwise, apply normal filtering
            switch selectedFilter {
            case .assigned:
                return task.status == .scheduled
            case .history:
                return task.status == .completed
            }
        }
    }
    
    var activeTrip: Trip? {
        viewModel.tripsForDriver.first { trip in
            // Include trips that are either in progress or have completed pre-inspection
            // but exclude trips that require maintenance
            trip.status == .inProgress || 
            (preInspectionCompletedTrips.contains(trip.id) && 
             trip.status == .scheduled && 
             !tripsRequiringMaintenance.contains(trip.id))
        }
    }
    
    func refreshData() async {
        isRefreshing = true
        
        // Load trips for the driver
        await viewModel.loadTripsForDriver()
        
        // Check pre-inspections
        await checkPreInspections()
        
        isRefreshing = false
    }
    
    func refreshActiveTrip() async {
        isActiveTripRefreshing = true
        
        // Load trips for the driver
        await viewModel.loadTripsForDriver()
        
        // Check pre-inspections
        await checkPreInspections()
        
        isActiveTripRefreshing = false
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // The entire UI stays in the same layout structure whether refreshing or not,
                    // only the content of individual sections changes
                    
                    // Active Trip section
                    VStack(alignment: .leading, spacing: 0) {
                        // Active Trip section title
                        if isRefreshing {
                            Rectangle()
                                .foregroundColor(Color.gray.opacity(0.4))
                                .frame(width: 100, height: 20)
                                .cornerRadius(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .padding(.top, 8)
                                .id("active-trip-title-skeleton")
                        } else {
                            Text("Active Trip")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryGradientStart)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .id("active-trip-title")
                        }
                        
                        // Active Trip section content
                        if isRefreshing {
                            // Always use the same ActiveTripSkeletonView regardless of actual trip state
                            NoActiveTripSkeletonView()
                                .id("active-trip-global-skeleton")
                        } else if isActiveTripRefreshing {
                            // Show the appropriate skeleton view for just the active trip section
                            if activeTrip != nil {
                                ActiveTripSkeletonView()
                                    .id("active-trip-skeleton")
                            } else {
                                NoActiveTripSkeletonView()
                                    .id("no-active-trip-skeleton")
                            }
                        } else if let activeTrip = activeTrip {
                            TaskCard(task: activeTrip, selectedTab: $selectedTab)
                                .padding(.horizontal)
                                .shadow(radius: 2, x: 2, y: 2)
                                .id("active-trip-card-\(activeTrip.id)")
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "truck.box")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.primaryGradientStart.opacity(0.6))
                                
                                Text("No Active Trip")
                                    .font(.headline)
                                    .foregroundColor(.primaryGradientStart)
                                
                                Text("You don't have any active trips at the moment")
                                    .font(.subheadline)
                                    .foregroundColor(.primaryGradientStart.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .id("no-active-trip")
                        }
                    }
                    .padding(.bottom, 8)
                    .refreshable {
                        await refreshActiveTrip()
                    }
                    
                    // My Trips section title
                    if isRefreshing {
                        Rectangle()
                            .foregroundColor(Color.gray.opacity(0.4))
                            .frame(width: 100, height: 20)
                            .cornerRadius(10)
                            .padding()
                            .id("my-trips-title-skeleton")
                    } else {
                        Text("My Trips")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .foregroundColor(.primaryGradientStart)
                            .id("my-trips-title")
                    }
                    
                    // Task filters
                    if isRefreshing {
                        // Skeleton filter buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(0..<2, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.4))
                                        .frame(width: 100, height: 36)
                                        .cornerRadius(20)
                                        .shimmer()
                                }
                            }
                            .padding(.horizontal)
                        }
                        .id("filters-skeleton")
                    } else {
                        TaskFilterView(selectedFilter: $selectedFilter)
                            .id("filters")
                    }
                    
                    // Task list
                    VStack(spacing: 16) {
                        if isRefreshing {
                            // Show skeleton cards
                            ForEach(0..<3, id: \.self) { index in
                                DriverTaskCardSkeletonView()
                                    .shadow(radius: 2, x: 2, y: 2)
                                    .id("task-skeleton-\(index)")
                            }
                            .padding(.horizontal)
                        } else if filteredTrips.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: selectedFilter == .assigned ? "calendar.badge.plus" : "clock.arrow.circlepath")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.primaryGradientStart.opacity(0.6))
                                
                                Text(selectedFilter == .assigned ? "No Assigned Trips" : "No Trip History")
                                    .font(.headline)
                                    .foregroundColor(.primaryGradientStart)
                                
                                Text(selectedFilter == .assigned ? "You don't have any assigned trips at the moment" : "You haven't completed any trips yet")
                                    .font(.subheadline)
                                    .foregroundColor(.primaryGradientStart.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .id("no-trips-\(selectedFilter.rawValue)")
                        } else {
                            ForEach(filteredTrips, id: \.id) { trip in
                                TaskCard(task: trip, selectedTab: $selectedTab)
                                    .shadow(radius: 2, x: 2, y: 2)
                                    .id("trip-card-\(trip.id)")
                            }
                        }
                    }
                    .padding()
                    .id("trip-list")
                }
                .id("dashboard-content")
            }
            .refreshable {
                await refreshData()
            }
            .background(Color(red: 242/255, green: 242/255, blue: 247/255))
            .navigationTitle("Driver")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isRefreshing {
                        Circle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 35, height: 35)
                            .shimmer()
                            .id("profile-skeleton")
                    } else {
                        Button(action: {
                            showingProfile = true
                        }) {
                            Image(systemName: "person.circle")
                                .font(.title)
                                .foregroundColor(.primaryGradientStart)
                        }
                        .id("profile-button")
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isRefreshing)
            .animation(.easeInOut(duration: 0.2), value: isActiveTripRefreshing)
            .sheet(isPresented: $showingProfile) {
                ProfileView(user: $user, role: $role)
            }
        }
        .task {
            if viewModel.tripsForDriver.isEmpty {
                isRefreshing = true
                await viewModel.loadTripsForDriver()
                await checkPreInspections()
                isRefreshing = false
            } else {
                await checkPreInspections()
            }
        }
    }
    
    private func checkPreInspections() async {
        for trip in viewModel.tripsForDriver {
            if let inspection = await IFEDataController.shared.getTripInspectionForTrip(by: trip.id) {
                let hasAnyFailure = inspection.preInspection.values.contains(false)
                let hasCompletedPreInspection = !inspection.preInspection.isEmpty
                
                if hasCompletedPreInspection {
                    preInspectionCompletedTrips.insert(trip.id)
                    if hasAnyFailure {
                        tripsRequiringMaintenance.insert(trip.id)
                    }
                }
            }
        }
    }
}

struct TaskFilterView: View {
    @Binding var selectedFilter: TaskFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterButton(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .padding()
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primaryGradientStart : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20)
        }
    }
}

struct TaskCard: View {
    let task: Trip
    @State private var showingTripOverview = false
    @State private var vehicle: Vehicle?
    @Binding var selectedTab: Int
    var remoteController = RemoteController()
    var statusColor: Color {
        switch task.status {
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .scheduled:
            return .orange
        }
    }
    var body: some View {
        Button(action: { showingTripOverview = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Task header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Trip ID: \(task.tripID)")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.headline)
                                .foregroundColor(.primaryGradientStart)
                        }
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                if let vehicle = vehicle {
                                    VStack(alignment: .leading){
                                        Text("\(vehicle.make) \(vehicle.model)")
                                            .font(.caption)
                                            .foregroundColor(.textSecondary)// Show vehicle name instead of ID
                                        Text(vehicle.licenseNumber)
                                            .foregroundColor(.statusOrange)
                                    }
                                } else {
                                    Text("Loading...")
                                        .foregroundColor(.gray)
                                }
                            }
                            .font(.subheadline)
                            Spacer()
                            Text(task.status.rawValue)
                                .font(.caption)
                                .foregroundColor(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // Task details
                HStack {
                    Text("\(task.scheduledDateTime.formatted())")
                        .fontWeight(.medium)
                    if let description = task.description, !description.isEmpty {
                        Text("•")
                        Text(description)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                Divider()
                // Locations
                LocationViewWrapper(coordinate: task.pickupLocation, type: .pickup)
                LocationViewWrapper(coordinate: task.destination, type: .destination)
                
                // Distance and time
                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.primaryGradientStart)
                    Text("\(task.totalDistance)")
                    Image(systemName: "clock")
                        .foregroundColor(.primaryGradientStart)
                    Text("\(Int(task.totalDistance)/50) hours")
                }
                .font(.subheadline)
                .foregroundColor(.textSecondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTripOverview) {
            TripOverviewView(task: task, selectedTab: $selectedTab, isInDestinationGeofence: MapViewModel().hasReachedDestination)
        }
        .task {
            await fetchVehicle() // Fetch vehicle data when TaskCard appears
        }
    }

    private func fetchVehicle() async {
            do {
                vehicle = try await remoteController.getRegisteredVehicle(by: task.assignedVehicleID)
            } catch {
                print("Error fetching vehicle: \(error)")
            }
        }
}
struct LocationViewWrapper: View {
    let coordinate: String
    let type: LocationType
    @State private var address: String = "Loading..."

    var body: some View {
        LocationView(location: Location(name: type == .pickup ? "Pickup" : "Destination", address: address), type: type)
            .onAppear {
                getAddress(from: coordinate) { fetchedAddress in
                    DispatchQueue.main.async {
                        self.address = fetchedAddress ?? "Unknown Location"
                    }
                }
            }
    }
}
struct LocationView: View {
    let location: Location
    let type: LocationType
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(type == .pickup ? Color.primaryGradientStart : Color.statusOrange)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type == .pickup ? "Pickup" : "Destination")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text(location.address)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

// Models
enum TaskFilter: String, CaseIterable {
    case assigned = "Assigned"
    case history = "History"
}

enum TripType: String {
    case active = "ACTIVE"
    case assigned = "ASSIGNED"
    case completed = "COMPLETED"
    
    var color: Color {
        switch self {
        case .active:
            return .statusRed
        case .assigned:
            return .statusOrange
        case .completed:
            return .statusGreen
        }
    }
}


struct Location {
    let name: String
    let address: String
}

enum LocationType {
    case pickup
    case destination
}

struct NotificationButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "bell")
                .font(.title2)
        }
    }
}

//struct Partner {
//    let name: String
//    let company: String
//    let contactNumber: String
//    let email: String
//}


