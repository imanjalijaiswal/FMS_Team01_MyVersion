//
//  DataController.swift
//  Fleet Management System
//
//  Created by Aakash Singh on 23/03/25.
//
import SwiftUI
import CoreLocation
class IFEDataController: ObservableObject {
    static let shared = IFEDataController() // Singleton instance
    
    @Published var drivers: [Driver] = []
    @Published var vehicles: [Vehicle] = []
    @Published var trips: [Trip] = []
    let remoteController = RemoteController.shared
    
    init() {
        Task { @MainActor in
            await loadDrivers()
            await loadVehicles()
        }
    }
    
    @MainActor
    private func loadDrivers() async {
        do {
            drivers = try await remoteController.getRegisteredDrivers()
        } catch {
            print("Error while fetching registered drivers: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func loadVehicles() async {
        do {
            vehicles = try await remoteController.getRegisteredVehicles()
        } catch {
            print("Error while fetching registered vehicles: \(error.localizedDescription)")
        }
    }
    

    func addDriver(_ driver: Driver, password: String) async {
        do {
            let new_driver_uid = try await remoteController.createNewDriver(driver.meta_data.email, password: password)
            let employeeID = try await remoteController.getMaxEmployeeID(ofType: .driver)
            
//            print("New Driver ID: \(new_driver_uid)")
//            print("EployeeID: \(employeeID + 1)")
            
            let newDriver = try await remoteController.addNewDriverMetaData(by: new_driver_uid, phoneNumber: driver.meta_data.phone, fullName: driver.meta_data.fullName, employeeID: employeeID+1, licenseNumber: driver.licenseNumber)
            DispatchQueue.main.async {
                self.drivers.append(newDriver)
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func removeDriver(_ driver: Driver) {
        Task {
            do {
                var inactiveDriver = driver
                inactiveDriver.meta_data.activeStatus = false
                try await remoteController.updateUserActiveStatus(by: driver.id, with: false)
                DispatchQueue.main.async {
                    self.drivers.removeAll { $0 == driver }
                    self.drivers.append(inactiveDriver)
                }
            } catch {
                print("Error while removing the driver: \(error.localizedDescription)")
            }
        }
    }
    
    func enableDriver(_ driver: Driver) {
        Task {
            do {
                var activeDriver = driver
                activeDriver.meta_data.activeStatus = true
                try await remoteController.updateUserActiveStatus(by: driver.id, with: true)
                drivers.removeAll { $0 == driver }
                drivers.append(activeDriver)
            } catch {
                print("Error while enabling the driver: \(error.localizedDescription)")
            }
        }
    }
    
    func updateTripStatus(_ trip: Trip, to newStatus: TripStatus) {
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].status = newStatus
        }
    }
    
    func addVehicle(_ vehicle: Vehicle) {
        Task {
            do {
                var newVehicle = vehicle
                newVehicle.id = try await remoteController.addNewVehicle(vehicle)
                DispatchQueue.main.async {
                    self.vehicles.append(newVehicle)
                }
            } catch {
                print("Error while adding new vehicle: \(error.localizedDescription)")
            }
        }
    }
    
    func removeVehicle(_ vehicle: Vehicle) {
        Task{
            do {
                var inactiveVehicle = vehicle
                inactiveVehicle.activeStatus = false
//                inactiveVehicle.status = .inactive
                try await remoteController.updateVehicleActiveStatus(by: vehicle.id, with: false)
                vehicles.removeAll { $0.id == vehicle.id }
                vehicles.append(inactiveVehicle)
            } catch {
                print("Error while removing the vehicle: \(error.localizedDescription)")
            }
        }
    }
    
    func enableVehicle(_ vehicle: Vehicle) {
        Task{
            do {
                var inactiveVehicle = vehicle
                inactiveVehicle.activeStatus = true
                inactiveVehicle.status = .available
                try await remoteController.updateVehicleActiveStatus(by: vehicle.id, with: true)
                vehicles.removeAll { $0.id == vehicle.id }
                vehicles.append(inactiveVehicle)
            } catch {
                print("Error while activating the vehicle: \(error.localizedDescription)")
            }
        }
    }
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        // Update driver status to onTrip
        for driverId in trip.assignedDriverIDs {
            if let index = drivers.firstIndex(where: { $0.id == driverId }) {
                var driver = drivers[index]
//                driver.totalTrips += 1
                driver.status = .onTrip
                drivers[index] = driver
            }
        }
        // Update vehicle status to inUse
        if let index = vehicles.firstIndex(where: { $0.id == trip.assigneVehicleID }) {
            var vehicle = vehicles[index]
            vehicle.status = .assigned
            vehicles[index] = vehicle
        }
    }
    
    func getFilteredTrips(status: TripStatus?) -> [Trip] {
        if let status = status {
            return trips.filter { $0.status == status }
        }
        return trips
    }
    
    func sendWelcomeEmail(to email: String, password: String) {
        print("Sending welcome email to: \(email)")
        print("Email content: Welcome to Fleet Management System!")
        print("Your login credentials are:")
        print("Email: \(email)")
        print("Password: \(password)")
    }
    
    func updateDriverPhone(_ driver: Driver,with phone: String) {
        Task {
            do {
                var updatedDriver = driver
                updatedDriver.meta_data.phone = phone
                try await remoteController.updateUserPhone(by: driver.id, phone)
                drivers.removeAll { $0 == driver }
                drivers.append(updatedDriver)
            } catch {
                print("Error while updating the driver phone: \(error.localizedDescription)")
            }
        }
    }
    
    func updateVehicleExpiryDates(_ vehicle: Vehicle, with newVehicle: Vehicle) {
        Task {
            do {
                try await remoteController.updateVehicleExpiry(by: vehicle.id, with: (
                    puc: newVehicle.pucExpiryDate,
                    insurance: newVehicle.insuranceExpiryDate,
                    registration: newVehicle.rcExpiryDate
                ))
                vehicles.removeAll { $0 == vehicle }
                vehicles.append(newVehicle)
            } catch {
                print("Error while updating the vehicle: \(error.localizedDescription)")
            }
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

    let location = CLLocation(latitude: latitude, longitude: longitude)
    let geocoder = CLGeocoder()
    
    geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
        if let error = error {
            print("Reverse geocoding failed: \(error.localizedDescription)")
            completion(nil)
            return
        }

        if let placemark = placemarks?.first {
            let address = [
                placemark.name,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")

            completion(address)
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
