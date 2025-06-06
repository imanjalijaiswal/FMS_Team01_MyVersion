import SwiftUI
import MapKit

struct DashboardCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer: MKLocalSearchCompleter
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address, .query]
        completer.pointOfInterestFilter = .includingAll
    }
    
    func search(with query: String) {
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}


struct ProgressBarView: View {
    let title: String
    let total: Int
    let items: [(String, Int, Color)]
    
    var body: some View {
                            VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryGradientStart)
                                            Spacer()
                Text("Total: \(total)")
                                    .foregroundColor(.gray)
            }
            
                                GeometryReader { geometry in
                                    let availableWidth = max(1, geometry.size.width) // Prevent zero width
                                    HStack(spacing: 0) {
                                        ForEach(items, id: \.0) { item in
                                            let validValue = max(0, CGFloat(item.1)) // Ensure non-negative values
                                            let width = total > 0 ? validValue / CGFloat(total) * availableWidth : 0
                                            Rectangle()
                                                .fill(item.2)
                                                .frame(width: width)
                                        }
                                    }
                                    .frame(height: 8)
                                    .clipShape(Capsule())
                                }
                                .frame(height: 8)
            
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    ForEach(Array(items.prefix(2)), id: \.0) { item in
                        HStack(spacing: 3) {
                            Circle()
                                .fill(item.2)
                                .frame(width: 8, height: 8)
                            Text("\(item.0)")
                                .font(.caption)
                            Text("(\(item.1))")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
                
                if items.count > 2 {
                    HStack(spacing: 16) {
                        ForEach(Array(items.dropFirst(items.count / 2 + items.count % 2)), id: \.0) { item in
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(item.2)
                                    .frame(width: 8, height: 8)
                                Text("\(item.0)")
                                    .font(.caption)
                                Text("(\(item.1))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct AnalyticsCard: View {
    let title: String
    let value: String
    let unit: String
    let change: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                            .font(.headline)
                .foregroundColor(.primaryGradientStart)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGradientStart)
                Text(unit)
                    .font(.subheadline)
                                        .foregroundColor(.gray)
            }
            
            HStack(spacing: 4) {
                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(change >= 0 ? .green : .red)
                Text("\(abs(change), specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(change >= 0 ? .green : .red)
                                        }
                                    }
                                    .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(radius: 1)
                                }
}

struct UpdateCard: View {
    let iconName: String
    let title: String
    let description: String
    let timeAgo: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.orange)
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primaryGradientStart)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
                    Spacer()
            
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 1)
    }
}

struct FleetManagerDashboardView: View {
    @Binding var user: AppUser?
    @Binding var role: Role?
    @State private var showingProfile = false
    @StateObject private var viewModel = IFEDataController.shared
    
    var availableDrivers: Int {
        viewModel.drivers.filter { $0.status == .available && $0.activeStatus && !$0.meta_data.firstTimeLogin }.count
    }

    var onTripDrivers: Int {
        viewModel.drivers.filter { $0.status == .onTrip && $0.activeStatus && !$0.meta_data.firstTimeLogin }.count
    }
    
    var inactiveDrivers: Int {
        viewModel.drivers.filter { !$0.activeStatus }.count
    }
    
    var offlineDrivers: Int {
        viewModel.drivers.filter{$0.activeStatus && $0.meta_data.firstTimeLogin}.count
    }
    
    var availableVehicles: Int {
        viewModel.vehicles.filter { $0.status == .available && $0.activeStatus }.count
    }
    
    var assignedVehicles: Int {
        viewModel.vehicles.filter { $0.status == .assigned && $0.activeStatus}.count
    }
    
    var inactiveVehicles: Int {
        viewModel.vehicles.filter { $0.activeStatus == false }.count
    }
    
    var underMaintenanceVehicles: Int {
        viewModel.vehicles.filter { $0.status == .underMaintenance && $0.activeStatus }.count
    }
    
    var availableMaintenancePersonnel: Int {
        viewModel.maintenancePersonnels.filter { $0.activeStatus && !$0.meta_data.firstTimeLogin }.count
    }
    
    var inactiveMaintenancePersonnel: Int {
        viewModel.maintenancePersonnels.filter { !$0.activeStatus }.count
    }
    var offlineMaintenancePersonnel: Int {
        viewModel.maintenancePersonnels.filter{ $0.activeStatus && $0.meta_data.firstTimeLogin}.count
    }
    var scheduledTrips: Int {
        viewModel.trips.filter { $0.status == .scheduled }.count
    }
    var inProgressTrips: Int {
        viewModel.trips.filter { $0.status == .inProgress }.count
    }
    var completedTrips: Int {
        viewModel.trips.filter { $0.status == .completed }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Fleet Overview Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Fleet Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryGradientStart)
                    
                    ProgressBarView(
                        title: "Drivers",
                        total: viewModel.drivers.count,
                        items: [
                            (DriverStatus.available.rawValue,
                             availableDrivers,
                             Color.mint),
                            
                            (DriverStatus.onTrip.rawValue, onTripDrivers, Color.primaryGradientEnd),
                            ("Inactive", inactiveDrivers, Color.orange),
                            ("Offline", offlineDrivers, Color.gray)
                        ]
                    )
                    
                    ProgressBarView(
                        title: "Maintenance Personnel",
                        total: viewModel.maintenancePersonnels.count,
                        items: [
                            ("Available", availableMaintenancePersonnel, Color.mint),
                            ("Inactive", inactiveMaintenancePersonnel, Color.orange),
                            ("Offline", offlineMaintenancePersonnel, Color.gray)
                        ]
                    )
                    
                    ProgressBarView(
                        title: "Trucks",
                        total: viewModel.vehicles.count,
                        items: [
                            (VehicleStatus.available.rawValue, availableVehicles, Color.mint),
                            (VehicleStatus.assigned.rawValue, assignedVehicles, Color.primaryGradientEnd),
                            (VehicleStatus.underMaintenance.rawValue, underMaintenanceVehicles, Color.statusOrange),
                            (VehicleStatus.inactive.rawValue, inactiveVehicles, Color.gray)
                        ]
                    )
                    ProgressBarView(
                        title: "Trips",
                        total: viewModel.trips.count,
                        items: [
                            ("Scheduled", scheduledTrips, Color.mint),
                            ("In Progress", inProgressTrips, Color.primaryGradientStart),
                            ("Completed ", completedTrips, Color.orange)
                        ]
                    )
                }
                .padding(.horizontal)
                
                // Fleet Analytics Section
//                VStack(alignment: .leading, spacing: 16) {
//                    Text("Fleet Analytics")
//                        .font(.title2)
//                        .fontWeight(.bold)
//                        .foregroundColor(.primaryGradientStart)
//                    
//                    HStack(spacing: 16) {
//                        AnalyticsCard(
//                            title: "Fuel Consumed",
//                            value: "1250.5",
//                            unit: "L",
//                            change: 5.2
//                        )
//                        
//                        AnalyticsCard(
//                            title: "Maintenance Cost",
//                            value: "8500.0",
//                            unit: "USD",
//                            change: -2.1
//                        )
//                    }
//            }
//            .padding(.horizontal)
//                
//                // Recent Updates Section
//                VStack(alignment: .leading, spacing: 16) {
//                    Text("Recent Updates")
//                        .font(.title2)
//                        .fontWeight(.bold)
//                        .foregroundColor(.primaryGradientStart)
//                    
//                    UpdateCard(
//                        iconName: "wrench.fill",
//                        title: "Maintenance Updated",
//                        description: "Robert Brown updated maintenance status for TRK003",
//                        timeAgo: "51 sec. ago"
//                    )
//                }
//                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .refreshable {
            Task {
                await viewModel.loadDrivers()
                await viewModel.loadVehicles()
                await viewModel.loadMaintenancePersonnels()
                await viewModel.loadTrips()
                await viewModel.loadManagerAssignedMaintenanceTasks()
                await viewModel.loadVehicleCompanies()
                await viewModel.loadServiceCenters()
                await viewModel.loadServiceCenterLocations()
            }
        }
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
        .navigationTitle("Fleet Manager")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(action: {
//                    // Action for the bell button
//                }) {
//                    Image(systemName: "bell.fill")
//                        .font(.title2)
//                        .foregroundColor(.primaryGradientEnd)
//                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingProfile = true
                }) {
                    Image(systemName: "person.circle")
                        .font(.title)
                        .foregroundColor(.primaryGradientEnd)
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView(user: $user, role: $role)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $text)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(isSelected ? Color.primaryGradientStart : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterSection<T: Hashable>: View {
    let title: String
    let filters: [T]
    @Binding var selectedFilter: T
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        title: filter as! String,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
    }
}



struct FleetManagerTabBarView: View {
    @Binding var user: AppUser?
    @Binding var role : Role?
    var body: some View {
        TabView {
            NavigationView {
                FleetManagerDashboardView(user: $user, role: $role)
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            
            NavigationView {
                StaffView()
            }
            .tabItem {
                Label("Staff", systemImage: "person.2.fill")
            }
            
            NavigationView {
                VehiclesView()
            }
            .tabItem {
                Label("Vehicles", systemImage: "truck.box.fill")
            }
            
            NavigationView {
                TripsView()
            }
            .tabItem {
                Label("Trips", systemImage: "map.fill")
            }
            
            NavigationView {
                MaintenanceSchedulingView()
            }
            .tabItem {
                Label("Maintenance", systemImage: "wrench.fill")
            }
            
        }
        .accentColor(.primaryGradientEnd)
    }
}
