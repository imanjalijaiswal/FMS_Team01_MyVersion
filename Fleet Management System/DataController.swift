//
//  DataController.swift
//  Fleet Management System
//
//  Created by Devansh Seth on 23/03/25.
//
import SwiftUI
import SwiftSMTP
import Auth


class IFEDataController: ObservableObject {
    static let shared = IFEDataController() // Singleton instance
    
    var user: AppUser?
    
    /// List of all registered drivers (updated from backend)
    @Published var drivers: [Driver] = []
    
    /// List of all registered vehicles (updated from backend)
    @Published var vehicles: [Vehicle] = []
    
    /// Trips assigned to the currently logged-in fleet manager
    @Published var trips: [Trip] = []
    
    /// Trips assigned to the currently logged-in driver
    @Published var tripsForDriver: [Trip] = []
    
    /// List of all registered maintenance personnels
    @Published var maintenancePersonnels: [MaintenancePersonnel] = []
    
    /// Tasks assigned by the fleet manager to maintenance personnels
    @Published var managerAssignedMaintenanceTasks: [MaintenanceTask] = []
    
    /// Tasks assigned to the currently logged-in maintenance personnel
    @Published var personnelTasks: [MaintenanceTask] = []
    
    /// List of registered vehicle company names
    @Published var vehicleCompanies: [String] = []
    
    /// List of registered service centers
    @Published var serviceCenters: [ServiceCenter] = []
    
    /// Map of service center ID to its resolved human-readable address
    @Published var serviceCenterLocations: [Int: String] = [:]
    
    /// Singleton instance of RemoteController used to handle all remote (network/API)
    let remoteController = RemoteController.shared
    
    /// Optional notifier used for handling remote push notifications
    var notifier: IFERemoteNotificationController?
    
    init() {
        Task { @MainActor in
            await fetchUser()
            
            if notifier != nil {
                await notifier?.subscribe()
            } else {
                print("Cannot subscribe to notification as notifer is not initialized.")
            }
            
            if let user = user {
                await loadDataForUser(user)
            }
        }
    }
    
    @MainActor
    func reloadData() async {
        await fetchUser()
        if let user = user {
            await loadDataForUser(user)
        }
    }
    
    @MainActor
    private func loadDataForUser(_ user: AppUser) async {
        if user.role == .driver {
            await loadTripsForDriver()
            await loadServiceCenters()
        } else if user.role == .maintenancePersonnel {
            await loadPersonnelTasks()
        } else {
            await loadDrivers()
            await loadVehicles()
            await loadMaintenancePersonnels()
            await loadTrips()
            await loadManagerAssignedMaintenanceTasks()
            await loadVehicleCompanies()
            await loadServiceCenters()
            await loadServiceCenterLocations()
        }
    }
    
    @MainActor
    private func fetchUser() async {
        do {
            user = try await AuthManager.shared.getCurrentSession()
            notifier = .init(RemoteController.shared.client, table: "Notifications", userID: user?.id)
            notifier?.notificationCenter.delegate = notifier
            notifier?.requestNotificationPermission()
            notifier?.registerPersistentNotificationCategory()
        } catch {
            print("Error while fetching user: \(error.localizedDescription)")
        }
    }
    
    /// Loads all registered drivers from the backend.
    ///
    /// - Note: Updates the `drivers` array on the main thread.
    /// - Warning: Logs an error message if the fetch fails.
    @MainActor
     func loadDrivers() async {
        do {
            drivers = try await remoteController.getRegisteredDrivers()
        } catch {
            print("Error while fetching registered drivers: \(error.localizedDescription)")
        }
    }
    
    /// Loads all registered vehicles from the backend.
    ///
    /// - Note: Updates the `vehicles` array on the main thread.
    /// - Warning: Logs an error message if the fetch fails.
    @MainActor
    func loadVehicles() async {
        do {
            vehicles = try await remoteController.getRegisteredVehicles()
        } catch {
            print("Error while fetching registered vehicles: \(error.localizedDescription)")
        }
    }
    
    /// Loads all registered maintenance personnels.
    ///
    /// - Note: Updates the `maintenancePersonnels` array.
    /// - Warning: Logs an error message if the fetch fails.
    @MainActor
     func loadMaintenancePersonnels() async {
        do {
            maintenancePersonnels = try await remoteController.getRegisteredMaintenancePersonnels()
        } catch {
            print("Error while fetching registered maintenance personnels: \(error.localizedDescription)")
        }
    }
    
    /// Loads trips assigned to the current fleet manager.
    ///
    /// - Requires: The current `user` must be a fleet manager.
    /// - Note: Updates the `trips` array.
    /// - Warning: Logs an error if user role is invalid or request fails.
    @MainActor
     func loadTrips() async {
        do {
            if let user = user {
                if user.role == .fleetManager {
                    trips = try await remoteController.getManagerAssignedTrips(by: user.id)
                }
            }
        } catch {
            print("Error while fetching trips: \(error.localizedDescription)")
        }
    }
    
    /// Loads all registered vehicle companies.
    ///
    /// - Note: Updates the `vehicleCompanies` array.
    /// - Warning: Logs an error message if the fetch fails.
    @MainActor
     func loadVehicleCompanies() async {
        do {
            vehicleCompanies = try await remoteController.getRegisteredVehicleCompanies()
        } catch {
            print("Error while fetching registered vehicle companies: \(error.localizedDescription)")
        }
    }
    
    /// Loads trips assigned to the currently logged-in driver.
    ///
    /// - Requires: The current `user` must be a driver.
    /// - Note: Updates the `tripsForDriver` array.
    /// - Warning: Logs an error if user role is invalid or request fails.
    @MainActor
    func loadTripsForDriver() async {
        do {
            if let user = user {
                if user.role == .driver{
                    tripsForDriver = try await remoteController.getDriverTrips(by: user.id)
                }
            }
        }catch {
            print("Error while fetching trips for driver : \(error.localizedDescription)")
        }
    }
    
    /// Loads all registered service centers for the current user role.
    ///
    /// - Requires: The user must be a fleet manager or driver.
    /// - Note: Updates the `serviceCenters` array.
    /// - Warning: Logs an error message if the fetch fails.
    @MainActor
    func loadServiceCenters() async {
        do {
            if let user = user {
                if user.role == .driver || user.role == .fleetManager {
                    serviceCenters = try await remoteController.getRegisteredServiceCenters()
                }
            }
        }catch {
            print("Error while fetching the registered service centers : \(error.localizedDescription)")
        }
    }
    
    /// Converts coordinates of all service centers to human-readable addresses.
    ///
    /// - Requires: The user must be a fleet manager or driver.
    /// - Note: Populates the `serviceCenterLocations` dictionary with resolved addresses.
    /// - Warning: Logs individual errors for failed reverse geocoding.
    @MainActor
    func loadServiceCenterLocations() async {
        do {
            if let user = user, user.role == .driver || user.role == .fleetManager {
                for (index, serviceCenter) in serviceCenters.enumerated() {
                    getAddress(from: serviceCenter.coordinate) { [weak self] address in
                        DispatchQueue.main.async {
                            if let address = address {
                                self?.serviceCenterLocations[serviceCenter.id] = address
                            } else {
                                print("Failed to get address for: \(serviceCenter.coordinate)")
                            }
                        }
                    }
                }
            }
        }
    }


    /// Loads maintenance tasks assigned to the currently logged-in maintenance personnel.
    ///
    /// - Requires: The user must be a maintenance personnel.
    /// - Note: Updates the `personnelTasks` array.
    /// - Warning: Logs an error if user role is invalid or request fails.
    @MainActor
    func loadPersonnelTasks() async {
        do {
            if let user = user {
                if user.role == .maintenancePersonnel{
                    personnelTasks = try await remoteController.getMaintenancePersonnelTasks(by: user.id)
                }
            }
        }catch {
            print("Error while fetching tasks assigned to maintenance personnel: \(error.localizedDescription)")
        }
    }
    
    /// Loads all maintenance tasks assigned by the fleet manager.
    ///
    /// - Requires: The user must be a fleet manager.
    /// - Note: Updates the `managerAssignedMaintenanceTasks` array.
    /// - Warning: Logs an error if user role is invalid or request fails.
    @MainActor
    func loadManagerAssignedMaintenanceTasks() async {
        do {
            if let user = user {
                if user.role == .fleetManager{
                    managerAssignedMaintenanceTasks = try await remoteController.getManagerAssignedMaintenanceTasks(by: user.id)
                }
            }
        }catch {
            print("Error while fetching tasks assigned by fleet manager to maintenance personnel : \(error.localizedDescription)")
        }
    }
    

    /// Adds a new driver to the system asynchronously.
    ///
    /// This function performs the full driver registration flow:
    /// 1. Saves the current fleet manager's ID.
    /// 2. Creates a new driver account using the provided email and password.
    /// 3. Fetches the maximum current employee ID and assigns the next available one.
    /// 4. Saves the driver's metadata (phone, full name, employee ID, license number).
    /// 5. Restores the fleet manager session if the user object gets reset during the process.
    ///
    /// - Parameters:
    ///   - driver: The `Driver` object containing metadata and license information.
    ///   - password: The password to be associated with the new driver’s account.
    ///
    /// # Example
    /// ```swift
    /// await addDriver(driver, password: "SecurePass123")
    /// ```
    ///
    /// - Note: This method ensures the fleet manager session is preserved after registering a driver.
    ///         Make sure the `user` is set before calling this function.
    /// - Warning: Network errors or backend issues may prevent driver creation; always handle errors gracefully.
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
    
    /// Fetches a `FleetManager` from the remote server using the provided UUID.
    ///
    /// This asynchronous function attempts to retrieve a fleet manager's details by their unique ID.
    /// If the operation fails, it logs the error and returns `nil`.
    ///
    /// - Parameter id: The unique identifier (`UUID`) of the fleet manager to fetch.
    /// - Returns: A `FleetManager` instance if found, otherwise `nil`.
    ///
    /// # Example
    /// ```swift
    /// let manager = try await getFleetManager(by: managerId)
    /// ```
    ///
    /// - Note: Even though the function is marked as `throws`, it handles the error internally
    ///         and still returns `nil` on failure instead of propagating the error further.
    /// - Warning: Ensure the `id` is valid and corresponds to a registered fleet manager in the system.
    func getFleetManager(by id: UUID) async throws -> FleetManager? {
        do {
            return try await remoteController.getFleetManager(by: id)
        } catch {
            print("Error while fetching fleet manager: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Disables a driver by updating their active status to `false` on the remote server.
    ///
    /// This function sets the driver's `activeStatus` to `false` both remotely and locally.
    /// After the update, the local `drivers` list is refreshed to reflect the change.
    ///
    /// - Parameter driver: The `Driver` object to be disabled.
    ///
    /// # Example
    /// ```swift
    /// removeDriver(driver)
    /// ```
    ///
    /// - Note: The driver is first removed from the local list and then re-appended with the updated status.
    /// - Important: This function performs UI-related updates on the main thread to ensure thread safety.
    /// - Warning: If the remote update fails, the local list remains unchanged and the error is logged.
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
    
    /// Enables a driver by updating their active status to `true` on the remote server.
    ///
    /// This function sets the driver's `activeStatus` to `true` both remotely and locally.
    /// After the update, the local `drivers` list is updated to reflect the change.
    ///
    /// - Parameter driver: The `Driver` object to be enabled.
    ///
    /// # Example
    /// ```swift
    /// enableDriver(driver)
    /// ```
    ///
    /// - Note: The driver is removed and re-appended to the `drivers` array to reflect the updated status.
    /// - Important: Make sure the provided `Driver` object matches exactly with the one stored locally for the `.removeAll` check to succeed.
    /// - Warning: If the remote update fails, the driver remains disabled and the error is printed to the console.
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
    
    /// Adds a new vehicle to the fleet by sending data to the remote server.
    ///
    /// This function sends the given `vehicle` to the backend to be registered,
    /// receives the generated `id`, and constructs a new `Vehicle` instance with it.
    /// The new vehicle is then appended to the local `vehicles` list on the main thread.
    ///
    /// - Parameter vehicle: A `Vehicle` instance containing the details to be added (without `id`).
    ///
    /// # Example
    /// ```swift
    /// let vehicle = Vehicle(..., id: UUID(), ...)
    /// addVehicle(vehicle)
    /// ```
    ///
    /// - Note: The `model` field is automatically converted to uppercase before being stored.
    /// - Important: This function must be called on a background thread. It handles UI updates on the main thread internally.
    /// - Warning: If the API call fails, the vehicle won't be added and the error is printed to the console.
    func addVehicle(_ vehicle: Vehicle) {
        Task {
            do {
                let newVehicle = Vehicle(
                    id: try await remoteController.addNewVehicle(vehicle),
                    make: vehicle.make,
                    model: vehicle.model.uppercased(),
                    vinNumber: vehicle.vinNumber,
                    licenseNumber: vehicle.licenseNumber,
                    fuelType: vehicle.fuelType,
                    loadCapacity: vehicle.loadCapacity,
                    insurancePolicyNumber: vehicle.insurancePolicyNumber,
                    insuranceExpiryDate: vehicle.insuranceExpiryDate,
                    pucCertificateNumber: vehicle.pucCertificateNumber,
                    pucExpiryDate: vehicle.pucExpiryDate,
                    rcNumber: vehicle.rcNumber,
                    rcExpiryDate: vehicle.rcExpiryDate,
                    currentCoordinate: vehicle.currentCoordinate,
                    status: vehicle.status,
                    activeStatus: vehicle.activeStatus
                )
                
                DispatchQueue.main.async {
                    self.vehicles.append(newVehicle)
                }
            } catch {
                print("Error while adding new vehicle: \(error.localizedDescription)")
            }
        }
    }
    
    /// Disables a vehicle by setting its active status to false.
    ///
    /// This function marks the provided `vehicle` as inactive by setting `activeStatus` to `false`.
    /// It then sends this update to the remote server via `remoteController`, and updates the local
    /// `vehicles` list by removing the old vehicle entry and appending the updated one.
    ///
    /// - Parameter vehicle: The `Vehicle` instance to be removed (deactivated).
    ///
    /// # Example
    /// ```swift
    /// let vehicle = Vehicle(id: UUID(), activeStatus: true, ...)
    /// removeVehicle(vehicle)
    /// ```
    ///
    /// - Note: The local `vehicles` array is updated after the remote update succeeds.
    /// - Warning: Ensure the vehicle's `id` exists in the local list before calling this to avoid redundancy.
    /// - Throws: Logs an error if the remote update fails.
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
    
    /// Enables a vehicle by updating its active status and availability.
    ///
    /// This function sets the given vehicle's `activeStatus` to `true` and updates its status to `.available`.
    /// It then sends the update to the remote server using `remoteController` and replaces the old vehicle
    /// entry in the local `vehicles` array with the updated one.
    ///
    /// - Parameter vehicle: The `Vehicle` object to be enabled.
    ///
    /// # Example
    /// ```swift
    /// let vehicle = Vehicle(id: UUID(), activeStatus: false, status: .inactive, ...)
    /// enableVehicle(vehicle)
    /// ```
    ///
    /// - Note: This operation also updates the vehicle's status locally after the remote update.
    /// - Warning: Make sure the vehicle exists in the local `vehicles` array, or the replacement will have no effect.
    /// - Throws: Logs any error that occurs during the remote update.
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
    
    /// Assigns a new trip using the provided `Trip` object and updates the local driver and vehicle status.
    ///
    /// This function parses the pickup and destination coordinates from string format,
    /// converts them to latitude and longitude, and sends a request to assign a new trip
    /// via the remote controller. It also updates the driver's status to `.onTrip` and the vehicle's status to `.assigned`
    /// locally if the assignment is successful.
    ///
    /// - Parameter trip: A `Trip` object containing all required data to assign a new trip.
    ///
    /// # Example
    /// ```swift
    /// let trip = Trip(
    ///     id: UUID(),
    ///     pickupLocation: "28.6139,77.2090",
    ///     destination: "28.7041,77.1025",
    ///     assignedVehicleID: vehicleID,
    ///     assignedDriverIDs: [driverID],
    ///     estimatedArrivalDateTime: Date(),
    ///     scheduledDateTime: Date().addingTimeInterval(3600),
    ///     totalDistance: 15.2,
    ///     totalTripDuration: DateComponents(hour: 1, minute: 30),
    ///     description: "Airport drop"
    /// )
    /// addTrip(trip)
    /// ```
    ///
    /// - Note: Make sure the pickup and destination coordinates are in valid `"lat,lng"` string format.
    /// - Note: Coordinates, vehicle status, and driver status are updated only if parsing and remote assignment are successful.
    /// - Warning: The function assumes `user` is non-nil and force unwraps its `id`.
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
    }
    
    /// Returns trips filtered by a given status.
    ///
    /// - Parameter status: The `TripStatus` to filter by. If `nil`, all trips are returned.
    ///
    /// # Example
    /// ```swift
    /// let assignedTrips = getFilteredTrips(status: .assigned)
    /// let allTrips = getFilteredTrips(status: nil)
    /// ```
    ///
    /// - Note: If no status is provided (`nil`), this function returns all available trips.
    func getFilteredTrips(status: TripStatus?) -> [Trip] {
        if let status = status {
            return trips.filter { $0.status == status }
        }
        return trips
    }
    
    /// Sends a welcome email containing login credentials to a new user.
    ///
    /// This function uses Gmail's SMTP server to send an email with the user's login details.
    /// Make sure to use an [App Password](https://support.google.com/accounts/answer/185833) for authentication,
    /// not the actual Gmail account password.
    ///
    /// - Parameters:
    ///   - email: The recipient's email address.
    ///   - password: The password assigned to the user.
    ///
    /// # Example
    /// ```swift
    /// sendWelcomeEmail(to: "newuser@example.com", password: "TempPass@123")
    /// ```
    ///
    /// - Note: Avoid logging sensitive data like passwords in production. Consider using secure channels instead.
    func sendWelcomeEmail(to email: String, password: String) {
        let smtp = SMTP(
            hostname: "smtp.gmail.com",  // Google's SMTP server
            email: "infleetexpress@gmail.com",
            password: "tpko cqtp oajo dflz" // Google App Password, not account's actual password
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
    
    /// Updates the phone number of a given driver.
    ///
    /// This function modifies the driver's phone number locally and sends the update to the remote controller.
    /// After a successful update, it removes the old driver object from the local list and appends the updated one.
    ///
    /// - Parameters:
    ///   - driver: The `Driver` object whose phone number needs to be updated.
    ///   - phone: The new phone number to assign.
    ///
    /// # Example
    /// ```swift
    /// updateDriverPhone(driverInstance, with: "9876543210")
    /// ```
    ///
    /// - Note: The driver is first removed and then re-added to the local list with updated phone metadata.
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
    
    /// Updates the expiry dates (PUC, insurance, registration) of a given vehicle.
    ///
    /// This function sends an update request to the remote controller with the new expiry dates.
    /// Upon successful update, the local vehicle list is updated by removing the old vehicle instance
    /// and appending the new one with updated dates.
    ///
    /// - Parameters:
    ///   - vehicle: The current `Vehicle` object to be updated.
    ///   - newVehicle: The `Vehicle` object containing the new expiry dates.
    ///
    /// # Example
    /// ```swift
    /// updateVehicleExpiryDates(currentVehicle, with: updatedVehicle)
    /// ```
    ///
    /// - Note: This operation replaces the old vehicle object in the local `vehicles` list.
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
    
    /// Updates the status of a specific trip both remotely and locally.
    ///
    /// This method checks the user's role (fleet manager or driver) and selects the appropriate
    /// local trip list. If the trip exists in the list, it attempts to update the status remotely
    /// via the `remoteController`. Upon success, the corresponding local trip's status is also updated.
    ///
    /// - Parameters:
    ///   - trip: The `Trip` object whose status is to be updated.
    ///   - newStatus: The new `TripStatus` to assign.
    ///
    /// # Example
    /// ```swift
    /// updateTripStatus(myTrip, to: .completed)
    /// ```
    ///
    /// - Note: If the user role is not fleet manager or driver, no action is taken.
    func updateTripStatus(_ trip: Trip, to newStatus: TripStatus) {
        if let user {
            let tripsToSearch: [Trip]
            
            if user.role == .fleetManager {
                tripsToSearch = trips
            } else if user.role == .driver {
                tripsToSearch = tripsForDriver
            } else {
                tripsToSearch = []
            }
            
            if let index = tripsToSearch.firstIndex(where: { $0.id == trip.id }) {
                Task {
                    do {
                        try await remoteController.updateTripStatus(by: trip.id, to: newStatus)
                        
                        if user.role == .fleetManager {
                            trips[index].status = newStatus
                        } else if user.role == .driver {
                            tripsForDriver[index].status = newStatus
                        }
                    } catch {
                        print("Error while updating the trip status: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Updates the status of a given driver both remotely and locally.
    ///
    /// This method sends an update request to the remote controller to change the driver's status.
    /// Upon success, the local `drivers` array is also updated to reflect the new status.
    /// If the remote update fails, the error is printed to the console.
    ///
    /// - Parameters:
    ///   - driver: The `Driver` object whose status is to be updated.
    ///   - newStatus: The new `DriverStatus` to be assigned.
    ///
    /// # Example
    /// ```swift
    /// updateDriverStatus(someDriver, with: .inactive)
    /// ```
    ///
    /// - Note: The operation runs asynchronously inside a `Task`.
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
    
    /// Updates the status of a given vehicle both remotely and locally.
    ///
    /// This method attempts to update the status of the specified vehicle using the remote controller.
    /// If successful, it also updates the local `vehicles` array with the new status.
    /// Errors encountered during the remote update are logged.
    ///
    /// - Parameters:
    ///   - vehicle: The `Vehicle` object whose status needs to be updated.
    ///   - newStatus: The new `VehicleStatus` to be applied.
    ///
    /// # Example
    /// ```swift
    /// updateVehicleStatus(someVehicle, with: .inactive)
    /// ```
    ///
    /// - Note: This operation is performed asynchronously within a `Task`.
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
    
    /// Fetches a registered driver by their UUID asynchronously.
    ///
    /// This method communicates with the remote controller to retrieve the driver details.
    /// If the operation fails, it logs an error and returns `nil`.
    ///
    /// - Parameter id: The UUID of the driver to fetch.
    /// - Returns: A `Driver` object if the fetch is successful, otherwise `nil`.
    ///
    /// # Example
    /// ```swift
    /// let driver = await getRegisteredDriver(by: someUUID)
    /// ```
    func getRegisteredDriver(by id: UUID) async -> Driver? {
        do {
            return try await remoteController.getRegisteredDriver(by: id)
        } catch {
            print("Error while fetching the driver by id: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Fetches a registered vehicle by its ID asynchronously.
    ///
    /// This method calls the remote controller to retrieve a vehicle associated with the given ID.
    /// If the fetch fails, it prints an error message and returns `nil`.
    ///
    /// - Parameter id: The unique identifier of the vehicle to be retrieved.
    /// - Returns: A `Vehicle` object if successful, otherwise `nil`.
    ///
    /// # Example
    /// ```swift
    /// let vehicle = await getRegisteredVehicle(by: 101)
    /// ```
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
    
    /// Fetches the metadata for a user by their unique identifier.
    ///
    /// - Parameter id: The unique identifier (UUID) of the user.
    /// - Returns: A `UserMetaData` object if the request is successful, otherwise `nil`.
    /// - Note: This function performs an asynchronous network request.
    /// - Throws: Prints an error message if fetching metadata fails.
    ///
    /// Usage:
    /// ```swift
    /// let userMetaData = await getUserMetaData(by: userId)
    /// if let metaData = userMetaData {
    ///     print("User metadata fetched: \(metaData)")
    /// } else {
    ///     print("Failed to fetch user metadata.")
    /// }
    /// ```
    func getUserMetaData(by id: UUID) async -> UserMetaData? {
        do {
            return try await remoteController.getUserMetaData(by: id)
        } catch {
            print("Error while fetching user meta data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Adds a new maintenance personnel to the system asynchronously.
    ///
    /// - Parameters:
    ///   - personnel: The `MaintenancePersonnel` object containing metadata like email, phone number, and full name.
    ///   - password: The password to be associated with the new maintenance personnel account.
    ///
    /// - Discussion:
    ///   - This function follows these steps:
    ///     1. Saves the current fleet manager's ID before performing any operations.
    ///     2. Creates a new maintenance personnel account with the given email and password.
    ///     3. Retrieves the highest existing employee ID and increments it for the new personnel.
    ///     4. Saves the personnel metadata (phone number, full name, and employee ID).
    ///     5. Ensures that the fleet manager session remains active after personnel creation.
    ///     6. Updates the UI by appending the new personnel to the `maintenancePersonnels` array on the main thread.
    ///
    /// - Throws: An error if any of the async operations fail.
    ///
    /// - Note: If the fleet manager session is lost during personnel creation, an attempt is made to restore it.
    ///
    func addMaintenancePersonnel(_ personnel: MaintenancePersonnel, password: String) async {
        do {
            // Save the current fleet manager ID before any operations
            if let currentUser = user, currentUser.role == .fleetManager {
                AuthManager.shared.saveActiveFleetManager(id: currentUser.id)
            }
            
            // Create the new driver
            let new_personnel_uid = try await remoteController.createNewMaintenancePersonnel(personnel.meta_data.email, password: password)
            let employeeID = try await remoteController.getMaxEmployeeID(ofType: .maintenancePersonnel)
            
            // Add the driver metadata
            let newPersonnel = try await remoteController.addNewMaintenancePersonnelMetaData(by: new_personnel_uid, phoneNumber: personnel.meta_data.phone, fullName: personnel.meta_data.fullName, employeeID: employeeID+1, serviceCenterID: personnel.serviceCenterID)
            
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
                self.maintenancePersonnels.append(newPersonnel)
            }
        } catch {
            print("Error adding maintenance personnel: \(error.localizedDescription)")
        }
    }
    
    func removeMaintenancePersonnel(_ personnel: MaintenancePersonnel) {
        Task {
            do {
                var inactiveMaintainencePersonnel = personnel
                inactiveMaintainencePersonnel.meta_data.activeStatus = false
                try await remoteController.updateUserActiveStatus(by: inactiveMaintainencePersonnel.id, with: false)
                DispatchQueue.main.async {
                    self.maintenancePersonnels.removeAll { $0 == personnel }
                    self.maintenancePersonnels.append(inactiveMaintainencePersonnel)
                }
            } catch {
                print("Error while removing the Maintenance Personnel: \(error.localizedDescription)")
            }
        }
    }
    
    func enableMaintenancePersonnel(_ personnel: MaintenancePersonnel) {
        Task {
            do {
                var activePersonnel = personnel
                activePersonnel.meta_data.activeStatus = true
                try await remoteController.updateUserActiveStatus(by: personnel.id, with: true)
                maintenancePersonnels.removeAll { $0 == personnel }
                maintenancePersonnels.append(activePersonnel)
            } catch {
                print("Error while enabling the driver: \(error.localizedDescription)")
            }
        }
    }
    
    /// Retrieves a registered maintenance personnel by their unique identifier.
    ///
    /// - Parameter id: The `UUID` of the maintenance personnel to fetch.
    /// - Returns: A `MaintenancePersonnel` object if found, otherwise `nil`.
    ///
    /// - Discussion:
    ///   - This function attempts to fetch a registered maintenance personnel from `remoteController`.
    ///   - If the operation fails, an error message is printed, and `nil` is returned.
    ///
    /// - Throws: This function handles errors internally and does not propagate them.
    ///
    func getRegisteredMaintenancePersonnel(by id: UUID) async -> MaintenancePersonnel? {
        do {
            return try await remoteController.getRegisteredMaintenancePersonnel(by: id)
        } catch {
            print("Error while fetching the maintenance personnel by id: \(error.localizedDescription)")
            return nil
        }
    }
    

    /// Assigns a new maintenance task to the specified personnel for a given vehicle.
    ///
    /// This asynchronous function communicates with a remote controller to assign a new maintenance task.
    /// It takes the ID of Manager or Driver, personnel's ID, vehicle ID, the type of maintenance task, and an issue note
    /// describing the problem. In case of an error during the assignment, the function returns `nil`
    /// and prints an error message to the console.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the manager or driver assigning the task.
    ///   - personnelID: The unique identifier of the personnel to whom the task is being assigned.
    ///   - vehicleID: The ID of the vehicle requiring maintenance.
    ///   - type: The type of maintenance task to be performed.
    ///   - issueNote: A string describing the issue to be addressed.
    /// - Returns: A `MaintenanceTask` object if the assignment is successful, or `nil` if an error occurs.
    ///
    /// - Throws: This function does not throw errors directly, but errors encountered during
    ///          the assignment process are caught and logged.
    ///
    /// # Example Usage:
    /// ```swift
    /// let task = await assignNewMaintenanceTask(by: UUID(), to: UUID(), for: 101, ofType: .oilChange, "Oil leakage from the engine.")
    /// if let task = task {
    ///     print("Maintenance task assigned: \(task)")
    /// } else {
    ///     print("Failed to assign maintenance task.")
    /// }
    /// ```
    func assignNewMaintenanceTask(by id: UUID, to personnelID: UUID,
                                  for vehicleID: Int, ofType type: MaintenanceTaskType,
                                  _ issueNote: String) async -> MaintenanceTask? {
        do {
            return try await remoteController.assignNewMaintenanceTask(by: id, to: personnelID, for: vehicleID, ofType: type, issueNote)
        } catch {
            print("Error while assigning new maintenance tasks: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Updates the status of a maintenance task to "in-progress".
    ///
    /// This asynchronous function communicates with a remote controller to update the status
    /// of a specified maintenance task to "in-progress". In case of an error during the update,
    /// it catches the error and logs the message to the console.
    ///
    /// - Parameter id: The unique identifier of the maintenance task to be updated.
    ///
    /// # Example Usage:
    /// ```swift
    /// await makeMaintenanceTaskInProgress(by: UUID())
    /// ```
    func makeMaintenanceTaskInProgress(by id: UUID) async {
        do {
            try await remoteController.makeMaintenanceTaskInProgress(by: id)
        } catch {
            print("Error while updating the maintenance task status to in-progress: \(error.localizedDescription)")
        }
    }
    
    /// Updates the estimated completion date of a maintenance task.
    ///
    /// This asynchronous function communicates with a remote controller to update the estimated
    /// completion date of a specified maintenance task. If an error occurs during the update process,
    /// it catches the error and logs the message to the console.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the maintenance task whose estimated date needs to be updated.
    ///   - date: The new estimated completion date for the maintenance task.
    ///
    /// # Example Usage:
    /// ```swift
    /// await updateMaintenanceTaskEstimatedDate(by: UUID(), Date())
    /// ```
    func updateMaintenanceTaskEstimatedDate(by id: UUID, _ date: Date) async {
        do {
            try await remoteController.updateMaintenanceTaskEstimatedDate(by: id, date)
        } catch {
            print("Error while updating the estimated date of maintenance task: \(error.localizedDescription)")
        }
    }
    
    /// Creates an invoice for a maintenance task, including detailed expenses and a repair note.
    ///
    /// This asynchronous function communicates with a remote controller to generate an invoice
    /// for a specified maintenance task. It accepts the task ID, a dictionary of expenses categorized
    /// by maintenance expense type, and a repair note detailing the work done. If an error occurs
    /// during invoice creation, it catches the error and logs the message to the console.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the maintenance task for which the invoice is being created.
    ///   - expenses: A dictionary mapping `MaintenanceExpenseType` to the associated cost of each expense.
    ///   - repairNote: A string providing details about the repair work performed.
    ///
    /// # Example Usage:
    /// ```swift
    /// let expenses: [MaintenanceExpenseType: Double] = [.laborsCost: 150.0, .partsCost: 300.0]
    /// await createInvoiceForMaintenanceTask(by: UUID(), expenses: expenses, "Replaced brake pads and performed an oil change.")
    /// ```
    func createInvoiceForMaintenanceTask(by id: UUID, expenses: [MaintenanceExpenseType: Double], _ repairNote: String) async {
        do {
            try await remoteController.createInvoiceForMaintenanceTask(by: id, expenses: expenses, repairNote)
        } catch {
            print("Error while creating the invoice for maintenance task: \(error.localizedDescription)")
        }
    }
    
    /// Retrieves the assigned status of a service center to maintenance personnel asynchronously.
    ///
    /// This function checks whether a specific service center (identified by its `id`) has been assigned to a maintenace personnel
    /// If the operation fails, it prints an error message and returns `nil`.
    ///
    /// - Parameter id: The unique identifier of the service center whose assignment status is being checked.
    /// - Returns: An optional `Bool` indicating whether the service center is assigned to a maintenance personnel. Returns `nil` if the fetch operation fails.
    ///
    /// # Example Usage
    /// ```swift
    /// if let isAssigned = await getVehicleServiceCenterAssignedStatus(by: vehicleID) {
    ///     if isAssigned {
    ///         print("Service center is assigned to a maintenance personnel.")
    ///     } else {
    ///         print("Service Center is not assigned to any maintenance personnel.")
    ///     }
    /// } else {
    ///     print("Failed to retrieve service center assignment status.")
    /// }
    /// ```
    func getVehicleServiceCenterAssignedStatus(by id: Int) async -> Bool? {
        do {
            return try await remoteController.getVehicleServiceCenterAssignedStatus(by: id)
        } catch {
            print("Error while fetching the assinged status of service center: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Retrieves the service center associated with a specific maintenance personnel asynchronously.
    ///
    /// This function fetches the `ServiceCenter` object linked to a given maintenance personnel (identified by its `serviceCenterID`).
    /// If the operation fails, it prints an error message and returns `nil`.
    ///
    /// - Parameter id: The unique identifier of the service center which is being retrieved.
    /// - Returns: An optional `ServiceCenter` object representing the service center associated with the maintenance personnel. Returns `nil` if the fetch operation fails.
    ///
    /// # Example Usage
    /// ```swift
    /// if let serviceCenter = await getVehicleServiceCenter(by: maintenancePersonnel.serviceCenterID) {
    ///     print("Service Center is found")
    /// } else {
    ///     print("Failed to fetch the service center for the given id.")
    /// }
    /// ```
    func getVehicleServiceCenter(by id: Int) async -> ServiceCenter? {
        do {
            return try await remoteController.getVehicleServiceCenter(by: id)
        } catch {
            print("Error while fetching the service center: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Updates the service center location of a maintenance personnel asynchronously.
    ///
    /// This function updates the assigned service center of a maintenance personnel identified by their unique `id` with a new service center ID.
    /// If the operation fails, it prints an error message.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the maintenance personnel whose service center needs to be updated.
    ///   - newCenterID: The identifier of the new service center to be assigned.
    ///
    /// # Example Usage
    /// ```swift
    /// await updateMaintenancePersonnelServiceCenter(by: personnelID, with: newCenterID)
    /// print("Service center updated successfully!")
    /// ```
    func updateMaintenancePersonnelServiceCenter(by id: UUID, with newCenterID: Int) async {
        do {
            try await remoteController.updateMaintenancePersonnelServiceCenter(by: id, with: newCenterID)
        } catch {
            print("Error while updating service center location of maintenance personnel: \(error.localizedDescription)")
        }
    }
    


    
    /// Retrieves the maintenance personnel associated with a specific service center asynchronously.
    ///
    /// This function fetches the `MaintenancePersonnel` object linked to a given service center (identified by its `centerID`).
    /// If the operation fails, it prints an error message and returns `nil`.
    ///
    /// - Parameter centerID: The unique identifier of the service center whose maintenance personnel is being retrieved.
    /// - Returns: An optional `MaintenancePersonnel` object representing the personnel associated with the given service center. Returns `nil` if the fetch operation fails.
    ///
    /// # Example Usage
    /// ```swift
    /// if let personnel = await getMaintenancePersonnel(ofCenter: centerID) {
    ///     print("Maintenance Personnel Name: \(personnel.meta_data.fullName)")
    /// } else {
    ///     print("Failed to fetch maintenance personnel for the given service center.")
    /// }
    /// ```
    func getMaintenancePersonnel(ofCenter centerID: Int) async -> MaintenancePersonnel? {
        do {
            return try await remoteController.getMaintenancePersonnel(ofCenter: centerID)
        } catch {
            print("Error while fetching maintenance personnel of service center(\(centerID)): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Retrieves the metadata of maintenance personnel associated with a specific service center asynchronously.
    ///
    /// This function fetches the `UserMetaData` object linked to a given service center (identified by its `centerID`).
    /// If the operation fails, it prints an error message and returns `nil`.
    ///
    /// - Parameter centerID: The unique identifier of the service center whose maintenance personnel metadata is being retrieved.
    /// - Returns: An optional `UserMetaData` object containing metadata of the personnel associated with the given service center. Returns `nil` if the fetch operation fails.
    ///
    /// # Example Usage
    /// ```swift
    /// if let metaData = await getMaintenancePersonnelMetaData(ofCenter: centerID) {
    ///     print("Personnel Employee ID: \(metaData.employeeID)")
    /// } else {
    ///     print("Failed to fetch maintenance personnel metadata for the given service center.")
    /// }
    /// ```
    func getMaintenancePersonnelMetaData(ofCenter centerID: Int) async -> UserMetaData? {
        do {
            return try await remoteController.getMaintenancePersonnelMetaData(ofCenter: centerID)
        } catch {
            print("Error while fetching personnel meta data of service center (\(centerID)): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Updates the coordinates of a vehicle asynchronously and returns the updated coordinate as a string.
    ///
    /// This function updates the geographical coordinates (latitude and longitude) of a vehicle identified by its `id`.
    /// If the update operation is successful, it returns the new coordinates as a formatted string `"latitude, longitude"`.
    /// If the operation fails, it prints an error message and returns `nil`.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the vehicle whose coordinates are being updated.
    ///   - latitude: The new latitude of the vehicle as a `String`.
    ///   - longitude: The new longitude of the vehicle as a `String`.
    /// - Returns: An optional `String` representing the updated coordinates in the format `"latitude, longitude"`. Returns `nil` if the update operation fails.
    ///
    /// # Example Usage
    /// ```swift
    /// if let updatedCoordinate = await updateVehicleCoordinate(by: vehicleID, latitude: "28.7041", longitude: "77.1025") {
    ///     print("Vehicle coordinates updated to: \(updatedCoordinate)")
    /// } else {
    ///     print("Failed to update vehicle coordinates.")
    /// }
    /// ```
    func updateVehicleCoordinate(by id: Int, latitude: String, longitude: String) async -> String? {
        do {
            return try await remoteController.updateVehicleCoordinate(by: id, latitude: latitude, longitude: longitude)
        } catch {
            print("Error while updating vehicle coordinate: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Sends a push notification message to a specified recipient asynchronously.
    ///
    /// This function creates a push notification object and sends it using the notifier.
    /// If the notifier is not initialized, it logs an error message and exits.
    ///
    /// - Parameters:
    ///   - recipientID: The unique identifier of the message recipient.
    ///   - title: The title of the message to be sent.
    ///   - message: The content of the message.
    /// - Returns: Void
    ///
    /// # Example Usage
    /// ```swift
    /// await sendMessage(to: recipientID, title: "Emergency", message: "SOS! Please help.")
    /// ```
    ///
    /// - Note: This function requires the notifier to be initialized before calling.
    func sendMessage(to recipientID: UUID, title: String, message: String) async {
        guard let notifier else {
            print("Can't send message notifier is not initialzied.")
            return
        }
        
        let pushNotification = IFEPushNotification(id: UUID(),
                                                   senderID: user!.id,
                                                   recipientID: recipientID,
                                                   title: title,
                                                   message: message,
                                                   sentAt: .now)
        
        await notifier.sendNotification(pushNotification)
    }
    
    /// Marks a trip as SOS asynchronously.
    ///
    /// This function updates the trip status to SOS in the remote database.
    /// If the user role is `.driver`, it also updates the local trip status to SOS.
    /// If the operation fails, an error message is logged.
    ///
    /// - Parameter id: The unique identifier of the trip to be marked as SOS.
    /// - Returns: Void
    ///
    /// # Example Usage
    /// ```swift
    /// await markTripForSOS(by: tripID)
    /// ```
    func markTripForSOS(by id: UUID) async {
        do {
            try await remoteController.markTripForSOS(by: id)
            if user?.role == .driver {
                updateLocalDriverTripStatus(by: id, to: .sos)
            }
        } catch {
            print("Error while making trip status to SOS: \(error.localizedDescription)")
        }
    }
    
    /// Marks a trip's SOS status as resolved asynchronously.
    ///
    /// This function updates the trip status to indicate that the SOS has been resolved.
    /// If the operation fails, an error message is logged.
    ///
    /// - Parameter id: The unique identifier of the trip whose SOS status needs to be resolved.
    /// - Returns: Void
    ///
    /// # Example Usage
    /// ```swift
    /// await markTripSOSResolved(by: tripID)
    /// ```
    func markTripSOSResolved(by id: UUID) async {
        do {
            try await remoteController.markTripSOSResolved(by: id)
        } catch {
            print("Error while resolving the trip SOS: \(error.localizedDescription)")
        }
    }
    
    /// Updates the status of a local driver trip.
    ///
    /// This function searches for the trip with the given ID in the list of driver's trips.
    /// If found, it updates the trip's status to the new status.
    /// If the trip is not found, an error message is logged.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the trip to update.
    ///   - newStatus: The new status to assign to the trip.
    ///
    /// # Example Usage
    /// ```swift
    /// updateLocalDriverTripStatus(by: tripID, to: .sos)
    /// ```
    func updateLocalDriverTripStatus(by id: UUID, to newStatus: TripStatus) {
        let index = tripsForDriver.firstIndex(where: { $0.id == id })
        
        if let index { tripsForDriver[index].status = newStatus }
        else {
            print("Cannot find any trip with id: \(id)")
        }
    }
    
    /// Updates the status of a local manager trip.
    ///
    /// This function searches for the trip with the given ID in the list of manager's trips.
    /// If found, it updates the trip's status to the new status.
    /// If the trip is not found, an error message is logged.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the trip to update.
    ///   - newStatus: The new status to assign to the trip.
    ///
    /// # Example Usage
    /// ```swift
    /// updateLocalManagerTripStatus(by: tripID, to: .completed)
    /// ```
    func updateLocalManagerTripStatus(by id: UUID, to newStatus: TripStatus) {
        let index = trips.firstIndex(where: { $0.id == id })
        
        if let index { trips[index].status = newStatus }
        else {
            print("Cannot find any trip with id: \(id)")
        }
    }
}
