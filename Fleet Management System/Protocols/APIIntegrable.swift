//
//  ServerControllerProtocol.swift
//  Fleet Management System
//
//  Created by Abcom on 20/03/25.
//

import Foundation

protocol DatabaseAPIIntegrable {
    //MARK: User APIs
    func getFleetManager(by id: UUID) async throws -> FleetManager
    
    func createNewDriver(_ email: String, password: String) async throws -> UUID
    
    func updateUserPhone(by id: UUID, _ phone: String) async throws
    
    func addNewDriverMetaData(by id: UUID,
                   phoneNumber: String,
                   fullName: String,
                   employeeID: Int,
                   licenseNumber: String) async throws -> Driver
    
    func updateDriverStatus(by id: UUID, _ newStatus: DriverStatus) async throws
    
    func getRegisteredDrivers() async throws -> [Driver]
    
    func getUserEmail(by id: UUID) async throws -> String
    
    func updateUserActiveStatus(by id: UUID, with status: Bool) async throws
    
    func getMaxEmployeeID(ofType type: Role) async throws -> Int
    
    
    //MARK: Vehicle APIs
    func addNewVehicle(_ vehicle: Vehicle) async throws -> Int
    
    func getRegisteredVehicles() async throws -> [Vehicle]
    
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
                       scheduledDateTime: Date) async throws -> UUID
    
    func getManagerAssignedTrips(by id: UUID) async throws -> [Trip]
    
    func getDriverTrips(by id: UUID) async throws -> [Trip]
}
