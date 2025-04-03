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
    
    @Published var drivers: [Driver] = []
    @Published var vehicles: [Vehicle] = []
    @Published var trips: [Trip] = []
    @Published var tripsForDriver: [Trip] = []
    @Published var maintenancePersonnels: [MaintenancePersonnel] = []
    @Published var managerAssignedMaintenanceTasks: [MaintenanceTask] = []
    @Published var personnelTasks: [MaintenanceTask] = []
    @Published var vehicleCompanies: [String] = []
    @Published var serviceCenters: [ServiceCenter] = []
    @Published var serviceCenterLocations: [Int: String] = [:]
    
    
    let remoteController = RemoteController.shared
    
    init() {
        Task { @MainActor in
            await fetchUser()
            if let user = user {
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
     func loadDrivers() async {
        do {
            drivers = try await remoteController.getRegisteredDrivers()
        } catch {
            print("Error while fetching registered drivers: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func loadVehicles() async {
        do {
            vehicles = try await remoteController.getRegisteredVehicles()
        } catch {
            print("Error while fetching registered vehicles: \(error.localizedDescription)")
        }
    }
    
    @MainActor
     func loadMaintenancePersonnels() async {
        do {
            maintenancePersonnels = try await remoteController.getRegisteredMaintenancePersonnels()
        } catch {
            print("Error while fetching registered maintenance personnels: \(error.localizedDescription)")
        }
    }
    
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
    
    @MainActor
     func loadVehicleCompanies() async {
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
                    tripsForDriver = try await remoteController.getDriverTrips(by: user.id)
                }
            }
        }catch {
            print("Error while fetching trips for driver : \(error.localizedDescription)")
        }
    }
    
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
}
