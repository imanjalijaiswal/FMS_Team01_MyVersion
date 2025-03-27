//
//  Users.swift
//  Fleet Management System
//
//  Created by Abcom on 27/03/25.
//

import Foundation

protocol User: Codable, Equatable, Identifiable {
    var meta_data: UserMetaData { get set }
    
    var id: UUID { get }
    
    var activeStatus: Bool { get }
    var employeeID: Int { get }
    var role: Role { get }
}

struct UserMetaData: Codable, Equatable, Identifiable {
    var id: UUID
    var fullName: String
    var email: String
    var phone: String
    var role: Role
    var employeeID: Int
    var firstTimeLogin: Bool
    var createdAt: Date
    var activeStatus: Bool
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}

struct FleetManager: User {
    var activeStatus: Bool { return meta_data.activeStatus }
    
    var employeeID: Int { return meta_data.employeeID }
    
    var role: Role { return meta_data.role }
    
    var meta_data: UserMetaData
    var id: UUID { meta_data.id }
}

struct Driver: User {
    var activeStatus: Bool { return meta_data.activeStatus }
    
    var employeeID: Int { return meta_data.employeeID }
    
    var role: Role { return meta_data.role }
    
    var meta_data: UserMetaData
    var licenseNumber: String
    var totalTrips: Int
    var status: DriverStatus
    
    var id: UUID { meta_data.id }
}

struct MaintenancePersonnel: User {
    var meta_data: UserMetaData
    var totalRepairs: Int
    
    var id: UUID { meta_data.id }
    
    var activeStatus: Bool { meta_data.activeStatus }
    
    var employeeID: Int { meta_data.employeeID }
    
    var role: Role { meta_data.role }
}

struct AppUser: Codable, Equatable, Identifiable {
    var userData: UserSpecificData

    enum UserSpecificData: Codable, Equatable {
        case driver(Driver)
        case fleetManager(FleetManager)
        case maintenancePersonnel(MaintenancePersonnel)

        enum CodingKeys: String, CodingKey {
            case type, data
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .driver(let driver):
                try container.encode("driver", forKey: .type)
                try container.encode(driver, forKey: .data)
            case .fleetManager(let manager):
                try container.encode("fleetManager", forKey: .type)
                try container.encode(manager, forKey: .data)
            case .maintenancePersonnel(let personnel):
                try container.encode("maintenancePersonnel", forKey: .type)
                try container.encode(personnel, forKey: .data)
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)

            switch type {
            case "driver":
                let driver = try container.decode(Driver.self, forKey: .data)
                self = .driver(driver)
            case "fleetManager":
                let manager = try container.decode(FleetManager.self, forKey: .data)
                self = .fleetManager(manager)
            case "maintenancePersonnel":
                let personnel = try container.decode(MaintenancePersonnel.self, forKey: .data)
                self = .maintenancePersonnel(personnel)
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid role type")
            }
        }
    }

    var meta_data: UserMetaData {
        switch userData {
        case .driver(let driver):
            return driver.meta_data
        case .fleetManager(let fleetManager):
            return fleetManager.meta_data
        case .maintenancePersonnel(let personnel):
            return personnel.meta_data
        }
    }
    
    var role: Role { return meta_data.role }
    
    var licenseNumber: String? {
        switch userData {
        case .driver(let driver):
            return driver.licenseNumber
        default: return nil
        }
    }
    
    var totalTrips: Int? {
        switch userData {
        case .driver(let driver):
            return driver.totalTrips
        default: return nil
        }
    }
    
    var driverStatus: DriverStatus? {
        switch userData {
        case .driver(let driver):
            return driver.status
        default: return nil
        }
    }
    
    var id: UUID {  return meta_data.id }
    
    var activeStatus: Bool { return meta_data.activeStatus }
    
    var employeeID: Int { return meta_data.employeeID }
}

enum Role: String, Codable {
    case fleetManager = "fleetManager"
    case driver = "driver"
    case maintenancePersonnel = "maintenancePersonnel"
}
