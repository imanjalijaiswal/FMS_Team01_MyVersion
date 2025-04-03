//
//  Extensions.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 19/03/25.
//

import Foundation
import SwiftUICore
import CoreLocation
import MapKit

struct IFEPushNotification: Codable, Identifiable, Equatable, CustomStringConvertible {
    var description: String {
        return """
        IFE Push Notification:
        Title: \(title)
        Message: \(message)
        Sent At: \(sentAt.description)
        """
    }
    
    var id: UUID
    var senderID: UUID
    var recipientID: UUID
    var title: String
    var message: String
    var sentAt: Date
}

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

func getAddress(from coordinate: String, completion: @escaping (String?) -> Void) {
    let components = coordinate.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    
    guard components.count == 2,
          let latitude = Double(components[0]),
          let longitude = Double(components[1]) else {
        print("Invalid coordinate format")
        completion(nil)
        return
    }

    let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    let searchRequest = MKLocalSearch.Request()
    searchRequest.naturalLanguageQuery = "\(latitude), \(longitude)"
    searchRequest.resultTypes = [.pointOfInterest, .address]
    searchRequest.region = MKCoordinateRegion(
        center: location,
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    let search = MKLocalSearch(request: searchRequest)
    search.start { response, error in
        if let error = error {
            print("Search failed: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        if let items = response?.mapItems {
            // Try to find the most relevant result
            if let poi = items.first(where: { $0.pointOfInterestCategory != nil }) {
                // If we found a point of interest, use its full address
                let address = [
                    poi.name,
                    poi.placemark.thoroughfare,
                    poi.placemark.locality,
                    poi.placemark.administrativeArea,
                    poi.placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                completion(address)
            } else if let firstItem = items.first {
                // If no POI, use the first result's full address
                let address = [
                    firstItem.name,
                    firstItem.placemark.thoroughfare,
                    firstItem.placemark.locality,
                    firstItem.placemark.administrativeArea,
                    firstItem.placemark.country
                ].compactMap { $0 }.joined(separator: ", ")
                completion(address)
            } else {
                // Fallback to reverse geocoding
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: latitude, longitude: longitude)
                
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    if let error = error {
                        print("Reverse geocoding failed: \(error.localizedDescription)")
                        completion(nil)
                        return
                    }

                    if let placemark = placemarks?.first {
                        let address = [
                            placemark.name,
                            placemark.thoroughfare,
                            placemark.locality,
                            placemark.administrativeArea,
                            placemark.country
                        ].compactMap { $0 }.joined(separator: ", ")
                        
                        completion(address.isEmpty ? nil : address)
                    } else {
                        completion(nil)
                    }
                }
            }
        } else {
            completion(nil)
        }
    }
}

func getCoordinates(from address: String) async -> String? {
    let geocoder = CLGeocoder()
    do {
        let placemarks = try await geocoder.geocodeAddressString(address)
        if let location = placemarks.first?.location {
            return "\(location.coordinate.latitude), \(location.coordinate.longitude)"
        }
    } catch {
        print("Geocoding failed: \(error.localizedDescription)")
    }
    return nil
}

func estimatedDate(from startDate: Date, hours: Float) -> Date {
    let secondsToAdd = Int(hours * 3600)// Convert hours to seconds
    return Calendar.current.date(byAdding: .second, value: secondsToAdd, to: startDate) ?? startDate
}
