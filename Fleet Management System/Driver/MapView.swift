import SwiftUI
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    private var isFirstLocationUpdate = true
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        
        // Center on user location on first update
        if isFirstLocationUpdate {
            isFirstLocationUpdate = false
            centerOnUserLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Failed to get location: \(error.localizedDescription)")
    }
    
    func requestLocation() {
        let status = locationManager.authorizationStatus
        if status == .denied || status == .restricted {
            print("❌ Location access is denied or restricted.")
            return
        }
        locationManager.requestLocation()
    }
    
    func centerOnUserLocation() {
        guard let location = location else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            region = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

struct MapView: View {
    @StateObject private var viewModel = IFEDataController.shared
    @StateObject private var locationManager = LocationManager()
    @Binding var selectedTab: Int
    @State private var mapType: MapStyle = .standard
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    
    var activeTrip: Trip? {
        viewModel.tripsForDriver.first { $0.status == .inProgress }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(coordinateRegion: $locationManager.region,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode)
                    .mapStyle(mapType)
                    .edgesIgnoringSafeArea(.all)
                
                // Custom navigation bar
                VStack {
                    HStack {
                        Spacer()
                        
                        // Location button
                        Button(action: {
                            locationManager.centerOnUserLocation()
                            userTrackingMode = .follow
                        }) {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.primaryGradientStart)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        
                        // Refresh button
                        Button(action: {
                            locationManager.requestLocation()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.primaryGradientStart)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                    }
                    .padding()
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    if let trip = activeTrip {
                        // Active trip cards
                        LocationCard(trip: trip)
                        TripDetailsCard(trip: trip)
                    } else {
                        // Empty state card
                        EmptyTripCard(selectedTab: $selectedTab)
                    }
                }
                .padding()
            }
        }
    }
}

struct EmptyTripCard: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.circle")
                .font(.system(size: 60))
                .foregroundColor(.primaryGradientStart.opacity(0.8))
            
            VStack(spacing: 8) {
                Text("No Active Trip")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGradientStart)
                
                Text("Start a trip from your dashboard to see navigation details")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                selectedTab = 0 // Switch to Dashboard tab
            }) {
                Text("View Dashboard")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryGradientStart)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct LocationCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            HStack(spacing: 4) {
                Text("\(trip.totalDistance) km")
                Text("•")
                Text("Estimated")
                Text("\(trip.totalTripDuration)")
                Text("away")
            }
            .font(.caption)
            .foregroundColor(.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.statusOrange)
        .foregroundColor(.white)
        .cornerRadius(12)
    }
}

struct TripDetailsCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Driver info
            HStack(spacing: 12) {
                Image("driver_avatar")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("David Russel")
                        .fontWeight(.medium)
                    Text("Trip #\(trip.tripID)")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Text("IN PROGRESS")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusGreen.opacity(0.2))
                    .foregroundColor(.statusGreen)
                    .cornerRadius(4)
            }
            
            Text("Started at \(trip.createdAt.formatted())")
                .font(.caption)
                .foregroundColor(.textSecondary)
            
            Divider()
            
            // Trip details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trip Details")
                        .font(.headline)
                    HStack {
                        Text("Vehicle ID: \(trip.assignedVehicleID)")
                        Text("•")
                        Text("\(trip.description ?? "No description")")
                            .foregroundColor(.statusOrange)
                    }
                    .font(.subheadline)
                }
                
                Spacer()
                
                Text("ACTIVE")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.statusOrange.opacity(0.2))
                    .foregroundColor(.statusOrange)
                    .cornerRadius(4)
            }
            
            HStack {
                Text("Scheduled: \(trip.scheduledDateTime.formatted())")
                Text("•")
                Text("ETA: \(trip.estimatedArrivalDateTime.formatted())")
            }
            .font(.subheadline)
            .foregroundColor(.textSecondary)
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {}) {
                    Text("End Trip")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button(action: {}) {
                    Text("Update Status")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryGradientStart)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}

#Preview {
    MapView(selectedTab: .constant(0))
} 
