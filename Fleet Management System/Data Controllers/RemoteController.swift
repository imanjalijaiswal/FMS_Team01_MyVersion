//
//  RemoteController.swift
//  Fleet Management System
//
//  Created by Devansh Seth on 21/03/25.
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
    func updateVehicleCoordinate(by id: Int, latitude: String, longitude: String) async throws -> String {
        struct UpdateVehicleCoordinateParams: Codable {
            let p_id: Int
            let p_latitude: String
            let p_longitude: String
        }
        
        let params = UpdateVehicleCoordinateParams(p_id: id, p_latitude: latitude, p_longitude: longitude)
        
        try await client
            .rpc("update_vehicle_coordinate_by_id", params: params)
            .execute()
        
        return "\(latitude), \(longitude)"
    }
    
    func getMaintenancePersonnel(ofCenter centerID: Int) async throws -> MaintenancePersonnel {
        return try await client
            .rpc("get_maintenance_personnel_of_service_center_by_id", params: ["p_id": centerID])
            .execute().value
    }
    
    func getMaintenancePersonnelMetaData(ofCenter centerID: Int) async throws -> UserMetaData {
        return try await client
            .rpc("get_maintenance_personnel_meta_data_of_service_center_by_id", params: ["p_id": centerID])
            .execute().value
    }
    
    func updateMaintenancePersonnelServiceCenter(by id: UUID, with newCenterID: Int) async throws {
        struct UpdateServiceCenterParams: Codable {
            let p_id: String
            let p_service_center_id: Int
        }
        
        let params = UpdateServiceCenterParams(p_id: id.uuidString, p_service_center_id: newCenterID)
        
        try await client
            .rpc("update_maintenance_personnel_service_center_by_id", params: params)
            .execute()
    }
    
    func getVehicleServiceCenter(by id: Int) async throws -> ServiceCenter {
        return try await client
            .rpc("get_service_center_by_id", params: ["p_id": id])
            .execute().value
    }
    
    func getVehicleServiceCenterAssignedStatus(by id: Int) async throws -> Bool {
        return try await client
            .rpc("get_service_center_assigned_status_by_id", params: ["p_id": id])
            .execute().value
    }
    func getRegisteredServiceCenters() async throws -> [ServiceCenter] {
        return try await client
            .rpc("get_registered_vehicle_service_centers")
            .execute().value
    }
    
    func assignNewMaintenanceTask(by id: UUID, to personnelID: UUID, for vehicleID: Int, ofType type: MaintenanceTaskType, _ issueNote: String) async throws -> MaintenanceTask {
        struct AssignMaintenanceTaskParams: Codable {
            let p_assigned_by: String
            let p_assigned_to: String
            let p_vehicle_id: Int
            let p_task_type: String
            let p_note: String
        }
        
        let params = AssignMaintenanceTaskParams(p_assigned_by: id.uuidString, p_assigned_to: personnelID.uuidString, p_vehicle_id: vehicleID, p_task_type: type.rawValue, p_note: issueNote)
        
        return try await client
            .rpc("assign_new_maintenance_task", params: params)
            .execute().value
    }
    
    func getManagerAssignedMaintenanceTasks(by id: UUID) async throws -> [MaintenanceTask] {
        struct MaintenanceTaskResponse: Codable {
            let id: UUID
            let type: MaintenanceTaskType
            let status: MaintenanceStatus
            let taskID: Int
            let expenses: [String: Double]?
            let createdAt: Date
            let issueNote: String
            let vehicleID: Int
            let assignedBy: UUID
            let assignedTo: UUID
            let repairNote: String
            let completionDate: String?
            let estimatedCompletionDate: String?
            
            private static let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd" // Supabase date format for DATE fields
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }()

            // Convert completionDate string (YYYY-MM-DD) to Date
            var parsedCompletionDate: Date? {
                guard let completionDate else { return nil }
                return Self.dateFormatter.date(from: completionDate)
            }
            
            var parsedEstimatedCompletionDate: Date? {
                guard let estimatedCompletionDate else { return nil }
                return Self.dateFormatter.date(from: estimatedCompletionDate)
            }
            
            var parsedExpenses: [MaintenanceExpenseType: Double]? {
                if let expenses {
                    return Dictionary(uniqueKeysWithValues: expenses.compactMap { key, value in
                        MaintenanceExpenseType(rawValue: key).map { ($0, value) }
                    })
                } else { return nil }
            }
        }
        
        let response: [MaintenanceTaskResponse] = try await client
            .rpc("get_maintenance_task_by_manager_id", params: ["p_id": id.uuidString])
            .execute().value
        
        var tasks: [MaintenanceTask] = []
        
        response.forEach({ task in
            tasks.append(MaintenanceTask(
                id: task.id,
                taskID: task.taskID,
                vehicleID: task.vehicleID,
                assignedTo: task.assignedTo, assignedBy: task.assignedBy,
                type: task.type, status: task.status,
                estimatedCompletionDate: task.parsedEstimatedCompletionDate,
                createdAt: task.createdAt,
                issueNote: task.issueNote, repairNote: task.repairNote,
                expenses: task.parsedExpenses,
                completionDate: task.parsedCompletionDate
            ))
        })
        
        return tasks;
    }
    
    func getMaintenancePersonnelTasks(by id: UUID) async throws -> [MaintenanceTask] {
        struct MaintenanceTaskResponse: Codable {
            let id: UUID
            let type: MaintenanceTaskType
            let status: MaintenanceStatus
            let taskID: Int
            let expenses: [String: Double]?
            let createdAt: Date
            let issueNote: String
            let vehicleID: Int
            let assignedBy: UUID
            let assignedTo: UUID
            let repairNote: String
            let completionDate: String?
            let estimatedCompletionDate: String?
            
            private static let dateFormatter: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd" // Supabase date format for DATE fields
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                return formatter
            }()

            // Convert completionDate string (YYYY-MM-DD) to Date
            var parsedCompletionDate: Date? {
                guard let completionDate else { return nil }
                return Self.dateFormatter.date(from: completionDate)
            }
            
            var parsedEstimatedCompletionDate: Date? {
                guard let estimatedCompletionDate else { return nil }
                return Self.dateFormatter.date(from: estimatedCompletionDate)
            }
            
            var parsedExpenses: [MaintenanceExpenseType: Double]? {
                if let expenses {
                    return Dictionary(uniqueKeysWithValues: expenses.compactMap { key, value in
                        MaintenanceExpenseType(rawValue: key).map { ($0, value) }
                    })
                } else { return nil }
            }
        }
        
        let response: [MaintenanceTaskResponse] = try await client
            .rpc("get_maintenance_task_by_maintenance_personnel_id", params: ["p_id": id.uuidString])
            .execute().value
        
        var tasks: [MaintenanceTask] = []
        
        response.forEach({ task in
            tasks.append(MaintenanceTask(
                id: task.id,
                taskID: task.taskID,
                vehicleID: task.vehicleID,
                assignedTo: task.assignedTo, assignedBy: task.assignedBy,
                type: task.type, status: task.status,
                estimatedCompletionDate: task.parsedEstimatedCompletionDate,
                createdAt: task.createdAt,
                issueNote: task.issueNote, repairNote: task.repairNote,
                expenses: task.parsedExpenses,
                completionDate: task.parsedCompletionDate
            ))
        })
        
        return tasks;
    }
    
    func makeMaintenanceTaskInProgress(by id: UUID) async throws {
        struct UpdateMaintenanceTaskStatusParams: Codable {
            let p_id: String
            let p_new_status: MaintenanceStatus
        }
        
        let params = UpdateMaintenanceTaskStatusParams(p_id: id.uuidString, p_new_status: .inProgress)
        
        try await client
            .rpc("update_maintenance_task_status_by_id", params: params)
            .execute()
    }
    
    func updateMaintenanceTaskEstimatedDate(by id: UUID, _ date: Date) async throws {
        struct UpdateMaintenanceTaskEstimatedDateParams: Codable {
            let p_id: String
            let p_date: String
        }
        
        let params = UpdateMaintenanceTaskEstimatedDateParams(p_id: id.uuidString, p_date: ISO8601DateFormatter().string(from: date))
        
        try await client
            .rpc("add_estimated_completion_date_for_maintenance_task_id", params: params)
            .execute().value
    }
    
    func createInvoiceForMaintenanceTask(by id: UUID, expenses: [MaintenanceExpenseType : Double], _ repairNote: String) async throws {
        struct CreateInvoiceParams: Codable {
            let p_id: String
            let p_expenses: [String : Double]
            let p_note: String
        }
        
        let expensesDictionary = Dictionary(uniqueKeysWithValues: expenses.map { ($0.rawValue, $1) })
        
        let params = CreateInvoiceParams(p_id: id.uuidString, p_expenses: expensesDictionary, p_note: repairNote)
        
        try await client
            .rpc("create_invoice_for_maintenance_task_id", params: params)
            .execute().value
    }
    
    func addNewMaintenancePersonnelMetaData(by id: UUID, phoneNumber: String, fullName: String, employeeID: Int, serviceCenterID: Int) async throws -> MaintenancePersonnel {
        struct AddDriverParams: Encodable {
            let p_id: UUID
            let p_phone: String
            let p_display_name: String
            let p_employee_id: Int
            let p_created_at: String
            let p_service_center_id: Int
        }
        
        let params = AddDriverParams(p_id: id, p_phone: phoneNumber, p_display_name: fullName,
                                     p_employee_id: employeeID,
                                     p_created_at: ISO8601DateFormatter().string(from: .now),
                                     p_service_center_id: serviceCenterID)
        
        let personnel: MaintenancePersonnel = try await client
            .rpc("add_new_maintenance_personnel", params: params).execute().value
        
        return personnel
    }
    
    func getRegisteredMaintenancePersonnels() async throws -> [MaintenancePersonnel] {
        return try await client
            .rpc("get_registered_maintenance_personnels").execute().value
    }
    
    func getRegisteredMaintenancePersonnel(by id: UUID) async throws -> MaintenancePersonnel {
        return try await client
            .rpc("get_maintenance_personnel_data_by_id", params: ["p_id": id.uuidString])
            .execute().value
    }
    
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
        struct TripInspectionResponse: Codable {
            let id: UUID
            let preInspection: [String: Bool]
            let postInspection: [String: Bool]
            let preInspectionNote: String
            let postInspectionNote: String
        }
        
        let inspection: TripInspectionResponse = try await client
            .rpc("get_trip_inspection_for_trip_id", params: ["p_id": id.uuidString])
            .execute().value
        
        let preInspection = Dictionary(uniqueKeysWithValues: inspection.preInspection.compactMap { key, value in
            TripInspectionItem(rawValue: key).map { ($0, value) }
        })

        
        let postInspection = Dictionary(uniqueKeysWithValues: inspection.postInspection.compactMap { key, value in
            TripInspectionItem(rawValue: key).map { ($0, value) }
        })
        

        return TripInspection(
            id: inspection.id,
            preInspection: preInspection,
            postInspection: postInspection,
            preInspectionNote: inspection.preInspectionNote,
            postInspectionNote: inspection.postInspectionNote
        )
    }
    
    func addPreTripInspectionForTrip(by id: UUID, inspection: [TripInspectionItem : Bool], note: String) async throws {
        struct PreInspectionParams: Codable {
            let p_id: String
            let p_pre_trip_inspection: [String: Bool]
            let p_note: String
        }
        
        let inspectionDictionary = Dictionary(uniqueKeysWithValues: inspection.map { ($0.rawValue, $1) })

        
        let params = PreInspectionParams(p_id: id.uuidString, p_pre_trip_inspection: inspectionDictionary, p_note: note)
        

        try await client
            .rpc("add_pre_trip_inspection_for_trip_id", params: params)
            .execute()
    }
    
    func addPostTripInspectionForTrip(by id: UUID, inspection: [TripInspectionItem : Bool], note: String) async throws {
        struct PostInspectionParams: Codable {
            let p_id: String
            let p_post_trip_inspection: [String: Bool]
            let p_note: String
        }
        
        let inspectionDictionary = Dictionary(uniqueKeysWithValues: inspection.map { ($0.rawValue, $1) })

        
        let params = PostInspectionParams(p_id: id.uuidString, p_post_trip_inspection: inspectionDictionary, p_note: note)
        

        try await client
            .rpc("add_post_trip_inspection_for_trip_id", params: params)
            .execute()
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
    
    func createNewMaintenancePersonnel(_ email: String, password: String) async throws -> UUID {
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
                .rpc("get_registered_vehicles")
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
