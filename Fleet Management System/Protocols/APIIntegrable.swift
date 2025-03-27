//
//  ServerControllerProtocol.swift
//  Fleet Management System
//
//  Created by Abcom on 20/03/25.
//

import Foundation

protocol DatabaseAPIIntegrable {
    //MARK: User APIs
    func getUserMetaData(by id: UUID) async throws -> UserMetaData
    
    func getFleetManager(by id: UUID) async throws -> FleetManager
    
    func createNewDriver(_ email: String, password: String) async throws -> UUID
    
    func createNewMaintenancePersonnel(_ email: String, password: String) async throws -> UUID
    
    func updateUserPhone(by id: UUID, _ phone: String) async throws
    
    func addNewDriverMetaData(by id: UUID,
                   phoneNumber: String,
                   fullName: String,
                   employeeID: Int,
                   licenseNumber: String) async throws -> Driver
    
    func addNewMaintenancePersonnelMetaData(by id: UUID,
                                            phoneNumber: String,
                                            fullName: String,
                                            employeeID: Int) async throws -> MaintenancePersonnel
    
    func getRegisteredMaintenancePersonnels() async throws -> [MaintenancePersonnel]
    
    func getRegisteredMaintenancePersonnel(by id: UUID) async throws -> MaintenancePersonnel
    
    func updateDriverStatus(by id: UUID, _ newStatus: DriverStatus) async throws
    
    func getRegisteredDrivers() async throws -> [Driver]
    
    func getRegisteredDriver(by id: UUID) async throws -> Driver
    
    func getUserEmail(by id: UUID) async throws -> String
    
    func updateUserActiveStatus(by id: UUID, with status: Bool) async throws
    
    func getOfflineDrivers() async throws -> [Driver]
    
    func getMaxEmployeeID(ofType type: Role) async throws -> Int
    
    
    
    //MARK: Vehicle APIs
    func addNewVehicle(_ vehicle: Vehicle) async throws -> Int
    
    func getRegisteredVehicles() async throws -> [Vehicle]
    
    func getRegisteredVehicle(by id: Int) async throws -> Vehicle
    
    func getRegisteredVehicleCompanies() async throws -> [String]
    
    func updateVehicleExpiry(by id: Int, with expiry: (puc: Date, insurance: Date, registration: Date)) async throws
    
    func updateVehicleStatus(by id: Int, with status: VehicleStatus) async throws
    
    func updateVehicleActiveStatus(by id: Int, with status: Bool) async throws
    
    
    //MARK: Trip APIs
    func assignNewTrip(assignedBy: UUID,
                       pickupCoordinates: (latitude: Double, longitude: Double),
                       destinationCoordinates: (latitude: Double, longitude: Double),
                       assignedVehicleId: Int,
                       assignedDriverIDs: [UUID],
                       estimatedDateTime: Date,
                       description: String,
                       totalDistance: Int,
                       totalTripDuration: (hours: Int, minutes: Int),
                       scheduledDateTime: Date) async throws -> Trip
    
    func updateTripStatus(by id: UUID, to new_status: TripStatus) async throws
    
    func getManagerAssignedTrips(by id: UUID) async throws -> [Trip]
    
    func getDriverTrips(by id: UUID) async throws -> [Trip]
    
    
    func getTripInspectionForTrip(by id: UUID) async throws -> TripInspection
    
    func addPreTripInspectionForTrip(by id: UUID,
                                     inspection: [TripInspectionItem: Bool],
                                     note: String) async throws
    
    func addPostTripInspectionForTrip(by id: UUID,
                                      inspection: [TripInspectionItem: Bool],
                                      note: String) async throws
    
    //MARK: Maintenance Task
    func assignNewMaintenanceTask(byManagerID: UUID, to personnelID: UUID,
                                  for vehicleID: Int, ofType type: MaintenanceTaskType,
                                  _ issueNote: String) async throws -> MaintenanceTask
    
    func getManagerAssignedMaintenanceTasks(by id: UUID) async throws -> [MaintenanceTask]
    
    func getMaintenancePersonnelTasks(bu id: UUID) async throws -> [MaintenanceTask]
    
    func makeMaintenanceTaskInProgress(by id: UUID) async throws
    
    func updateMaintenanceTaskEstimatedDate(by id: UUID, _ date: Date) async throws
    
    func createInvoiceForMaintenanceTask(by id: UUID, expenses: [MaintenanceExpenseType: Double], _ repairNote: String) async throws
}
