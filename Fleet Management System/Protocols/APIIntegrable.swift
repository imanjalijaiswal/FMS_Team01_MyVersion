//
//  ServerControllerProtocol.swift
//  Fleet Management System
//
//  Created by Abcom on 20/03/25.
//

import Foundation

protocol DatabaseAPIIntegrable {
    //MARK: User APIs
    func getUserProfile(with email: String, _ password: String) -> UserRoles
    
    func getDriverProfile(by userRole: UserRoles) -> Driver
    
    func getManagerProfile(by userRole: UserRoles) -> FleetManager
    
    func getUsers(ofType type: Role) -> [UserRoles]
    
    func getRegisteredDrivers(by userRoles: [UserRoles]) -> [Driver]
}
