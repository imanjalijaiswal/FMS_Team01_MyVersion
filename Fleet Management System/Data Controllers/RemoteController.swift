//
//  RemoteController.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 21/03/25.
//

import Foundation

import Supabase
import SwiftUI

class RemoteController: DatabaseAPIIntegrable{
    func addNewDriverMetaData(by id: UUID, phoneNumber: String, fullName: String, employeeID: Int, licenseNumber: String) async throws -> Driver {
        struct AddDriverParams: Encodable {
            let p_id: UUID
            let p_phone: String
            let p_display_name: String
            let p_employee_id: Int
            let p_licenseNumber: String
        }
        
        let params = AddDriverParams(p_id: id, p_phone: phoneNumber, p_display_name: fullName, p_employee_id: employeeID, p_licenseNumber: licenseNumber)
        
        let driver: Driver = try await client
            .rpc("add_new_driver_meta_data",params: params)
            .execute()
            .value
        
        return driver
    }
    
    func assignNewTrip(assignedBy: UUID,
                       pickupCoordinates: (latitude: Double, longitude: Double),
                       destinationCoordinates: (latitude: Double, longitude: Double),
                       assignedVehicleId: Int,
                       assignedDriverIDs: [UUID],
                       estimatedDateTime: Date,
                       description: String,
                       totalDistance: Int,
                       totalTripDuration: (hours: Int, minutes: Int),
                       scheduledDateTime: Date) async throws -> UUID {
        struct AssignTripParams: Encodable {
            let p_assigned_by: String
            let p_pickup_location: String
            let p_destination: String
            let p_vehicle_id: Int
            let p_driver_ids: [String]
            let p_estimated_arrival_date_time: String
            let p_description: String
            let p_total_distance: Int
            let p_total_trip_duration: String
            let p_scheduled_date_time: String
        }
        
        let driver_uuids = assignedDriverIDs.map({$0.uuidString})
        
        let params = AssignTripParams(p_assigned_by: assignedBy.uuidString,
                                      p_pickup_location: "\(pickupCoordinates.latitude), \(pickupCoordinates.longitude)",
                                      p_destination: "\(destinationCoordinates.latitude), \(destinationCoordinates.longitude)",
                                      p_vehicle_id: assignedVehicleId,
                                      p_driver_ids: driver_uuids,
                                      p_estimated_arrival_date_time: ISO8601DateFormatter().string(from: estimatedDateTime),
                                      p_description: description,
                                      p_total_distance: totalDistance,
                                      p_total_trip_duration: "\(totalTripDuration.hours) hours \(totalTripDuration.minutes) minutes",
                                      p_scheduled_date_time: ISO8601DateFormatter().string(from: scheduledDateTime))
        
        let newTripUUID: UUID = try await client
            .rpc("assign_new_trip",params: params)
            .execute()
            .value
        
        return newTripUUID
    }
    
    func getManagerAssignedTrips(by id: UUID) async throws -> [Trip] {
        let response = try await client
                .rpc("get_assigned_trips_by_manager_id", params: [
                    "p_manager_id": id.uuidString
                ])
                .execute()

        let decodedTrips = try JSONDecoder().decode([Trip].self, from: response.data)

        return decodedTrips
    }
    
    func getDriverTrips(by id: UUID) async throws -> [Trip] {
        let response = try await client
                .rpc("get_assigned_trip_for_driver_id", params: [
                    "p_driver_id": id.uuidString
                ])
                .execute()

        let decodedTrips = try JSONDecoder().decode([Trip].self, from: response.data)

        return decodedTrips
    }
    
    func updateVehicleExpiry(by id: Int, with expiry: (puc: Date, insurance: Date, registration: Date)) async throws {
        struct UpdateVehicleRegistrationParams: Encodable {
            let p_registered_id: Int
            let p_insurance_expiry_date: String
            let p_puc_expiry_date: String
            let p_rc_expiry_date: String
        }
        
        let params = UpdateVehicleRegistrationParams(
            p_registered_id: id,
            p_insurance_expiry_date: ISO8601DateFormatter().string(from: expiry.insurance),
            p_puc_expiry_date: ISO8601DateFormatter().string(from: expiry.puc),
            p_rc_expiry_date: ISO8601DateFormatter().string(from: expiry.registration)
        )
        
        try await client
            .rpc("update_registered_vehicle_for_id",params: params)
            .execute()
    }
    
    func updateVehicleStatus(by id: Int, with status: VehicleStatus) async throws {
        struct UpdateVehicleStatusParams: Encodable {
            let p_vehicle_id: Int
            let p_status: String
        }
        
        let params = UpdateVehicleStatusParams(
            p_vehicle_id: id,
            p_status: status.rawValue
        )
        
        try await client
            .rpc("update_vehicle_status_for_id",params: params)
            .execute()
    }
    
    func updateVehicleActiveStatus(by id: Int, with status: Bool) async throws {
        struct UpdateVehicleActiveStatusParams: Encodable {
            let p_vehicle_id: Int
            let p_new_status: Bool
        }
        
        let params = UpdateVehicleActiveStatusParams(
            p_vehicle_id: id,
            p_new_status: status
        )
        
        try await client
            .rpc("update_vehicle_active_status_for_id",params: params)
            .execute()
    }
    
    func updateUserWorkingStatus(by id: UUID, with status: Bool) async throws {
        struct UpdateUserStatusParams: Encodable {
            let p_user_uuid: String
            let p_new_status: Bool
        }
        
        let params = UpdateUserStatusParams(
            p_user_uuid: id.uuidString, // Convert UUID to String
            p_new_status: status
        )

        try await client
            .rpc("update_user_working_status_for_id", params: params)
            .execute()
    }
    
    func addNewVehicle(_ vehicle: Vehicle) async throws {
        try await client
            .rpc("add_new_vehicle",
                 params: [
                    "p_make": vehicle.make,
                    "p_model": vehicle.model,
                    "p_vinNumber": vehicle.vinNumber,
                    "p_licenseNumber": vehicle.licenseNumber,
                    "p_fuelType": vehicle.fuelType.rawValue,
                    "p_loadcapacity": String(vehicle.loadCapacity),
                    "p_insurancepolicynumber": vehicle.insurancePolicyNumber,
                    "p_insuranceexpirydate": ISO8601DateFormatter()
                        .string(from: vehicle.insuranceExpiryDate),
                    "p_puccertificatenumber": vehicle.pucCertificateNumber,
                    "p_pucexpirydate": ISO8601DateFormatter()
                        .string(from: vehicle.pucExpiryDate),
                    "p_rcnumber": vehicle.rcNumber,
                    "p_rcexpirydate": ISO8601DateFormatter()
                        .string(from: vehicle.rcExpiryDate)
                 ])
            .select()
            .execute()
            .value
    }
    
    func getRegisteredVehicles() async throws -> [Vehicle] {
        let vehicles: [Vehicle] = try await client
            .rpc("get_registered_vehicles")
            .execute()
            .value
        
        return vehicles
    }
    
    func getUserEmail(by id: UUID) async throws -> String {
        let email: String = try await client
            .rpc("get_user_email_by_id", params: ["p_user_uuid": id])
            .execute()
            .value
        
        return email
    }
    
    func getFleetManager(by id: UUID) async throws -> FleetManager {
        return try await client
            .rpc("get_fleet_manager_data_for_id", params: ["p_id": id])
            .execute()
            .value
    }
    
    
    func getRegisteredDrivers() async throws -> [Driver] {
        return try await client
            .rpc("get_registered_drivers")
            .execute()
            .value
    }
   
    private let client = AuthManager.shared.client
    
    static let shared = RemoteController()
}
