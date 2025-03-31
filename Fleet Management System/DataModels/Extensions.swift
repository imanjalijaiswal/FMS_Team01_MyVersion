//
//  Extensions.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 19/03/25.
//

import Foundation
import SwiftUICore
extension Color {
    static let primaryGradientStart = Color(red: 0/255, green: 128/255, blue: 128/255)
    static let primaryGradientEnd = Color(red: 0/255, green: 105/255, blue: 105/255)
    static let primaryGradientStart1 = Color(red: 247/255, green: 242/255, blue: 236/255)
    static let statusGreen = Color(red: 76/255, green: 187/255, blue: 23/255)
    static let statusOrange = Color(red: 245/255, green: 166/255, blue: 35/255)
    static let cardBackground = Color(red: 248/255, green: 248/255, blue: 248/255)
    static let textPrimary = Color(red: 51/255, green: 51/255, blue: 51/255)
    static let textSecondary = Color(red: 119/255, green: 119/255, blue: 119/255)
    static let statusRed = Color.primaryGradientStart

    
    
    static let tealGreen = Color(red : 102/255, green : 204/255, blue : 153/255)
    static let backgroundTealGreen = Color(red : 83/255, green : 204/255, blue : 153/255)
    static let lightOrange = Color(red: 201/255, green: 181/255, blue: 169/255)
    static let orange = Color(red : 206/255,green: 143/255,blue: 113/255)
    static let darkOrange = Color(red: 212/255, green: 97/255, blue: 53/255)
    static let lightwhite = Color(red: 253/255, green: 253/255, blue: 253/255)
    static let lightWhiteGrey = Color(red: 228/255, green: 228/255, blue: 228/255)
    static let blackFont = Color(red: 24/255, green: 24/255, blue: 24/255)
    
    
    
    static func setColor(status : DriverStatus)->Color{
            switch status {
            case .available:
                return Color.primaryGradientStart
            case .onTrip:
                return Color.statusOrange
            default:
                return Color.blue
            }
        }
        static func foregroundColorForDriver(driver: Driver) -> Color {
            if driver.meta_data.firstTimeLogin {
                return .gray // Offline (firstTimeLogin)
            } else if !driver.activeStatus {
                return .red // Inactive (activeStatus)
            } else {
                return setColor(status: driver.status) // Status color
            }
        }
        static func setVechicleColor(status : VehicleStatus) -> Color{
            switch status{
            case .assigned :
                return Color.statusOrange
            case .available :
                return Color.primaryGradientStart
            case .inactive :
                return Color.red
            default:
                return Color.blue
            }
        }
        static func setForegroundColor(vehicle : Vehicle) -> Color{
            if !vehicle.activeStatus {
                return .red
            }else{
                return setVechicleColor(status : vehicle.status)
            }
        }
    static func setMaintaiencePersonalColor(status : MaintenanceStatus) -> Color{
        switch status{
        case .completed :
            return Color.primaryGradientStart
        case .inProgress :
            return Color.statusOrange
        case .scheduled :
            return Color.blue
        default:
            return Color.blue
        }
    }
    static func setMaintaienceColor(maintaiencePersonal: MaintenancePersonnel) -> Color {
        if !maintaiencePersonal.activeStatus {
            return .red
        } else if maintaiencePersonal.meta_data.firstTimeLogin {
            return .gray
        } else {
            return Color.primaryGradientStart
        }
    }
}
