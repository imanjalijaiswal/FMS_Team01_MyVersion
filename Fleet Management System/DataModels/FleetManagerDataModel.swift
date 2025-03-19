//
//  FleetManagerDataModel.swift
//  Fleet Management System
//
//  Created by Rohit Raj on 19/03/25.
//

import Foundation

struct FleetManagerDataModel : Identifiable, Codable{
    let id: UUID
    let managerID: Int
    let fullName: String
    let email: String
    let phoneNumber: String
}
