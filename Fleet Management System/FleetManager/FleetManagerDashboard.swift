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

struct VehicleStatusView: View {
    let movingCount: Int
    let stationaryCount: Int
    let maintenanceCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vehicle Status")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(movingCount) vehicles moving")
                    Spacer()
                }
                .padding()
                
                Divider()
                
                HStack {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 8, height: 8)
                    Text("\(stationaryCount) vehicles are ready to go")
                    Spacer()
                }
                .padding()
                
                Divider()
                
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("\(maintenanceCount) vehicles in maintenance")
                    Spacer()
                }
                .padding()
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 1)
        }
    }
}

struct AssignedTrip: Identifiable {
    let id = UUID()
    let driverName: String
    let vehicleNumber: String
    let startLocation: String
    let endLocation: String
    let estimatedTime: String
    let currentLocation: String
}

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer: MKLocalSearchCompleter
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
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

struct LocationSearchBar: View {
    @Binding var text: String
    let placeholder: String
    @Binding var selectedLocation: String?
    @State private var showingMap = false
    @StateObject private var searchCompleter = SearchCompleter()
    @State private var showResults = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: text, initial: false) { oldValue, newValue in
                        searchCompleter.search(with: newValue)
                        showResults = !newValue.isEmpty
                    }
                
                Button(action: { showingMap = true }) {
                    Image(systemName: "map")
                        .foregroundColor(.blue)
                }
            }
            
            if showResults && !searchCompleter.results.isEmpty {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(searchCompleter.results, id: \.self) { result in
                            Button(action: {
                                text = result.title
                                selectedLocation = result.title
                                showResults = false
                            }) {
                                VStack(alignment: .leading) {
                                    Text(result.title)
                                        .foregroundColor(.primary)
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
        .sheet(isPresented: $showingMap) {
            MapLocationPicker(selectedLocation: $selectedLocation, searchText: $text)
        }
    }
}

struct MapLocationPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: String?
    @Binding var searchText: String
    @State private var position = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
        span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 30.0)
    ))
    @State private var searchTextMap = ""
    @StateObject private var searchCompleter = SearchCompleter()
    @State private var showResults = false
    
    func getLocationName(center: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let address = [
                    placemark.name,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                selectedLocation = address
                searchText = address
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Map(position: $position) { }
                    .mapStyle(.standard)
                    .edgesIgnoringSafeArea(.all)
                    .overlay(alignment: .center) {
                        Image(systemName: "mappin")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                
                VStack {
                    HStack {
                        TextField("Search location", text: $searchTextMap)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(8)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .onChange(of: searchTextMap, initial: false) { oldValue, newValue in
                                searchCompleter.search(with: newValue)
                                showResults = !newValue.isEmpty
                            }
                    }
                    .padding()
                    
                    if showResults && !searchCompleter.results.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(searchCompleter.results, id: \.self) { result in
                                    Button(action: {
                                        searchTextMap = result.title
                                        let searchRequest = MKLocalSearch.Request(completion: result)
                                        let search = MKLocalSearch(request: searchRequest)
                                        search.start { response, error in
                                            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
                                            position = .region(MKCoordinateRegion(
                                                center: coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            ))
                                        }
                                        showResults = false
                                    }) {
                                        VStack(alignment: .leading) {
                                            Text(result.title)
                                                .foregroundColor(.primary)
                                            Text(result.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                }
                            }
                            .padding()
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if let center = position.region?.center {
                            getLocationName(center: center)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let center = position.region?.center {
                    getLocationName(center: center)
                }
            }
            .onChange(of: position) { oldValue, newValue in
                if let center = newValue.region?.center {
                    getLocationName(center: center)
                }
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Handle location updates
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

struct AssignTripView: View {
    let driver: Driver
    @Environment(\.dismiss) var dismiss
    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var selectedVehicle: Vehicle? = nil
    @State private var selectedStartLocation: String? = nil
    @State private var selectedEndLocation: String? = nil
    @State private var showingAlert = false
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var showDatePicker = false
    @State private var showTimePicker = false
    @State private var showVehiclePicker = false
    @State private var selectedDriver1: Driver? = nil
    @State private var selectedDriver2: Driver? = nil
    @State private var showDriver1Picker = false
    @State private var showDriver2Picker = false
    @ObservedObject var viewModel: DriverViewModel
    
    let availableVehicles = [
        Vehicle(number: "TN36AL5963", model: "Tata", companyName: "Tata Motors", yearOfManufacture: 2020, vin: "1234567890", plateNumber: "TN36AL5963", fuelType: "Diesel", loadCapacity: "10 tons", insuranceNumber: "1234567890", insuranceExpiry: Date(), pucNumber: "1234567890", pucExpiry: Date(), rcNumber: "1234567890", rcExpiry: Date(), currentLocation: "Bangalore", isAvailable: true, isActive: true),
        Vehicle(number: "TN36AL5964", model: "Ashok Leyland", companyName: "Ashok Leyland", yearOfManufacture: 2021, vin: "2345678901", plateNumber: "TN36AL5964", fuelType: "Diesel", loadCapacity: "15 tons", insuranceNumber: "2345678901", insuranceExpiry: Date(), pucNumber: "2345678901", pucExpiry: Date(), rcNumber: "2345678901", rcExpiry: Date(), currentLocation: "Chennai", isAvailable: true, isActive:true)
    ]
    
    var availableDrivers1: [Driver] {
        viewModel.drivers.filter { $0.isActive && $0.isAvailable }
    }

    var availableDrivers2: [Driver] {
        viewModel.drivers.filter { $0.isActive && $0.isAvailable && $0.id != selectedDriver1?.id }
    }
    
    var isFormValid: Bool {
        !startLocation.isEmpty &&
        !endLocation.isEmpty &&
        selectedVehicle != nil &&
        selectedDriver1 != nil
    }
    
    var body: some View {
        NavigationView {  
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    LocationSearchBar(
                        text: $startLocation,
                        placeholder: "Pickup Location",
                        selectedLocation: $selectedStartLocation
                    )
                    
                    LocationSearchBar(
                        text: $endLocation,
                        placeholder: "Drop-off Location",
                        selectedLocation: $selectedEndLocation
                    )
                    
                    VStack {
                        Button(action: { showDatePicker.toggle() }) {
                            HStack {
                                Text("Date")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if showDatePicker {
                            DatePicker(
                                "Select Date",
                                selection: $selectedDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .transition(.opacity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    VStack {
                        Button(action: { showTimePicker.toggle() }) {
                            HStack {
                                Text("Time")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedTime.formatted(date: .omitted, time: .shortened))
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showTimePicker ? 90 : 0))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if showTimePicker {
                            DatePicker(
                                "Select Time",
                                selection: $selectedTime,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .transition(.opacity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    VStack {
                        Button(action: { withAnimation { showVehiclePicker.toggle() } }) {
                            HStack {
                                Text("Vehicle")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedVehicle?.number ?? "Select Vehicle")
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showVehiclePicker ? 90 : 0))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if showVehiclePicker {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(availableVehicles) { vehicle in
                                    Button(action: {
                                        selectedVehicle = vehicle
                                        withAnimation { showVehiclePicker = false }
                                    }) {
                                        HStack {
                                            Text(vehicle.number)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if selectedVehicle == vehicle {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    if vehicle != availableVehicles.last {
                                        Divider()
                                    }
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    VStack {
                        Button(action: { showDriver1Picker.toggle() }) {
                            HStack {
                                Text("Driver 1")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedDriver1?.name ?? "Select Driver 1")
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showDriver1Picker ? 90 : 0))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if showDriver1Picker {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(availableDrivers1) { driver in
                                    Button(action: {
                                        selectedDriver1 = driver
                                        if selectedDriver2?.id == driver.id {
                                            selectedDriver2 = nil
                                        }
                                        withAnimation { showDriver1Picker = false }
                                    }) {
                                        HStack {
                                            Text(driver.name)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if selectedDriver1 == driver {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    if driver != availableDrivers1.last {
                                        Divider()
                                    }
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    VStack {
                        Button(action: { showDriver2Picker.toggle() }) {
                            HStack {
                                Text("Driver 2")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedDriver2?.name ?? "Select Driver 2")
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showDriver2Picker ? 90 : 0))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if showDriver2Picker {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(availableDrivers2) { driver in
                                    Button(action: {
                                        selectedDriver2 = driver
                                        withAnimation { showDriver2Picker = false }
                                    }) {
                                        HStack {
                                            Text(driver.name)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if selectedDriver2 == driver {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    if driver != availableDrivers2.last {
                                        Divider()
                                    }
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Assign Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let newTrip = AssignedTrip(
                            driverName: [selectedDriver1?.name, selectedDriver2?.name]
                                .compactMap { $0 }
                                .joined(separator: ", "),
                            vehicleNumber: selectedVehicle?.number ?? "",
                            startLocation: startLocation,
                            endLocation: endLocation,
                            estimatedTime: selectedTime.formatted(date: .omitted, time: .shortened),
                            currentLocation: "Bangalore"
                        )
                        
                        viewModel.assignedTrips.append(newTrip)
                        showingAlert = true
                    }
                    .disabled(!isFormValid)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Trip assigned successfully")
            }
        }
    }
}



struct FleetManagerDashboardView: View {
    @StateObject private var viewModel = DriverViewModel()
    
    @State private var assignedTrips: [AssignedTrip] = []
    @State private var showTripDetails = false
    @State private var selectedTrip: AssignedTrip?
    @State private var showAssignTrip = false
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        DashboardCard(title: "Total Vehicles", value: "163", color: .orange)
                        DashboardCard(title: "Total Drivers", value: "45", color: .blue)
                    }
                    
                    VehicleStatusView(movingCount: 3, stationaryCount: 3, maintenanceCount: 50)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assigned Trips")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if viewModel.assignedTrips.isEmpty {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("No trips assigned")
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding()
                            }
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 1)
                        } else {
                            ForEach(viewModel.assignedTrips) { trip in
                                Button(action: {
                                    selectedTrip = trip
                                    showTripDetails = true
                                }) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Text("Trip ID: TRP-2024-001")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.teal)
                                        }
                                        
                                        Text("Tata Prima LX 2823.K")
                                            .font(.body)
                                            .foregroundColor(.gray)
                                        Text("MH 04 HJ 1234")
                                            .foregroundColor(.orange)
                                        
                                        Text("Today • Electronics, 2500 kg")
                                            .foregroundColor(.gray)
                                        
                                        VStack(alignment: .leading, spacing: 16) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Pickup")
                                                    .foregroundColor(.gray)
                                                HStack(spacing: 8) {
                                                    Circle()
                                                        .fill(Color.teal)
                                                        .frame(width: 8, height: 8)
                                                    Text(trip.startLocation)
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Drop-off")
                                                    .foregroundColor(.gray)
                                                HStack(spacing: 8) {
                                                    Circle()
                                                        .fill(Color.orange)
                                                        .frame(width: 8, height: 8)
                                                    Text(trip.endLocation)
                                                }
                                            }
                                        }
                                        
                                        HStack {
                                            Image(systemName: "arrow.up.right")
                                                .foregroundColor(.teal)
                                            Text("985 km - 14 hours")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(radius: 1)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding()
            }

            Button(action: { showAssignTrip = true }) {
                HStack {
                    Text("Assign a Trip")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(radius: 1)
            }
            .padding(.horizontal)
            .padding(.bottom)
            .sheet(isPresented: $showAssignTrip) {
                AssignTripView(
                    driver: Driver(name: "", totalTrips: 0, licenseNumber: "", emailId: "", employeeId: "", phoneNumber: "", isAvailable: true, isActive: true),
                    viewModel: viewModel
                )
            }
        }
        .navigationTitle("Dashboard")
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
        .onAppear {
            if viewModel.drivers.isEmpty {
                viewModel.drivers = [
                    Driver(name: "John Doe", totalTrips: 125, licenseNumber: "DL123456", emailId: "john@example.com", employeeId: "EMP001", phoneNumber: "+1234567890", isAvailable: true, isActive: true),
                    Driver(name: "Jane Smith", totalTrips: 98, licenseNumber: "DL789012", emailId: "jane@example.com", employeeId: "EMP002", phoneNumber: "+0987654321", isAvailable: false, isActive: true),
                    Driver(name: "Mike Johnson", totalTrips: 156, licenseNumber: "DL345678", emailId: "mike@example.com", employeeId: "EMP003", phoneNumber: "+1122334455", isAvailable: true, isActive: true),
                    Driver(name: "Sarah Wilson", totalTrips: 112, licenseNumber: "DL456789", emailId: "sarah@example.com", employeeId: "EMP004", phoneNumber: "+2233445566", isAvailable: true, isActive: true),
                    Driver(name: "David Brown", totalTrips: 143, licenseNumber: "DL567890", emailId: "david@example.com", employeeId: "EMP005", phoneNumber: "+3344556677", isAvailable: true, isActive: true),
                    Driver(name: "Emma Davis", totalTrips: 87, licenseNumber: "DL678901", emailId: "emma@example.com", employeeId: "EMP006", phoneNumber: "+4455667788", isAvailable: true, isActive: true),
                    Driver(name: "James Wilson", totalTrips: 165, licenseNumber: "DL789012", emailId: "james@example.com", employeeId: "EMP007", phoneNumber: "+5566778899", isAvailable: true, isActive: true),
                    Driver(name: "Linda Taylor", totalTrips: 134, licenseNumber: "DL890123", emailId: "linda@example.com", employeeId: "EMP008", phoneNumber: "+6677889900", isAvailable: true, isActive: true),
                    Driver(name: "Robert Martin", totalTrips: 145, licenseNumber: "DL901234", emailId: "robert@example.com", employeeId: "EMP009", phoneNumber: "+7788990011", isAvailable: true, isActive: true),
                    Driver(name: "Mary Anderson", totalTrips: 98, licenseNumber: "DL012345", emailId: "mary@example.com", employeeId: "EMP010", phoneNumber: "+8899001122", isAvailable: true, isActive: true),
                    Driver(name: "William Clark", totalTrips: 178, licenseNumber: "DL123456", emailId: "william@example.com", employeeId: "EMP011", phoneNumber: "+9900112233", isAvailable: true, isActive: true),
                    Driver(name: "Patricia Lee", totalTrips: 132, licenseNumber: "DL234567", emailId: "patricia@example.com", employeeId: "EMP012", phoneNumber: "+0011223344", isAvailable: true, isActive: true),
                    Driver(name: "Richard Hall", totalTrips: 156, licenseNumber: "DL345678", emailId: "richard@example.com", employeeId: "EMP013", phoneNumber: "+1122334455", isAvailable: true, isActive: true),
                    Driver(name: "Barbara White", totalTrips: 123, licenseNumber: "DL456789", emailId: "barbara@example.com", employeeId: "EMP014", phoneNumber: "+2233445566", isAvailable: true, isActive: true),
                    Driver(name: "Michael King", totalTrips: 167, licenseNumber: "DL567890", emailId: "michael@example.com", employeeId: "EMP015", phoneNumber: "+3344556677", isAvailable: true, isActive: true)
                ]
            }
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
                .background(isSelected ? Color.black : Color(.systemGray6))
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
    var body: some View {
        TabView {
            NavigationView {
                FleetManagerDashboardView()
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Dashboard")
            }
            
            NavigationView {
                DriversView()
            }
            .tabItem {
                Image(systemName: "person.2.fill")
                Text("Drivers")
            }
            
            NavigationView {
                VehiclesView()
            }
            .tabItem {
                Image(systemName: "car.fill")
                Text("Vehicles")
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
