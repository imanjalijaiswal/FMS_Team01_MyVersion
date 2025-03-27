//
//  TripDataModel.swift
//  Fleet Management System
//
//  Created by Kavyansh Pratap Singh on 19/03/25.
//


import Foundation

/*
 TripInspection table
 (id: UUID PK, tripUID: UUID FK, preInspection: JSONB, postInspection: JSONB, notes: TEXT)
 */

struct Trip: Identifiable, Codable {
    var id: UUID
    var tripID: Int
//    var tripInspectionUID: UUID
    
    var assignedByFleetManagerID: UUID      //initialize automatidally when fleet manager assignns the trip
    var assignedDriverIDs: [UUID]
    //var assigneVehicleID: Int
    var assignedVehicleID: Int

    var pickupLocation: String
    var destination: String
    var estimatedArrivalDateTime: Date      // Estimated time at which delivery will be completed.
    var totalDistance: Int
    var totalTripDuration: Date
    var description: String?
    var scheduledDateTime: Date
    var createdAt: Date
    var status: TripStatus
}



enum TripStatus: String, Codable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
}

struct TripInspection: Codable, Equatable, Identifiable {
    var id: UUID // This is trip id
    var preInspection: [TripInspectionItem: Bool]
    var postInspection: [TripInspectionItem: Bool]
    var preInspectionNote: String
    var postInspectionNote: String
}

enum TripInspectionItem: String, Codable, CaseIterable{
    case tireCondition = "Tire Condition"
    case brakeSystem = "Brake System"
    case lights = "Lights"
    case fluidLevels = "Fluid Levels"
    case tirePressure = "Tire Pressure"
    case coolingSystem = "Cooling System"
    case mirrors = "Mirrors"
    case batteryHealth = "Battery Health"
    case seatBelts = "Seat Belts"
    case airbags = "Airbags"
    case emergencyKit = "Emergency Kit"
}

