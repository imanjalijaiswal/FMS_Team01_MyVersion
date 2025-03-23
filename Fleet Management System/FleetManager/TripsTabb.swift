//
//  TripsTabb.swift
//  Fleet Management System
//
//  Created by Aakash Singh on 21/03/25.
//
import SwiftUI
import MapKit


struct TripsView: View {
    @State private var showingAddNewTrip = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @StateObject private var viewModel = IFEDataController.shared
    
    let filters = ["All", "Scheduled", "In Progress", "Completed"]
    
    var filteredTrips: [Trip] {
        let searchResults = viewModel.trips.filter { trip in
            if searchText.isEmpty { return true }
            
            let driverNames = trip.assignedDriverIDs.compactMap { driverId in
                viewModel.drivers.first { $0.id == driverId }?.meta_data.fullName
            }.joined(separator: ", ")
            
            let vehicleNumber = viewModel.vehicles.first { $0.id == trip.assigneVehicleID }?.vinNumber ?? ""
            
            return driverNames.localizedCaseInsensitiveContains(searchText) ||
                   vehicleNumber.localizedCaseInsensitiveContains(searchText) ||
                   trip.pickupLocation.localizedCaseInsensitiveContains(searchText) ||
                   trip.destination.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter{
            
            case "In Progress":
                return searchResults.filter { $0.status == TripStatus.inProgress }
            case "Completed":
                return searchResults.filter { $0.status == TripStatus.completed }
            case "Scheduled":
                return searchResults.filter { $0.status == TripStatus.scheduled }
            default:
                return searchResults
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SearchBar(text: $searchText)
                .padding(.top, 8)
            
            FilterSection(
                title: "",
                filters: filters,
                selectedFilter: $selectedFilter
            )
            
            ScrollView {
                VStack(spacing: 16) {
                    if filteredTrips.isEmpty {
                        Text("No trips available")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(filteredTrips) { trip in
                            TripCard(trip: trip, viewModel: viewModel)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Trips")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingAddNewTrip = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.primaryGradientEnd)
                }
                .sheet(isPresented: $showingAddNewTrip) {
                    AssignTripView(viewModel: viewModel)
                }
            }
        }
        .background(.white)
    }
}

struct TripCard: View {
    let trip: Trip
    @ObservedObject var viewModel: IFEDataController
    @State private var showingStatusSheet = false
    
    var driverNames: String {
        trip.assignedDriverIDs.compactMap { driverId in
            viewModel.drivers.first { $0.id == driverId }?.meta_data.fullName
        }.joined(separator: ", ")
    }
    
    var vehicleNumber: String {
        viewModel.vehicles.first { $0.id == trip.assigneVehicleID }?.vinNumber ?? "Unknown Vehicle"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(driverNames)
                        .font(.headline)
                    Text(vehicleNumber)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Button(action: {
                    showingStatusSheet = true
                }) {
                    StatusBadge(status: trip.status)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                LocationRow(title: "From", location: trip.pickupLocation)
                LocationRow(title: "To", location: trip.destination)
            }
            
            if let description = trip.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            
            HStack {
                Label(trip.scheduledDateTime.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Label("\(trip.totalDistance) km", systemImage: "arrow.left.and.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Label("ETA: \(trip.estimatedArrivalDateTime.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .actionSheet(isPresented: $showingStatusSheet) {
            let buttons: [ActionSheet.Button] = {
                switch trip.status {
                case .scheduled:
                    return [
                        .default(Text("Mark as In Progress")) {
                            viewModel.updateTripStatus(trip, to: .inProgress)
                        },
                        .cancel()
                    ]
                case .inProgress:
                    return [
                        .default(Text("Mark as Completed")) {
                            viewModel.updateTripStatus(trip, to: .completed)
                        },
                        .cancel()
                    ]
                case .completed:
                    return [.cancel()]
                }
            }()
            
            return ActionSheet(
                title: Text("Update Trip Status"),
                message: nil,
                buttons: buttons
            )
        }
    }
}

struct AssignTripView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IFEDataController
    
    @State private var pickupLocation = ""
    @State private var destination = ""
    @State private var selectedVehicle: Vehicle? = nil
    @State private var selectedStartLocation: String? = nil
    @State private var selectedEndLocation: String? = nil
    @State private var showingAlert = false
    @State private var scheduledDateTime = Date()
    @State private var estimatedArrivalDateTime = Date()
    @State private var showScheduledDatePicker = false
    @State private var showEstimatedDatePicker = false
    @State private var showVehiclePicker = false
    @State private var selectedDriver1: Driver? = nil
    @State private var selectedDriver2: Driver? = nil
    @State private var showDriver1Selection = false
    @State private var showDriver2Selection = false
    @State private var tripDescription = ""
    @State private var totalDistance = ""
    
    var isFormValid: Bool {
        !pickupLocation.isEmpty &&
        !destination.isEmpty &&
        selectedVehicle != nil &&
        selectedDriver1 != nil &&
        !totalDistance.isEmpty &&
        Int(totalDistance) != nil
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LocationSearchBar(
                        text: $pickupLocation,
                        placeholder: "Pickup Location",
                        selectedLocation: $selectedStartLocation
                    )
                    
                    LocationSearchBar(
                        text: $destination,
                        placeholder: "Drop-off Location",
                        selectedLocation: $selectedEndLocation
                    )
                    
                    // Scheduled Date Time
                    VStack {
                        Button(action: { showScheduledDatePicker.toggle() }) {
                            HStack {
                                Text("Scheduled Date & Time")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(scheduledDateTime.formatted())
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showScheduledDatePicker ? 90 : 0))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if showScheduledDatePicker {
                            DatePicker(
                                "Scheduled Date & Time",
                                selection: $scheduledDateTime
                            )
                            .datePickerStyle(.graphical)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Estimated Arrival
                    VStack {
                        Button(action: { showEstimatedDatePicker.toggle() }) {
                            HStack {
                                Text("Estimated Arrival")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(estimatedArrivalDateTime.formatted())
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .rotationEffect(.degrees(showEstimatedDatePicker ? 90 : 0))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if showEstimatedDatePicker {
                            DatePicker(
                                "Estimated Arrival",
                                selection: $estimatedArrivalDateTime
                            )
                            .datePickerStyle(.graphical)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Total Distance
                    TextField("Total Distance (km)", text: $totalDistance)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    // Description
                    TextField("Trip Description (Optional)", text: $tripDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    // Vehicle Selection
                    VStack {
                        Button(action: { showVehiclePicker.toggle() }) {
                            HStack {
                                Text("Vehicle")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedVehicle?.vinNumber ?? "Select Vehicle")
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .sheet(isPresented: $showVehiclePicker) {
                    VehicleSelectionView(viewModel: viewModel, selectedVehicle: $selectedVehicle)
                    }

                    // Driver Selection
                    VStack {
                        Button(action: { showDriver1Selection = true }) {
                            HStack {
                                Text("Driver 1")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedDriver1?.meta_data.fullName ?? "Select Driver 1")
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .sheet(isPresented: $showDriver1Selection) {
                        DriverSelectionView(viewModel: viewModel, selectedDriver: $selectedDriver1, excludeDriver: selectedDriver2)
                    }

                    VStack {
                        Button(action: { showDriver2Selection = true }) {
                            HStack {
                                Text("Driver 2 (Optional)")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(selectedDriver2?.meta_data.fullName ?? "Select Driver 2")
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .sheet(isPresented: $showDriver2Selection) {
                        DriverSelectionView(viewModel: viewModel, selectedDriver: $selectedDriver2, excludeDriver: selectedDriver1)
                    }
                }
                .padding()
            }
            .navigationTitle("Assign Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let newTrip = Trip(
                            id: UUID(),
                            tripID: Int.random(in: 1000...9999),
                            assignedByFleetManagerID: UUID(),
                            assignedDriverIDs: [selectedDriver1, selectedDriver2].compactMap { $0?.id },
                            assigneVehicleID: selectedVehicle?.id ?? 0,
                            pickupLocation: pickupLocation,
                            destination: destination,
                            estimatedArrivalDateTime: estimatedArrivalDateTime,
                            totalDistance: Int(totalDistance) ?? 0,
                            totalTripDuration: estimatedArrivalDateTime,
                            description: tripDescription.isEmpty ? nil : tripDescription,
                            scheduledDateTime: scheduledDateTime,
                            status: .scheduled
                        )
                        
                        viewModel.addTrip(newTrip)
                        showingAlert = true
                    }
                    .foregroundColor(Color.primaryGradientEnd)
                    .disabled(!isFormValid)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.primaryGradientEnd)
                }
            }
            .alert("Success", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
                .foregroundColor(Color.primaryGradientEnd)
            } message: {
                Text("Trip assigned successfully")
            }
        }
    }
}
struct DriversRowView: View {
    let driver: Driver
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(driver.meta_data.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("ID: \(driver.employeeID)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack {
                    Label(driver.meta_data.phone, systemImage: "phone.fill")
                        .font(.caption)
                        .foregroundColor(.gray)

                }

                HStack {
                    Label("License: \(driver.licenseNumber)", systemImage: "car.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DriverSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IFEDataController
    @Binding var selectedDriver: Driver?
    let excludeDriver: Driver?
    
    var availableDrivers: [Driver] {
        viewModel.drivers.filter { driver in
            driver.activeStatus &&
            driver.status == .available &&
            driver.role == .driver
            &&
            driver.id != excludeDriver?.id
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if availableDrivers.isEmpty {
                    Text("No available drivers")
                        .foregroundColor(.gray)
                } else {
                    ForEach(availableDrivers) { driver in
                        Button(action: {
                            selectedDriver = driver
                            dismiss()
                        }) {
                            DriversRowView(driver: driver, isSelected: selectedDriver?.id == driver.id)
                        }
                    }
                }
            }
            .navigationTitle("Select Driver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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

struct LocationRow: View {
    let title: String
    let location: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(location)
                .font(.subheadline)
        }
    }
}

struct StatusBadge: View {
    let status: TripStatus
    
    var statusColor: Color {
        switch status {
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .scheduled:
            return .orange
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
    }
}

struct VehicleSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IFEDataController
    @Binding var selectedVehicle: Vehicle?
    
    var availableVehicles: [Vehicle] {
        viewModel.vehicles.filter { vehicle in
            vehicle.status == .available && vehicle.activeStatus
        }
    }
    
    var body: some View {
        NavigationView {
            List(availableVehicles) { vehicle in
                Button(action: {
                    selectedVehicle = vehicle
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vehicle.model)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(vehicle.make) • \(vehicle.licenseNumber)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Label("VIN: \(vehicle.vinNumber)", systemImage: "number")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Label("\(vehicle.loadCapacity) tons", systemImage: "scalemass")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Label(vehicle.fuelType.rawValue, systemImage: "fuelpump.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Label(vehicle.currentCoordinate, systemImage: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            HStack {
                                Label("Insurance: \(vehicle.insurancePolicyNumber)", systemImage: "checkmark.shield.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Label("Expires: \(vehicle.insuranceExpiryDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        if selectedVehicle?.id == vehicle.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}



