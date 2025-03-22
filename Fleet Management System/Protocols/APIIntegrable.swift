//
//  ServerControllerProtocol.swift
//  Fleet Management System
//
//  Created by Abcom on 20/03/25.
//

import Foundation

protocol DatabaseAPIIntegrable {
    //MARK: User APIs
    func getManagerProfile(by id: UUID) async throws -> FleetManager
    
    func getUsers(ofType type: Role) async throws -> [UserRoles]
    
    func getRegisteredDrivers(by userRoles: [UserRoles]) async throws -> [Driver]
    
    func getUserEmail(by id: UUID) async throws -> String
    
    func updateUserWorkingStatus(by id: UUID, with status: Bool) async throws
    
    
    //MARK: Vehicle APIs
    func addNewVehicle(_ vehicle: Vehicle) async throws
    
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
