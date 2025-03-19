//
//  DriverDataModel.swift
//  Fleet Management System
//
//  Created by Rohit Raj on 19/03/25.
//

import Foundation

struct Driver: Identifiable, Codable  {
    let id: UUID
    let driverID: Int
    var fullName: String
    let email: String
    var phoneNumber: String
    let licenseNumber: String
}

struct Vehicle: Identifiable, Codable  {
    let id: UUID
    let vehicleID: Int
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
    var currentLocation: String
}


enum FuelType: String, Codable {
    case diesel = "Diesel"
    case petrol = "Petrol"
}
