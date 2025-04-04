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
    case sos = "SOS"
    case completed = "Completed"
}

struct TripInspection: Codable, Equatable, Identifiable {
    var id: UUID // This is trip id
    var preInspection: [TripInspectionItem: Bool]
    var postInspection: [TripInspectionItem: Bool]
    var preInspectionNote: String
    var postInspectionNote: String
    
    static var issueDescription: [TripInspectionItem: String] {
        let description: [TripInspectionItem: String] = [
            .tireCondition: "Tires are worn out or damaged.",
            .brakeSystem: "Brakes are not functioning properly or have reduced efficiency.",
            .lights: "Lights are dim, flickering, or not functioning.",
            .fluidLevels: "Fluid levels are insufficient or inconsistent.",
            .tirePressure: "Pressure is not optimal or uneven among tires.",
            .coolingSystem: "Cooling system is not maintaining optimal temperature.",
            .mirrors: "Mirrors are damaged or not adjustable.",
            .batteryHealth: "Battery is weak or not holding charge.",
            .seatBelts: "Seat belts are faulty or not locking properly.",
            .airbags: "Airbags are not deploying correctly or show malfunction.",
            .emergencyKit: "Emergency kit is incomplete or missing essential items."
        ]
        
        return description
    }
    
    func getPreInspectionFailureDetails() -> String {
        let failedItems = preInspection.filter { !$0.value }
            .map { $0.key }
        
        let formatedItems = failedItems.enumerated()
            .map { "\($0.offset + 1). \($0.element.rawValue) - \(TripInspection.issueDescription[$0.element] ?? "Issue detected.")" }
            .joined(separator: "\n")
        
        let details = """
        Issues detected during pre-inspection:
        \(formatedItems)
        
        Note:
        \(preInspectionNote)
        """
        
        return details
    }
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

