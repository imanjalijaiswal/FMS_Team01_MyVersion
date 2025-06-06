//
//  DriverDataModel.swift
//  Fleet Management System
//
//  Created by Kavyansh Pratap Singh on 19/03/25.
//

import Foundation

//struct Driver: Identifiable, Codable  {
//    let id: UUID
//    let driverID: Int
//    var fullName: String
//    let email: String
//    var phoneNumber: String
//    let licenseNumber: String
//}

enum FuelType: String, Codable {
    case diesel = "Diesel"
    case petrol = "Petrol"
    case electric = "Electric"
    case hybrid = "Hybrid"
}

enum VehicleStatus: String, Codable {
    case available = "Available"
    case assigned = "Assigned"
    case underMaintenance = "Under Maintenance"
    case inactive = "Inactive"
}

struct Vehicle: Identifiable, Codable, Equatable{
    var id: Int
    let make: String //company name
    let model: String
    let vinNumber: String
    let licenseNumber: String
    let fuelType: FuelType
    let loadCapacity: Float
    let insurancePolicyNumber: String
    var insuranceExpiryDate: Date
    let pucCertificateNumber: String
    var pucExpiryDate: Date
    let rcNumber: String
    var rcExpiryDate: Date
    var currentCoordinate: String
    var status: VehicleStatus
    var activeStatus: Bool
}

struct ServiceCenter: Identifiable, Codable, Equatable {
    var id: Int
    var coordinate: String
    var isAssigned: Bool
}
