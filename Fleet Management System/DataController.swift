//
//  DataController.swift
//  Fleet Management System
//
//  Created by Aakash Singh on 23/03/25.
//
import SwiftUI
import CoreLocation
import SwiftSMTP
import Auth


class IFEDataController: ObservableObject {
    static let shared = IFEDataController() // Singleton instance
    var user: AppUser?
    
    @Published var drivers: [Driver] = []
    @Published var vehicles: [Vehicle] = []
    @Published var trips: [Trip] = []
    @Published var tripsForDriver: [Trip] = []
    @Published var vehicleCompanies: [String] = []
    let remoteController = RemoteController.shared
    
    init() {
        Task { @MainActor in
            await fetchUser()
            if let user = user {
                if user.role == .driver {
                    await loadTripsForDriver()
                } else {
                    await loadDrivers()
                    await loadVehicles()
                    await loadTrips()
                    await loadVehicleCompanies()
                }
            }
        }
    }
    
    @MainActor
    private func fetchUser() async {
        do {
            user = try await AuthManager.shared.getCurrentSession()
        } catch {
            print("Error while fetching user: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadDrivers() async {
        do {
            drivers = try await remoteController.getRegisteredDrivers()
        } catch {
            print("Error while fetching registered drivers: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadVehicles() async {
        do {
            vehicles = try await remoteController.getRegisteredVehicles()
        } catch {
            print("Error while fetching registered vehicles: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadTrips() async {
        do {
            if let user = user {
                if user.role == .fleetManager {
                    print(user.id.uuidString)
                    trips = try await remoteController.getManagerAssignedTrips(by: user.id)
                }
            }
        } catch {
            print("Error while fetching trips: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadVehicleCompanies() async {
        do {
            vehicleCompanies = try await remoteController.getRegisteredVehicleCompanies()
        } catch {
            print("Error while fetching registered vehicle companies: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func loadTripsForDriver() async {
        do {
            if let user = user {
                if user.role == .driver{
                    print(user.id.uuidString)
                    tripsForDriver = try await remoteController.getDriverTrips(by: user.id)
                }
            }
        }catch {
            print("Error while fetching trips for driver : \(error.localizedDescription)")
        }
    }
    

    func addDriver(_ driver: Driver, password: String) async {
        do {
            // Save the current fleet manager ID before any operations
            if let currentUser = user, currentUser.role == .fleetManager {
                AuthManager.shared.saveActiveFleetManager(id: currentUser.id)
            }
            
            // Create the new driver
            let new_driver_uid = try await remoteController.createNewDriver(driver.meta_data.email, password: password)
            let employeeID = try await remoteController.getMaxEmployeeID(ofType: .driver)
            
            // Add the driver metadata
            let newDriver = try await remoteController.addNewDriverMetaData(by: new_driver_uid, phoneNumber: driver.meta_data.phone, fullName: driver.meta_data.fullName, employeeID: employeeID+1, licenseNumber: driver.licenseNumber)
            
            // Make sure the current user is still set correctly after driver creation
            if user == nil || user?.role != .fleetManager {
                // Attempt to restore the fleet manager session
                if let fleetManagerId = AuthManager.shared.getActiveFleetManagerID() {
                    let role = try await remoteController.getUserRole(by: fleetManagerId.uuidString)
                    if role == .fleetManager {
                        user = try await AuthManager.shared.getAppUser(byType: role, id: fleetManagerId)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.drivers.append(newDriver)
            }
        } catch {
            print("Error adding driver: \(error.localizedDescription)")
        }
    }
    
    func removeDriver(_ driver: Driver) {
        Task {
            do {
                var inactiveDriver = driver
                inactiveDriver.meta_data.activeStatus = false
                try await remoteController.updateUserActiveStatus(by: driver.id, with: false)
                DispatchQueue.main.async {
                    self.drivers.removeAll { $0 == driver }
                    self.drivers.append(inactiveDriver)
                }
            } catch {
                print("Error while removing the driver: \(error.localizedDescription)")
            }
        }
    }
    
    func enableDriver(_ driver: Driver) {
        Task {
            do {
                var activeDriver = driver
                activeDriver.meta_data.activeStatus = true
                try await remoteController.updateUserActiveStatus(by: driver.id, with: true)
                drivers.removeAll { $0 == driver }
                drivers.append(activeDriver)
            } catch {
                print("Error while enabling the driver: \(error.localizedDescription)")
            }
        }
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        Task {
            do {
                var newVehicle = vehicle
                newVehicle.id = try await remoteController.addNewVehicle(vehicle)
                DispatchQueue.main.async {
                    self.vehicles.append(newVehicle)
                }
            } catch {
                print("Error while adding new vehicle: \(error.localizedDescription)")
            }
        }
    }
    
    func removeVehicle(_ vehicle: Vehicle) {
        Task{
            do {
                var inactiveVehicle = vehicle
                inactiveVehicle.activeStatus = false
//                inactiveVehicle.status = .inactive
                try await remoteController.updateVehicleActiveStatus(by: vehicle.id, with: false)
                vehicles.removeAll { $0.id == vehicle.id }
                vehicles.append(inactiveVehicle)
            } catch {
                print("Error while removing the vehicle: \(error.localizedDescription)")
            }
        }
    }
    
    func enableVehicle(_ vehicle: Vehicle) {
        Task{
            do {
                var inactiveVehicle = vehicle
                inactiveVehicle.activeStatus = true
                inactiveVehicle.status = .available
                try await remoteController.updateVehicleActiveStatus(by: vehicle.id, with: true)
                vehicles.removeAll { $0.id == vehicle.id }
                vehicles.append(inactiveVehicle)
            } catch {
                print("Error while activating the vehicle: \(error.localizedDescription)")
            }
        }
    }
    
    func addTrip(_ trip: Trip) {
        Task {
            do {
                print("Pickup location: \(trip.pickupLocation)\nDestination: \(trip.destination)")
                let pickupComponents = trip.pickupLocation
                    .split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                
                let destinationComponent = trip.destination
                    .split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                
                print(pickupComponents, destinationComponent)
                
                if let pickupLatitude = Double(pickupComponents[0]), let pickupLongitude = Double(pickupComponents[1]), let destLatitude = Double(destinationComponent[0]), let destLongitude = Double(destinationComponent[1]) {
                    let pickupCoordinates = (pickupLatitude, pickupLongitude)
                    let destCoordinates = (destLatitude, destLongitude)
                    
                    let calendar = Calendar.current

                    let hours: Int = calendar.component(.hour, from: trip.totalTripDuration)
                    let minutes: Int = calendar.component(.minute, from: trip.totalTripDuration)

                    let time = (hours: hours, minutes: minutes)
                    
                    let newTrip = try await remoteController.assignNewTrip(assignedBy: user!.id, pickupCoordinates: pickupCoordinates, destinationCoordinates: destCoordinates, assignedVehicleId: trip.assignedVehicleID, assignedDriverIDs: trip.assignedDriverIDs, estimatedDateTime: trip.estimatedArrivalDateTime, description: trip.description!, totalDistance: trip.totalDistance, totalTripDuration: time, scheduledDateTime: trip.scheduledDateTime)
                    
                    for driverId in newTrip.assignedDriverIDs {
                        if let index = drivers.firstIndex(where: { $0.id == driverId }) {
                            var driver = drivers[index]
                            driver.status = .onTrip
                            drivers[index] = driver
                        }
                    }
                    // Update vehicle status to assigned
                    if let index = vehicles.firstIndex(where: { $0.id == trip.assignedVehicleID }) {
                        var vehicle = vehicles[index]
                        vehicle.status = .assigned
                        vehicles[index] = vehicle
                    }
                    
                    trips.append(newTrip)
                } else {
                    print("Unable to parse the coordinates")
                }
            } catch {
                print("Error assigning the new trip: \(error.localizedDescription)")
            }
        }
//
//        try await remoteController.a
    }
    
    func getFilteredTrips(status: TripStatus?) -> [Trip] {
        if let status = status {
            return trips.filter { $0.status == status }
        }
        return trips
    }
    
    func sendWelcomeEmail(to email: String, password: String) {
        let smtp = SMTP(
            hostname: "smtp.gmail.com",  // Google's SMTP server
            email: "infleetexpress@gmail.com",
            password: "tpko cqtp oajo dflz" // Use App Password, not your actual password
        )
        
        let sender = Mail.User(name: "InFleet Express", email: "infleetexpress@gmail.com")
        let recipient = Mail.User(email: email)
        
        let email = Mail(
                from: sender,
                to: [recipient],
                subject: "Welcome to InFleet Express",
                text: """
                Hello,

                Here are your login details:

                Email: \(email)
                Password: \(password)

                Please keep this information secure.

                Regards,
                InFleet Express Team
                """
            )
        
        smtp.send(email) { error in
            if let error = error {
                print("Failed to send email: \(error.localizedDescription)")
            } else {
                print("Email sent successfully")
            }
        }
    }
    
    func updateDriverPhone(_ driver: Driver,with phone: String) {
        Task {
            do {
                var updatedDriver = driver
                updatedDriver.meta_data.phone = phone
                try await remoteController.updateUserPhone(by: driver.id, phone)
                drivers.removeAll { $0 == driver }
                drivers.append(updatedDriver)
            } catch {
                print("Error while updating the driver phone: \(error.localizedDescription)")
            }
        }
    }
    
    func updateVehicleExpiryDates(_ vehicle: Vehicle, with newVehicle: Vehicle) {
        Task {
            do {
                try await remoteController.updateVehicleExpiry(by: vehicle.id, with: (
                    puc: newVehicle.pucExpiryDate,
                    insurance: newVehicle.insuranceExpiryDate,
                    registration: newVehicle.rcExpiryDate
                ))
                vehicles.removeAll { $0 == vehicle }
                vehicles.append(newVehicle)
            } catch {
                print("Error while updating the vehicle: \(error.localizedDescription)")
            }
        }
    }
    
    func updateTripStatus(_ trip: Trip, to newStatus: TripStatus) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            Task {
                do {
                    try await remoteController.updateTripStatus(by: trip.id, to: newStatus)
                    trips[index].status = newStatus
                } catch {
                    print("Error while updating the trip status: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateDriverStatus(_ driver: Driver, with newStatus: DriverStatus) {
        if let index = drivers.firstIndex(where: { $0 == driver }) {
            Task {
                do {
                    try await remoteController.updateDriverStatus(by: driver.id, newStatus)
                    drivers[index].status = newStatus
                } catch {
                    print("Error while updating the driver status: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func updateVehicleStatus(_ vehicle: Vehicle, with newStatus: VehicleStatus) {
        if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            Task {
                do {
                    try await remoteController.updateVehicleStatus(by: vehicle.id, with: newStatus)
                    vehicles[index].status = newStatus
                } catch {
                    print("Error while updating the driver status: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getRegisteredDriver(by id: UUID) async -> Driver? {
        do {
            return try await remoteController.getRegisteredDriver(by: id)
        } catch {
            print("Error while fetching the driver by id: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getRegisteredVehicle(by id: Int) async -> Vehicle? {
        do {
            return try await remoteController.getRegisteredVehicle(by: id)
        } catch {
            print("Error while fetching the vehicle by id: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetches offline drivers from the remote controller.
    ///
    /// This function asynchronously retrieves the list of offline drivers
    /// and returns them using a completion handler.
    ///
    /// - Parameter completion: A closure that receives an optional array of `Driver`.
    ///
    /// ## Example Usage:
    /// ```swift
    /// getOfflineDrivers { drivers in
    ///     if let drivers = drivers {
    ///         print("Fetched offline drivers: \(drivers)")
    ///     } else {
    ///         print("Failed to fetch offline drivers.")
    ///     }
    /// }
    /// ```
    ///
    /// - Note: This function runs asynchronously using a `Task`, so the callback
    ///   executes after the network request completes.
    func getOfflineDrivers(completion: @escaping ([Driver]?) -> Void) {
        Task {
            do {
                let drivers = try await remoteController.getOfflineDrivers()
                completion(drivers)
            } catch {
                print("Error while fetching offline drivers: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    /// Fetches the trip inspection for a given trip ID.
    ///
    /// This function asynchronously retrieves the `TripInspection` record
    /// associated with a specific trip. If an error occurs, it returns `nil`.
    ///
    /// - Parameter id: The unique identifier (`UUID`) of the trip.
    /// - Returns: An optional `TripInspection` object. Returns `nil` if an error occurs.
    ///
    /// ## Example Usage:
    /// ```swift
    /// let tripId = UUID()
    /// Task {
    ///     if let inspection = await getTripInspectionForTrip(by: tripId) {
    ///         print("Fetched trip inspection: \(inspection)")
    ///     } else {
    ///         print("Failed to fetch trip inspection.")
    ///     }
    /// }
    /// ```
    ///
    /// - Note: This function uses `async/await` and should be called within an async context.
    ///   Any errors encountered are logged but not thrown.
    func getTripInspectionForTrip(by id: UUID) async -> TripInspection? {
        do {
            return try await remoteController.getTripInspectionForTrip(by: id)
        } catch {
            print("Error while fetching trip inspection: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Adds a pre-trip inspection for a specific trip.
    ///
    /// This function asynchronously sends a pre-trip inspection report for a given trip ID.
    /// It includes a dictionary of `TripInspectionItem` values mapped to `Bool`
    /// to indicate whether each inspection item passed or failed.
    ///
    /// - Parameters:
    ///   - id: The unique identifier (`UUID`) of the trip.
    ///   - inspection: A dictionary where keys are `TripInspectionItem` (an enum) and
    ///     values are `Bool`, indicating the status of each inspection item.
    ///   - note: A `String` containing any additional notes related to the inspection.
    ///
    /// ## Example Usage:
    /// ```swift
    /// let tripId = UUID()
    /// let inspectionData: [TripInspectionItem: Bool] = [
    ///     .tireCondition: true,
    ///     .mirros: false
    /// ]
    /// let note = "Tire pressure needs to be checked."
    ///
    /// addPreTripInspectionForTrip(by: tripId, inspection: inspectionData, note: note)
    /// ```
    ///
    /// - Note: This function runs asynchronously inside a `Task`, so it should be called
    ///   within an async-safe context. Errors are logged but not thrown.
    func addPreTripInspectionForTrip(by id: UUID,
                                     inspection: [TripInspectionItem: Bool],
                                     note: String) {
        Task {
            do {
                try await remoteController.addPreTripInspectionForTrip(by: id, inspection: inspection, note: note)
            } catch {
                print("Error while adding pre-trip inspection: \(error.localizedDescription)")
            }
        }
    }
    
    /// Adds a post-trip inspection for a specific trip.
    ///
    /// This function asynchronously sends a post-trip inspection report for a given trip ID.
    /// It includes a dictionary of `TripInspectionItem` values mapped to `Bool`
    /// to indicate whether each inspection item passed or failed.
    ///
    /// - Parameters:
    ///   - id: The unique identifier (`UUID`) of the trip.
    ///   - inspection: A dictionary where keys are `TripInspectionItem` (an enum) and
    ///     values are `Bool`, indicating the status of each inspection item.
    ///   - note: A `String` containing any additional notes related to the inspection.
    ///
    /// ## Example Usage:
    /// ```swift
    /// let tripId = UUID()
    /// let inspectionData: [TripInspectionItem: Bool] = [
    ///     .tireCondition: true,
    ///     .mirros: false
    /// ]
    /// let note = "Tire pressure needs to be checked."
    ///
    /// addPostTripInspectionForTrip(by: tripId, inspection: inspectionData, note: note)
    /// ```
    ///
    /// - Note: This function runs asynchronously inside a `Task`, so it should be called
    ///   within an async-safe context. Errors are logged but not thrown.
    func addPostTripInspectionForTrip(by id: UUID,
                                      inspection: [TripInspectionItem: Bool],
                                      note: String) {
        Task {
            do {
                try await remoteController.addPostTripInspectionForTrip(by: id, inspection: inspection, note: note)
            } catch {
                print("Error while adding post-trip inspection: \(error.localizedDescription)")
            }
        }
    }
}

func getAddress(from coordinate: String, completion: @escaping (String?) -> Void) {
    let components = coordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    
    guard components.count == 2,
          let latitude = Double(components[0]),
          let longitude = Double(components[1]) else {
        print("Invalid coordinate format")
        completion(nil)
        return
    }

    let location = CLLocation(latitude: latitude, longitude: longitude)
    let geocoder = CLGeocoder()
    
    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
        if let error = error {
            print("Reverse geocoding failed: \(error.localizedDescription)")
            completion(nil)
            return
        }

        if let placemark = placemarks?.first {
            let address = [
                placemark.name,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")

            completion(address)
        } else {
            completion(nil)
        }
    }
}

func getCoordinates(from address: String) async -> String? {
    let geocoder = CLGeocoder()
    do {
        let placemarks = try await geocoder.geocodeAddressString(address)
        if let location = placemarks.first?.location {
            return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        }
    } catch {
        print("Geocoding failed: \(error.localizedDescription)")
    }
    return nil
}
