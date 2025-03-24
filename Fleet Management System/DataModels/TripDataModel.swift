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


