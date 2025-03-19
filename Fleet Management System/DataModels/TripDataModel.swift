//
//  TripDataModel.swift
//  Fleet Management System
//
//  Created by Rohit Raj on 19/03/25.
//


import Foundation

struct Trip: Identifiable, Codable {
    var id: UUID
    var tripID: Int
    
    var assignedByFleetManagerID: UUID      //initialize automatidally when fleet manager assignns the trip
    var assignedDriverIDs: [UUID]
    var assigneVehicleID: UUID
    var pickupLocation: String
    var destination: String
    var estimatedArrivalDateTime: Date      // Estimated time at which delivery will be completed.

    var description: String?
    
    /// For future version
//    var actualArrivalDateTime: Date         // Actual time at which delivery is completed.
//    var fuelConsumed: Double?
//    var distanceTraveled: Double?
//    var completedAt: Date   //initialize automatically when ending a trip.
//    var startedAt: Date     //initialize automatically when starting a trip.
    
    var createdAt: Date = Date.now
    var status: TripStatus = .scheduled
}


enum TripStatus: String, Codable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
}
