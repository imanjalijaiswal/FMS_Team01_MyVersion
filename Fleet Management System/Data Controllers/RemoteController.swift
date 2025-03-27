//
//  RemoteController.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 21/03/25.
//

import Foundation

import Supabase
import SwiftUI
import Auth
import SwiftSMTP

extension Date {
    func formatDateForSupabase() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: self)
    }
}

class RemoteController: DatabaseAPIIntegrable {
    func getUserMetaData(by id: UUID) async throws -> UserMetaData {
        return try await client
            .rpc("get_user_meta_data_for_id", params: ["p_id": id.uuidString])
            .execute().value
    }
    
    func getOfflineDrivers() async throws -> [Driver] {
        return try await client
            .rpc("get_offline_drivers").execute().value
    }
    
    func getTripInspectionForTrip(by id: UUID) async throws -> TripInspection {
        return try await client
            .rpc("get_trip_inspection_for_trip_id", params: ["p_id": id.uuidString])
            .execute().value
    }
    
    func addPreTripInspectionForTrip(by id: UUID, inspection: [TripInspectionItem : Bool], note: String) async throws {
        struct PreInspectionParams: Codable {
            let p_id: String
            let p_pre_trip_inspection: [TripInspectionItem: Bool]
            let p_note: String
        }
        
        let params = PreInspectionParams(p_id: id.uuidString, p_pre_trip_inspection: inspection, p_note: note)
        
        try await client
            .rpc("add_pre_trip_inspection_for_trip_id", params: params)
            .execute().value
    }
    
    func addPostTripInspectionForTrip(by id: UUID, inspection: [TripInspectionItem : Bool], note: String) async throws {
        struct PostInspectionParams: Codable {
            let p_id: String
            let p_post_trip_inspection: [TripInspectionItem: Bool]
            let p_note: String
        }
        
        let params = PostInspectionParams(p_id: id.uuidString, p_post_trip_inspection: inspection, p_note: note)
        
        try await client
            .rpc("add_post_trip_inspection_for_trip_id", params: params)
            .execute().value
    }
    
    func updateTripStatus(by id: UUID, to newStatus: TripStatus) async throws {
        try await client
            .rpc("update_trip_status_for_id", params: [
                "p_trip_uuid": id.uuidString,
                "p_new_status": newStatus.rawValue])
            .execute()
    }
    
    func getRegisteredVehicle(by id: Int) async throws -> Vehicle {
        return try await client
            .rpc("get_vehicle_data_by_id", params: ["p_id": id])
            .execute().value
    }
    
    func getRegisteredVehicleCompanies() async throws -> [String] {
        return try await client
            .rpc("get_registered_vehicle_companies")
            .execute().value
    }
    
    func getRegisteredDriver(by id: UUID) async throws -> Driver {
        return try await client
            .rpc("get_driver_data_by_id", params: ["p_id": id.uuidString])
            .execute().value
    }
    
    func updateDriverStatus(by id: UUID, _ newStatus: DriverStatus) async throws {
        try await client
            .rpc("update_driver_status_by_id", params: [
                "p_id": id.uuidString,
                "p_new_status": newStatus.rawValue
            ]).execute()
    }
    
    func updateUserPhone(by id: UUID, _ phone: String) async throws {
        try await client
            .rpc("update_user_phone_by_id", params: [
                "p_id": id.uuidString,
                "p_phone": phone
            ])
            .execute()
    }
    
    func createNewDriver(_ email: String, password: String) async throws -> UUID {
        // Store the current session before creating a new driver
        let currentSession = try? await client.auth.session
        
        // Create the new driver account
        let authResponse = try await client.auth.signUp(email: email, password: password)
        
        // Extract the new driver's user ID
        let userId = authResponse.user.id
        
        // If we had a session before and the new user creation changed it, restore it
        if let session = currentSession, try await client.auth.session.user.id != session.user.id {
            // Re-authenticate with the stored session token to restore the fleet manager's session
            try await client.auth.setSession(accessToken: session.accessToken, refreshToken: session.refreshToken)
        }
        
        return userId
    }
    
    func getMaxEmployeeID(ofType type: Role) async throws -> Int {
        return try await client
            .rpc("get_max_employee_id_of_type", params: ["p_type": type])
            .execute().value
    }
    
    func addNewDriverMetaData(by id: UUID, phoneNumber: String, fullName: String, employeeID: Int, licenseNumber: String) async throws -> Driver {
        struct AddDriverParams: Encodable {
            let p_id: UUID
            let p_phone: String
            let p_display_name: String
            let p_employee_id: Int
            let p_created_at: String
            let p_license_number: String
        }
        
        let params = AddDriverParams(p_id: id, p_phone: phoneNumber, p_display_name: fullName,
                                     p_employee_id: employeeID,
                                     p_created_at: ISO8601DateFormatter().string(from: .now),
                                     p_license_number: licenseNumber)
        
        let driver: Driver = try await client
            .rpc("add_new_driver",params: params)
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
                       scheduledDateTime: Date) async throws -> Trip {
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
        
        let newTrip: Trip = try await client
            .rpc("assign_new_trip",params: params)
            .execute()
            .value
        
        return newTrip
    }
    
    func getManagerAssignedTrips(by id: UUID) async throws -> [Trip] {
        let response: [Trip] = try await client
                .rpc("get_assigned_trips_by_manager_id", params: [
                    "p_manager_id": id.uuidString
                ])
                .execute()
                .value

//        let trips: [Trip] = try JSONDecoder().decode([Trip].self, from: response.data)
//        return trips
        return response
    }
    
    func getDriverTrips(by id: UUID) async throws -> [Trip] {
        let response: [Trip] = try await client
                .rpc("get_assigned_trips_for_driver_id", params: [
                    "p_driver_id": id.uuidString
                ])
                .execute()
                .value

//        let decodedTrips = try JSONDecoder().decode([Trip].self, from: response.data)

        return response
    }
    
    func updateVehicleExpiry(by id: Int, with expiry: (puc: Date, insurance: Date, registration: Date)) async throws {
        struct UpdateVehicleRegistrationParams: Encodable {
            let p_id: Int
            let p_new_insurance_expiry_date: String
            let p_new_puc_expiry_date: String
            let p_new_rc_expiry_date: String
        }
        
        let params = UpdateVehicleRegistrationParams(
            p_id: id,
            p_new_insurance_expiry_date: ISO8601DateFormatter().string(from: expiry.insurance),
            p_new_puc_expiry_date: ISO8601DateFormatter().string(from: expiry.puc),
            p_new_rc_expiry_date: ISO8601DateFormatter().string(from: expiry.registration)
        )
        
        try await client
            .rpc("update_vehicle_expiry_by_id",params: params)
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
            let p_id: Int
            let p_new_status: Bool
        }
        
        let params = UpdateVehicleActiveStatusParams(
            p_id: id,
            p_new_status: status
        )
        
        try await client
            .rpc("update_vehicle_active_status_for_id",params: params)
            .execute()
    }
    
    func updateUserActiveStatus(by id: UUID, with status: Bool) async throws {
        struct UpdateUserStatusParams: Encodable {
            let p_user_uuid: String
            let p_new_status: Bool
        }
        
        let params = UpdateUserStatusParams(
            p_user_uuid: id.uuidString, // Convert UUID to String
            p_new_status: status
        )

        try await client
            .rpc("update_user_active_status_by_id", params: params)
            .execute()
    }
    
    func addNewVehicle(_ vehicle: Vehicle) async throws -> Int {
        struct AddNewVehicleParams: Encodable {
            let p_make: String
            let p_model: String
            let p_vinNumber: String
            let p_licenseNumber: String
            let p_fuelType: String
            let p_loadCapacity: String
            let p_insurancePolicyNumber: String
            let p_insuranceExpiryDate: String
            let p_pucCertificateNumber: String
            let p_pucExpiryDate: String
            let p_rcNumber: String
            let p_rcExpiryDate: String
            let p_currentCoordinate: String
        }
        
        let insuranceExpiryDate = vehicle.insuranceExpiryDate.formatDateForSupabase()
        let pucExpiryDate = vehicle.pucExpiryDate.formatDateForSupabase()
        let rcExpiryDate = vehicle.rcExpiryDate.formatDateForSupabase()
        
        let params = AddNewVehicleParams(p_make: vehicle.make, p_model: vehicle.model,
                                         p_vinNumber: vehicle.vinNumber, p_licenseNumber: vehicle.licenseNumber,
                                         p_fuelType: vehicle.fuelType.rawValue,
                                         p_loadCapacity: String(vehicle.loadCapacity),
                                         p_insurancePolicyNumber: vehicle.insurancePolicyNumber,
                                         p_insuranceExpiryDate: insuranceExpiryDate,
                                         p_pucCertificateNumber: vehicle.pucCertificateNumber,
                                         p_pucExpiryDate: pucExpiryDate,
                                         p_rcNumber: vehicle.rcNumber,
                                         p_rcExpiryDate: rcExpiryDate,
                                         p_currentCoordinate: vehicle.currentCoordinate)
        return try await client
            .rpc("add_new_vehicle", params: params)
            .execute()
            .value
    }
    
    func getRegisteredVehicles() async throws -> [Vehicle] {
        let response = try await client
                .rpc("get_regsitered_vehicles")
                .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let vehicles = try decoder.decode([Vehicle].self, from: response.data)
        return vehicles
    }
    
    func getUserEmail(by id: UUID) async throws -> String {
        let email: String = try await client
            .from("auth.users")
            .select("email")
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        
        return email
    }
    
    func getFleetManager(by id: UUID) async throws -> FleetManager {
        return try await client
            .rpc("get_fleet_manager_data_by_id", params: ["p_id": id])
            .execute()
            .value
    }
    
    
    func getRegisteredDrivers() async throws -> [Driver] {
        return try await client
            .rpc("get_registered_drivers")
            .execute()
            .value
    }
    
    func getUserRole(by userId: String) async throws -> Role {
        struct UserRole: Codable {
            let role: String
        }
        
        let response = try await client
            .from("UserRoles").select("role").eq("id", value: userId).single()
            .execute()
        
        let userRole = try JSONDecoder().decode(UserRole.self, from: response.data)
        if userRole.role == "driver" { 
            return .driver 
        } else if userRole.role == "maintenancePersonnel" {
            return .maintenancePersonnel
        } else {
            return .fleetManager
        }
    }
   
    private let client = AuthManager.shared.client
    static let shared = RemoteController()
}
