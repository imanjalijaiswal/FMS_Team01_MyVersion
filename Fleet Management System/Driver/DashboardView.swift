import SwiftUI

struct DashboardView: View {
    @State var remoteController = RemoteController.shared
    @StateObject private var viewModel = IFEDataController.shared
    @Binding var user: AppUser?
    @Binding var role : Role?
    @State private var showingProfile = false
    @State private var selectedFilter: TaskFilter = .assigned
    //@State private var viewModel.tripsForDriver: [Trip] = []
    
    var filteredTrips: [Trip] {
        viewModel.tripsForDriver.filter { task in
            switch selectedFilter {
            case .assigned:
                return task.status == .scheduled
            case .history:
                return task.status == .completed
            }
        }
    }
    
    var activeTrip: Trip? {
        viewModel.tripsForDriver.first { $0.status == .inProgress }
    }
    
    var body: some View {
        NavigationView{
            ScrollView{
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Trip")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGradientStart)
                        .padding(.horizontal)
                    
                    if let activeTrip = activeTrip {
                        TaskCard(task: activeTrip)
                            .padding(.horizontal)
                            .shadow(radius: 2, x: 2, y: 2)
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
                        .padding(.vertical, 32)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                
                Text("My Trips")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .foregroundColor(.primaryGradientStart)
                
                // Task filters
                TaskFilterView(selectedFilter: $selectedFilter)
                
                // Task list
                VStack(spacing: 16) {
                    ForEach(filteredTrips, id: \.id) { trip in
                        TaskCard(task: trip)
                            .shadow(radius: 2, x: 2, y: 2)
                    }
                }
                .padding()
            }
            .background(Color(red: 242/255, green: 242/255, blue: 247/255))
            .navigationTitle("Hello, \(user!.meta_data.fullName.split(separator: " ").first ?? "")")// Empty title to prevent double title
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    //                    Button(action: {
                    //                        // Action for the bell button
                    //                    }) {
                    //                        Image(systemName: "bell.fill")
                    //                            .font(.title2)
                    //                            .foregroundColor(.primaryGradientStart)
                    //                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle")
                            .font(.title)
                            .foregroundColor(.primaryGradientStart)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView(user: $user, role: $role)
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
                .background(isSelected ? Color.white : Color.white.opacity(0.5))
                .foregroundColor(isSelected ? .primaryGradientStart : .gray)
                .cornerRadius(20)
        }
    }
}

struct TaskCard: View {
    let task: Trip
    @State private var showingTripOverview = false
    @State private var vehicle: Vehicle?
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
                                    Text("\(vehicle.make) \(vehicle.model) \n \(vehicle.licenseNumber)") // Show vehicle name instead of ID
                                        .foregroundColor(.statusOrange)
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
                    Text("\(task.scheduledDateTime)")
                        .fontWeight(.medium)
                    if let description = task.description, !description.isEmpty {
                        Text("•")
                        Text(description)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                
                // Locations
                LocationViewWrapper(coordinate: task.pickupLocation, type: .pickup)
                LocationViewWrapper(coordinate: task.destination, type: .destination)
                
                // Distance and time
                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.primaryGradientStart)
                    Text("\(task.totalDistance)")
                    Text("-")
                    Text("\(task.totalTripDuration)")
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
            TripOverviewView(task: task)
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


