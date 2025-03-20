import SwiftUI

struct DashboardView: View {
    @Binding var user: AppUser?
    @Binding var role : Role?
    @State private var showingProfile = false
    @State private var selectedFilter: TaskFilter = .assigned
    @State private var trips: [Trips] = [
        // Active Trip (only one allowed)
        Trips(
            tripId: "TRP-2024-001",
            truckType: "Tata Prima LX 2823.K",
            numberPlate: "MH 04 HJ 1234",
            type: .active,
            date: "Today",
            details: "Electronics, 2500 kg",
            pickup: Location(
                name: "Amazon Warehouse",
                address: "Bhiwandi Logistics Park, Mumbai-Nashik Highway, Maharashtra"
            ),
            destination: Location(
                name: "Amazon FC",
                address: "Attibele Industrial Area, Hosur Road, Bangalore"
            ),
            distance: "985 km",
            estimatedTime: "14 hours",
            partner: Partner(
                name: "Priya Sharma",
                company: "Amazon Logistics",
                contactNumber: "+91 98765 43210",
                email: "priya.sharma@amazon.com"
            )
        ),
        
        // Upcoming Trips
        Trips(
            tripId: "TRP-2024-002",
            truckType: "Ashok Leyland 2518",
            numberPlate: "KA 01 AB 5678",
            type: .assigned,
            date: "Tomorrow - Mar 20, 2024",
            details: "FMCG Goods, 1800 kg",
            pickup: Location(
                name: "Hindustan Unilever DC",
                address: "SIPCOT Industrial Park, Chennai, Tamil Nadu"
            ),
            destination: Location(
                name: "HUL Regional Center",
                address: "Miyapur, Hyderabad, Telangana"
            ),
            distance: "635 km",
            estimatedTime: "9 hours",
            partner: Partner(
                name: "Rahul Verma",
                company: "Hindustan Unilever",
                contactNumber: "+91 87654 32109",
                email: "rahul.verma@hul.com"
            )
        ),
        Trips(
            tripId: "TRP-2024-003",
            truckType: "BharatBenz 2823C",
            numberPlate: "DL 01 HH 9876",
            type: .assigned,
            date: "Thursday - Mar 21, 2024",
            details: "Auto Parts, 3200 kg",
            pickup: Location(
                name: "Maruti Suzuki Plant",
                address: "IMT Manesar, Gurugram, Haryana"
            ),
            destination: Location(
                name: "Tata Motors Factory",
                address: "MIDC Pimpri, Pune, Maharashtra"
            ),
            distance: "1420 km",
            estimatedTime: "20 hours",
            partner: Partner(
                name: "Amit Patel",
                company: "Maruti Suzuki",
                contactNumber: "+91 76543 21098",
                email: "amit.patel@maruti.com"
            )
        ),
        
        // History Trips
        Trips(
            tripId: "TRP-2024-000",
            truckType: "Tata Prima LX 2823.K",
            numberPlate: "MH 04 HJ 1234",
            type: .completed,
            date: "Yesterday - Mar 18, 2024",
            details: "Textiles, 1500 kg",
            pickup: Location(
                name: "Textile Hub",
                address: "Tirupur Trade Centre, Tamil Nadu"
            ),
            destination: Location(
                name: "Fashion Street DC",
                address: "Linking Road, Mumbai, Maharashtra"
            ),
            distance: "1250 km",
            estimatedTime: "18",
            partner: Partner(
                name: "Neha Gupta",
                company: "Textile Hub",
                contactNumber: "+91 65432 10987",
                email: "neha.gupta@textilehub.com"
            )
        ),
        Trips(
            tripId: "TRP-2024-999",
            truckType: "Ashok Leyland 2518",
            numberPlate: "KA 01 AB 5678",
            type: .completed,
            date: "Mar 17, 2024",
            details: "Perishables, 2200 kg",
            pickup: Location(
                name: "APMC Market",
                address: "Vashi, Navi Mumbai, Maharashtra"
            ),
            destination: Location(
                name: "Big Bazaar DC",
                address: "Whitefield, Bangalore, Karnataka"
            ),
            distance: "985 km",
            estimatedTime: "14",
            partner: Partner(
                name: "Vikram Singh",
                company: "Big Bazaar",
                contactNumber: "+91 54321 09876",
                email: "vikram.singh@bigbazaar.com"
            )
        )
    ]
    
    var filteredTrips: [Trips] {
        trips.filter { task in
            switch selectedFilter {
            case .assigned:
                return task.type == .assigned
            case .history:
                return task.type == .completed
            }
        }
    }
    
    var activeTrip: Trips? {
        trips.first { $0.type == .active }
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
                            ForEach(filteredTrips, id: \.tripId) { trip in
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
                    Button(action: {
                        // Action for the bell button
                    }) {
                        Image(systemName: "bell.fill")
                            .font(.title2)
                            .foregroundColor(.primaryGradientStart)
                    }
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
    @Binding var trips: [Trips]
    
    var currentTrip: Trips? {
        trips.first { $0.type == .active }
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
                    Text("\(activeTrip.truckType) • \(activeTrip.numberPlate)")
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
    let task: Trips
    @State private var showingTripOverview = false
    
    var body: some View {
        Button(action: { showingTripOverview = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Task header
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack{
                            Text("Trip ID: \(task.tripId)")
                                .font(.headline)
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.headline)
                                .foregroundColor(.primaryGradientStart)
                        }
                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.truckType)
                                    .foregroundColor(.textSecondary)
                                Text(task.numberPlate)
                                    .foregroundColor(.statusOrange)
                            }
                            .font(.subheadline)
                            Spacer()
                            Text(task.type.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(task.type.color.opacity(0.2))
                                .foregroundColor(task.type.color)
                                .cornerRadius(4)
                        }
                    }
                    
                    
                }
                
                // Task details
                HStack {
                    Text(task.date)
                        .fontWeight(.medium)
                    if !task.details.isEmpty {
                        Text("•")
                        Text(task.details)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                
                if !task.pickup.address.isEmpty {
                    // Locations
                    LocationView(location: task.pickup, type: .pickup)
                    LocationView(location: task.destination, type: .destination)
                    
                    // Distance and time
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.primaryGradientStart)
                        Text(task.distance)
                        Text("-")
                        Text(task.estimatedTime)
                    }
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                }
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

struct Trips {
    let tripId: String
    let truckType: String
    let numberPlate: String
    let type: TripType
    let date: String
    let details: String
    let pickup: Location
    let destination: Location
    let distance: String
    let estimatedTime: String
    let partner: Partner
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

struct Partner {
    let name: String
    let company: String
    let contactNumber: String
    let email: String
}

