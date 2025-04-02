//
//  TripsTabb.swift
//  Fleet Management System
//
//  Created by Aakash Singh on 21/03/25.
//
import SwiftUI
import MapKit
import CoreLocation

struct TripsView: View {
    @State private var showingAddNewTrip = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @StateObject private var viewModel = IFEDataController.shared
    @State private var isRefreshing = false
    @State private var viewRefreshTrigger = UUID()
    
    let filters = ["All", "Scheduled", "In Progress", "Completed"]
    
    var filteredTrips: [Trip] {
        let searchResults = viewModel.trips.filter { trip in
            if searchText.isEmpty { return true }
            
            let driverNames = trip.assignedDriverIDs.compactMap { driverId in
                viewModel.drivers.first { $0.id == driverId }?.meta_data.fullName
            }.joined(separator: ", ")
            
            let vehicleNumber = viewModel.vehicles.first { $0.id == trip.assignedVehicleID }?.vinNumber ?? ""
            
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
    
    func refreshData() {
        self.isRefreshing = true
        
        Task {
            await viewModel.loadTrips()
            await viewModel.loadVehicles()
            await viewModel.loadDrivers()
            
            DispatchQueue.main.async {
                self.isRefreshing = false
                self.viewRefreshTrigger = UUID() // Force view update
            }
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
            .id(viewRefreshTrigger)
            
            ScrollView {
                PullToRefresh(coordinateSpaceName: "tripsPullToRefresh", onRefresh: refreshData, isRefreshing: isRefreshing)
                
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
                .id(viewRefreshTrigger)
            }
            .coordinateSpace(name: "tripsPullToRefresh")
        }
        .id(viewRefreshTrigger)
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
            
//            ToolbarItem(placement: .topBarLeading) {
//                Button(action: refreshData) {
//                    Image(systemName: "arrow.clockwise")
//                        .foregroundColor(.primaryGradientEnd)
//                }
//            }
        }
        .background(.white)
    }
}

struct TripCard: View {
    let trip: Trip
    @ObservedObject var viewModel: IFEDataController
    @State private var showingStatusSheet = false
    @State private var pickupAddress: String = "Fetching address..."
    @State private var destinationAddress: String = "Fetching address..."
    var driverNames: String {
        trip.assignedDriverIDs.compactMap { driverId in
            viewModel.drivers.first { $0.id == driverId }?.meta_data.fullName
        }.joined(separator: ", ")
    }
    
    var vehicleNumber: String {
        if let vehicle = viewModel.vehicles.first(where: { $0.id == trip.assignedVehicleID }) {
            return "\(vehicle.make) • \(vehicle.licenseNumber)"
        }
        return "Unknown Vehicle"
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
                StatusBadge(status: trip.status)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                LocationRow(title: "From", location: pickupAddress)
                LocationRow(title: "To", location: destinationAddress)
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
        .onAppear {
            getAddress(from: trip.destination) { result in
                if let result = result {
                    destinationAddress = result
                } else {
                    destinationAddress = "Address not found"
                }
            }
            getAddress(from: trip.pickupLocation) { result in
                if let result = result {
                    pickupAddress = result
                } else {
                    pickupAddress = "Address not found"
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
    @State private var selectedStartCoordinates: String? = nil
    @State private var selectedEndCoordinates: String? = nil
    @State private var showingAlert = false
    @State private var scheduledDateTime = Date()
    @State private var estimatedArrivalDateTime = Date()
    @State private var showScheduledDatePicker = false
    @State private var showVehiclePicker = false
    @State private var selectedDriver1: Driver? = nil
    @State private var selectedDriver2: Driver? = nil
    @State private var showDriver1Selection = false
    @State private var showDriver2Selection = false
    @State private var tripDescription = ""
    @State private var pickupAddress: String = "Fetching address..."
    @State private var destinationAddress: String = "Fetching address..."
    @State private var isCalculatingDistance = false
    @State private var calculatedDistance: Double? = nil

    var isFormValid: Bool {
        !pickupLocation.isEmpty &&
        !destination.isEmpty &&
        selectedVehicle != nil &&
        selectedDriver1 != nil &&
        selectedStartCoordinates != nil &&
        selectedEndCoordinates != nil &&
        calculatedDistance != nil
    }

    var totalDrivingHours: Double {
        guard let distance = calculatedDistance else { return 0 }
        // Assuming average speed of 50 km/h
        return distance / 50000 // Convert meters to hours
    }

    var maxDailyDrivingHours: Double {
        // One driver can drive up to 10 hours, two drivers can drive up to 20 hours
        return selectedDriver2 != nil ? 20.0 : 10.0
    }

    var requiredDays: Int {
        Int(ceil(totalDrivingHours / maxDailyDrivingHours))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LocationSearchBar(
                        text: $pickupLocation,
                        placeholder: "Pickup Location",
                        selectedLocation: $selectedStartLocation,
                        selectedCoordinates: $selectedStartCoordinates
                    )

                    LocationSearchBar(
                        text: $destination,
                        placeholder: "Drop-off Location",
                        selectedLocation: $selectedEndLocation,
                        selectedCoordinates: $selectedEndCoordinates
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
                                selection: $scheduledDateTime,
                                in: Calendar.current.date(byAdding: .day, value: 1, to: Date())!...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .onAppear {
                                scheduledDateTime = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            }
                            .onChange(of: scheduledDateTime) { oldValue, newValue in
                                updateEstimatedArrivalTime()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Estimated Arrival (Read-only)
                    VStack(alignment: .leading) {
                        Text("Estimated Arrival")
                            .foregroundColor(.primary)
                        HStack {
                            Text(estimatedArrivalDateTime.formatted())
                                .foregroundColor(.gray)
                            Spacer()
                            if let distance = calculatedDistance {
                                Text("\(Int(distance/1000)) km")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
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

                    if isCalculatingDistance {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Calculating route distance...")
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else if let distance = calculatedDistance {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Route Details")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Label("\(Int(distance/1000)) km", systemImage: "arrow.left.and.right")
                                Spacer()
                                Label("\(Int(totalDrivingHours))h \(Int((totalDrivingHours.truncatingRemainder(dividingBy: 1)) * 60))m", systemImage: "clock")
                            }
                            .foregroundColor(.gray)
                            
                            if requiredDays > 1 {
                                Text("Note: This trip will require \(requiredDays) days to complete")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("Assign Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            if let startCoordinates = selectedStartCoordinates,
                               let endCoordinates = selectedEndCoordinates,
                               let distance = calculatedDistance {
                                let newTrip = Trip(
                                    id: UUID(),
                                    tripID: Int.random(in: 1000...9999),
                                    assignedByFleetManagerID: UUID(),
                                    assignedDriverIDs: [selectedDriver1, selectedDriver2].compactMap { $0?.id },
                                    assignedVehicleID: selectedVehicle?.id ?? 0,
                                    pickupLocation: startCoordinates,
                                    destination: endCoordinates,
                                    estimatedArrivalDateTime: estimatedArrivalDateTime,
                                    totalDistance: Int(distance/1000),
                                    totalTripDuration: estimatedDate(from: scheduledDateTime, hours: Float(totalDrivingHours)),
                                    description: tripDescription.isEmpty ? "InFleet Express Trip" : tripDescription,
                                    scheduledDateTime: scheduledDateTime,
                                    createdAt: .now,
                                    status: .scheduled
                                )

                                viewModel.addTrip(newTrip)
                                showingAlert = true
                            }
                        }
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
            .onChange(of: selectedEndCoordinates) { oldValue, newValue in
                if let start = selectedStartCoordinates,
                   let end = newValue {
                    isCalculatingDistance = true
                    calculateDistance(from: start, to: end) { distance in
                        DispatchQueue.main.async {
                            calculatedDistance = distance
                            isCalculatingDistance = false
                            updateEstimatedArrivalTime()
                        }
                    }
                }
            }
            .onChange(of: selectedDriver2) { oldValue, newValue in
                updateEstimatedArrivalTime()
            }
        }
    }
    
    private func updateEstimatedArrivalTime() {
        if let distance = calculatedDistance {
            let totalHours = distance / 50000 // Convert meters to hours
            let totalMinutes = Int((totalHours.truncatingRemainder(dividingBy: 1)) * 60)
            let totalWholeHours = Int(totalHours)
            
            // Calculate how many full days are needed
            let maxDailyHours = maxDailyDrivingHours
            let fullDays = totalWholeHours / Int(maxDailyHours)
            let remainingHours = totalWholeHours % Int(maxDailyHours)
            
            // Create a new date starting from scheduled date
            var arrivalDate = scheduledDateTime
            
            // Add full days if needed
            if fullDays > 0 {
                arrivalDate = Calendar.current.date(byAdding: .day, value: fullDays, to: arrivalDate) ?? arrivalDate
            }
            
            // Add remaining hours and minutes
            if remainingHours > 0 {
                arrivalDate = Calendar.current.date(byAdding: .hour, value: remainingHours, to: arrivalDate) ?? arrivalDate
            }
            if totalMinutes > 0 {
                arrivalDate = Calendar.current.date(byAdding: .minute, value: totalMinutes, to: arrivalDate) ?? arrivalDate
            }
            
            estimatedArrivalDateTime = arrivalDate
        }
    }
}

func calculateDistance(from startCoordinate: String, to endCoordinate: String, completion: @escaping (Double?) -> Void) {
    let startComponents = startCoordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    let endComponents = endCoordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

    guard startComponents.count == 2, endComponents.count == 2,
          let startLatitude = Double(startComponents[0]),
          let startLongitude = Double(startComponents[1]),
          let endLatitude = Double(endComponents[0]),
          let endLongitude = Double(endComponents[1]) else {
        print("Invalid coordinate format")
        completion(nil)
        return
    }

    let startLocation = CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    let endLocation = CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)

    // Create a route request
    let request = MKDirections.Request()
    request.source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation))
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation))
    request.transportType = .automobile

    // Calculate the route
    let directions = MKDirections(request: request)
    directions.calculate { response, error in
        if let error = error {
            print("Error calculating route: \(error)")
            // Fallback to straight-line distance if route calculation fails
            let startLoc = CLLocation(latitude: startLatitude, longitude: startLongitude)
            let endLoc = CLLocation(latitude: endLatitude, longitude: endLongitude)
            completion(startLoc.distance(from: endLoc))
            return
        }
        
        if let route = response?.routes.first {
            completion(route.distance)
        } else {
            // Fallback to straight-line distance if no route found
            let startLoc = CLLocation(latitude: startLatitude, longitude: startLongitude)
            let endLoc = CLLocation(latitude: endLatitude, longitude: endLongitude)
            completion(startLoc.distance(from: endLoc))
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
                .foregroundColor(Color.primaryGradientStart)

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

import SwiftUI

struct DriverSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IFEDataController
    @Binding var selectedDriver: Driver?
    let excludeDriver: Driver?
    @State private var searchText = ""
    @State private var temporarySelectedDriver: Driver? // Holds selection until confirmed

    var availableDrivers: [Driver] {
        let drivers = viewModel.drivers.filter { driver in
            driver.activeStatus &&
            driver.status == .available &&
            driver.role == .driver &&
            driver.meta_data.firstTimeLogin == false &&
            driver.id != excludeDriver?.id
        }
        
        if searchText.isEmpty {
            return drivers
        }
        
        return drivers.filter { driver in
            driver.meta_data.fullName.lowercased().contains(searchText.lowercased()) ||
            String(driver.employeeID).contains(searchText) ||
            driver.meta_data.phone.contains(searchText) ||
            driver.licenseNumber.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.vertical, 8)
                
                if availableDrivers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(searchText.isEmpty ? "No available drivers" : "No matching drivers")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Add a "No Driver" option at the top
                            Button(action: {
                                temporarySelectedDriver = nil
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("No Driver")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("Remove driver selection")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    if temporarySelectedDriver == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            ForEach(availableDrivers) { driver in
                                Button(action: {
                                    if temporarySelectedDriver?.id == driver.id {
                                        // Deselect if already selected
                                        temporarySelectedDriver = nil
                                    } else {
                                        // Select new driver
                                        temporarySelectedDriver = driver
                                    }
                                }) {
                                    DriversRowView(
                                        driver: driver,
                                        isSelected: temporarySelectedDriver?.id == driver.id
                                    )
                                    .padding(.vertical, 8)
                                    .padding(.horizontal)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color.white)
                }
            }
            .navigationTitle("Select Driver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGradientEnd)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedDriver = temporarySelectedDriver
                        dismiss()
                    }
                    .foregroundColor(Color.primaryGradientStart)
                }
            }
            .toolbarBackground(Color(.white), for: .navigationBar)
            .background(Color.white)
        }.onAppear{
            temporarySelectedDriver = selectedDriver
        }
    }
}

struct LocationSearchBar: View {
    @Binding var text: String
    let placeholder: String
    @Binding var selectedLocation: String?
    @Binding var selectedCoordinates: String?
    @State private var showingMap = false
    @StateObject private var searchCompleter = SearchCompleter()
    @State private var showResults = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField(placeholder, text: $text)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .onChange(of: text, initial: false) { oldValue, newValue in
                        searchCompleter.search(with: newValue)
                        showResults = !newValue.isEmpty
                    }
                
                Button(action: { showingMap = true }) {
                    Image(systemName: "map")
                        .foregroundColor(.primaryGradientStart)
                }
            }
            
            if showResults && !searchCompleter.results.isEmpty {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(searchCompleter.results, id: \.self) { result in
                            Button(action: {
                                let searchRequest = MKLocalSearch.Request(completion: result)
                                let search = MKLocalSearch(request: searchRequest)
                                search.start { response, error in
                                    guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
                                    text = result.title
                                    selectedLocation = result.title
                                    selectedCoordinates = "\(coordinate.latitude), \(coordinate.longitude)"
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
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(radius: 2)
            }
        }
        .sheet(isPresented: $showingMap) {
            MapLocationPicker(selectedLocation: $selectedLocation, selectedCoordinates: $selectedCoordinates, searchText: $text)
        }
    }
}

struct MapLocationPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: String?
    @Binding var selectedCoordinates: String?
    @Binding var searchText: String
    @State private var position = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
        span: MKCoordinateSpan(latitudeDelta: 30.0, longitudeDelta: 30.0)
    ))
    @State private var searchTextMap = ""
    @StateObject private var searchCompleter = SearchCompleter()
    @State private var showResults = false
    @State private var currentSearchResult: MKLocalSearchCompletion?
    
    func getLocationName(center: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                if let currentResult = currentSearchResult {
                    // If we have a search result, use its title instead of reverse geocoding
                    selectedLocation = currentResult.title
                    searchText = currentResult.title
                } else {
                    // Fallback to reverse geocoded address
                    let address = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                    selectedLocation = address
                    searchText = address
                }
                selectedCoordinates = "\(center.latitude), \(center.longitude)"
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
                                        currentSearchResult = result
                                        let searchRequest = MKLocalSearch.Request(completion: result)
                                        let search = MKLocalSearch(request: searchRequest)
                                        search.start { response, error in
                                            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
                                            position = .region(MKCoordinateRegion(
                                                center: coordinate,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            ))
                                            selectedLocation = result.title
                                            selectedCoordinates = "\(coordinate.latitude), \(coordinate.longitude)"
                                            searchText = result.title
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
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .leading)
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

//VehicleSelectionView
struct VehicleCardContent: View {
    let vehicle: Vehicle
    let isSelected: Bool
    let vehicleAddress: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "truck.box.fill")
                .font(.system(size: 40))
                .foregroundColor(Color.setForegroundColor(vehicle: vehicle))
            
            VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 4){
                        Text(vehicle.model)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(vehicle.make) • \(vehicle.licenseNumber)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                Label(vehicleAddress, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.trailing, 5)
                // Fuel and Weight
        
                    Label(vehicle.fuelType.rawValue, systemImage: "fuelpump.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
               
                    
                    Label("\(Int(vehicle.loadCapacity)) tons", systemImage: "scalemass.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                
                // Insurance Info
                
                VStack(alignment: .leading, spacing: 4){
                    Label("Insurance Details:", systemImage: "checkmark.shield.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading){
                        Text("Insurance Number: \(vehicle.insurancePolicyNumber)")
                        .font(.caption)
                        .foregroundColor(.gray)
                       
                        Text("Expires At: \(vehicle.insuranceExpiryDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(.leading, 15)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

import SwiftUI
import CoreLocation

import SwiftUI
import CoreLocation

struct VehicleSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: IFEDataController
    @Binding var selectedVehicle: Vehicle?
    @State private var searchText = ""
    @State private var vehicleAddresses: [Int: String] = [:]
    @State private var temporarySelectedVehicle: Vehicle? // Holds the selection until confirmed
    
    var availableVehicles: [Vehicle] {
        let vehicles = viewModel.vehicles.filter { vehicle in
            vehicle.status == .available && vehicle.activeStatus
        }
        
        if searchText.isEmpty {
            return vehicles
        }
        
        return vehicles.filter { vehicle in
            vehicle.model.lowercased().contains(searchText.lowercased()) ||
            vehicle.make.lowercased().contains(searchText.lowercased()) ||
            vehicle.vinNumber.lowercased().contains(searchText.lowercased()) ||
            vehicle.loadCapacity.description.lowercased().contains(searchText.lowercased()) ||
            vehicle.licenseNumber.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding(.vertical, 8)
                
                if availableVehicles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text(searchText.isEmpty ? "No available vehicles" : "No matching vehicles")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(availableVehicles) { vehicle in
                                Button(action: {
                                    if temporarySelectedVehicle?.id == vehicle.id {
                                        // Deselect if already selected
                                        temporarySelectedVehicle = nil
                                    } else {
                                        // Select new vehicle
                                        temporarySelectedVehicle = vehicle
                                    }
                                }) {
                                    VehicleCardContent(
                                        vehicle: vehicle,
                                        isSelected: temporarySelectedVehicle?.id == vehicle.id,
                                        vehicleAddress: vehicleAddresses[vehicle.id] ?? "Fetching address..."
                                    )
                                }
                                .onAppear {
                                    fetchVehicleAddress(for: vehicle)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color.white)
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primaryGradientEnd)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedVehicle = temporarySelectedVehicle
                        dismiss()
                    }
                    .disabled(temporarySelectedVehicle == nil)
                    .foregroundColor(temporarySelectedVehicle == nil ? Color.gray : Color.primaryGradientStart) // Custom color
                }
            }
            .toolbarBackground(Color(.white), for: .navigationBar)
            .background(Color.white)
        }.onAppear{
            temporarySelectedVehicle = selectedVehicle
        }
    }
    
    /// Fetches address from vehicle's coordinate
    private func fetchVehicleAddress(for vehicle: Vehicle) {
        guard vehicleAddresses[vehicle.id] == nil else { return } // Avoid duplicate requests
        
        getAddress(from: vehicle.currentCoordinate) { address in
            DispatchQueue.main.async {
                vehicleAddresses[vehicle.id] = address ?? "Unknown location"
            }
        }
    }
}



#Preview{
    TripsView()
}
