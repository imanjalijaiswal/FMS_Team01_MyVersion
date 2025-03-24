import SwiftUI

struct DashboardView: View {
    @Binding var user: AppUser?
    @Binding var role : Role?
    @State private var showingProfile = false
    @State private var selectedFilter: TaskFilter = .assigned
    @State private var trips: [Trip] = [
        // Active Trip (only one allowed)
        
//        Trip(
//                    id: UUID(),
//                    tripID: 1,
//                    assignedByFleetManagerID: UUID(),
//                    assignedDriverIDs: [UUID()],
//                    assigneVehicleID: 1,
//                    pickupLocation: "Bhiwandi Logistics Park, Mumbai-Nashik Highway, Maharashtra",
//                    destination: "Attibele Industrial Area, Hosur Road, Bangalore",
//                    estimatedArrivalDateTime: Date().addingTimeInterval(14*3600),
//                    totalDistance: 985,
//                    totalTripDuration: Date().addingTimeInterval(14*3600),
//                    description: "Electronics, 2500 kg",
//                    scheduledDateTime: Date(),
//                    status: .inProgress
//        ),
        
        
        // Upcoming Trips
//        Trip(
//                    id: UUID(),
//                    tripID: 2,
//                    assignedByFleetManagerID: UUID(),
//                    assignedDriverIDs: [UUID()],
//                    assigneVehicleID: 2,
//                    pickupLocation: "SIPCOT Industrial Park, Chennai, Tamil Nadu",
//                    destination: "Miyapur, Hyderabad, Telangana",
//                    estimatedArrivalDateTime: Date().addingTimeInterval(24*3600),
//                    totalDistance: 635,
//                    totalTripDuration: Date().addingTimeInterval(9*3600),
//                    description: "FMCG Goods, 1800 kg",
//                    scheduledDateTime: Date().addingTimeInterval(24*3600),
//                    status: .scheduled
//        ),
        
//        Trip(
//                    id: UUID(),
//                    tripID: 3,
//                    assignedByFleetManagerID: UUID(),
//                    assignedDriverIDs: [UUID()],
//                    assigneVehicleID: 3,
//                    pickupLocation: "IMT Manesar, Gurugram, Haryana",
//                    destination: "MIDC Pimpri, Pune, Maharashtra",
//                    estimatedArrivalDateTime: Date().addingTimeInterval(48*3600),
//                    totalDistance: 1420,
//                    totalTripDuration: Date().addingTimeInterval(20*3600),
//                    description: "Auto Parts, 3200 kg",
//                    scheduledDateTime: Date().addingTimeInterval(48*3600),
//                    status: .scheduled
//                ),
        
        // History Trips
//        
//        Trip(
//                    id: UUID(),
//                    tripID: 0,
//                    assignedByFleetManagerID: UUID(),
//                    assignedDriverIDs: [UUID()],
//                    assigneVehicleID: 1,
//                    pickupLocation: "Tirupur Trade Centre, Tamil Nadu",
//                    destination: "Linking Road, Mumbai, Maharashtra",
//                    estimatedArrivalDateTime: Date().addingTimeInterval(-24*3600),
//                    totalDistance: 1250,
//                    totalTripDuration: Date().addingTimeInterval(18*3600),
//                    description: "Textiles, 1500 kg",
//                    scheduledDateTime: Date().addingTimeInterval(-48*3600),
//                    status: .completed
//                ),
//        
//        Trip(
//                    id: UUID(),
//                    tripID: 999,
//                    assignedByFleetManagerID: UUID(),
//                    assignedDriverIDs: [UUID()],
//                    assigneVehicleID: 2,
//                    pickupLocation: "Vashi, Navi Mumbai, Maharashtra",
//                    destination: "Whitefield, Bangalore, Karnataka",
//                    estimatedArrivalDateTime: Date().addingTimeInterval(-48*3600),
//                    totalDistance: 985,
//                    totalTripDuration: Date().addingTimeInterval(14*3600),
//                    description: "Perishables, 2200 kg",
//                    scheduledDateTime: Date().addingTimeInterval(-72*3600),
//                    status: .completed
//                )
    ]
    
    var filteredTrips: [Trip] {
        trips.filter { task in
            switch selectedFilter {
            case .assigned:
                return task.status == .scheduled
            case .history:
                return task.status == .completed
            }
        }
    }
    
    var activeTrip: Trip? {
        trips.first { $0.status == .inProgress }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        .primaryGradientStart1,
//                        .primaryGradientEnd
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Active Trip Section
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
                                .background(Color.white.opacity(0.1))
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
                }
            }
            .navigationBarTitle("Hello, Rajesh", displayMode: .large)// Empty title to prevent double title
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
                        // Action for the bell button
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
struct DriverInfoCard: View {
    // Get the active trip to show current truck details
    @Binding var trips: [Trip]
    
    var currentTrip: Trip? {
        trips.first { $0.status == .inProgress }
    }
    
    var driverStatus: (text: String, color: Color) {
        if currentTrip != nil {
            return ("IN TRIP", .statusOrange)
        } else {
            return ("AVAILABLE", .statusGreen)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image("driver_avatar")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Rajesh Kumar Singh")
                    .fontWeight(.medium)
                if let activeTrip = currentTrip {
                    Text("\(activeTrip.assignedVehicleID)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Text(driverStatus.text)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(driverStatus.color.opacity(0.2))
                .foregroundColor(driverStatus.color)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
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
    
    var body: some View {
        Button(action: { showingTripOverview = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Task header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack{
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
                                //Text(task.truckType)
                                    //.foregroundColor(.textSecondary)
                                Text("\(task.assignedVehicleID)")
                                    .foregroundColor(.statusOrange)
                            }
                            .font(.subheadline)
                            Spacer()
                            Text(task.status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                //.background(task.status.color.opacity(0.2))
                                //.foregroundColor(task.status.color)
                                //.cornerRadius(4)
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
                
                //if !task.pickup.address.isEmpty {
                    // Locations
                    LocationView(location: Location(name: "Pickup", address: task.pickupLocation), type: .pickup)
                    LocationView(location: Location(name: "Destination", address: task.destination), type: .destination)
                    
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
                //}
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTripOverview) {
            TripOverviewView(task: task)
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

//struct Trips {
//    let tripId: String
//    let truckType: String
//    let numberPlate: String
//    let type: TripType
//    let date: String
//    let details: String
//    let pickup: Location
//    let destination: Location
//    let distance: 

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


