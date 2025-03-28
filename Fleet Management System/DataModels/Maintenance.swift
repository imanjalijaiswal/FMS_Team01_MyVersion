//
//  Maintenance.swift
//  Fleet Management System
//
//  Created by Abcom on 27/03/25.
//

import Foundation

enum MaintenanceExpenseType: String, Codable {
    case laborsCost = "Labors Cost"
    case partsCost = "Parts Cost"
    case otherCost = "Other Cost"
}

enum MaintenanceTaskType: String, Codable {
    case regularMaintenance = "Regular Maintenance"
    case preInspectionMaintenance = "Pre-Inspection Maintenance"
    case postInspectionMaintenance = "Post-Inspection Maintenance"
    case emergencyMaintenance = "Emergency Maintenance"
}

enum MaintenanceStatus: String, Codable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
}

struct Invoice {
    static func == (lhs: Invoice, rhs: Invoice) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: UUID   // this id is same as maintenance task uuid
    var taskID: Int // this id is same as maintenance task id
    var expenses: [MaintenanceExpenseType: Double]
    var issueNote: String
    var repairNote: String
    var createdAt: Date
    var completionDate: Date
    var vehicleID: Int
    var vehicleLicenseNumber: String
    var type: MaintenanceTaskType
    
    var totalExpense: Double {
        expenses.values.reduce(0, +)
    }
}

struct MaintenanceTask: Codable, Identifiable, Equatable {
    var id: UUID
    var taskID: Int
    var vehicleID: Int
    
    var assignedTo: UUID
    var assignedBy: UUID    // Driver or Fleet Manager ID
    
    var type: MaintenanceTaskType
    var status: MaintenanceStatus
    
    // Estimated values
    var estimatedCompletionDate: Date? // given by maintenance personnel only date no time e.g "2025-03-31"
    var createdAt: Date
    var issueNote: String
    var repairNote: String
    var expenses: [MaintenanceExpenseType: Double]?

    var completionDate: Date? // only date no time e.g "2025-03-31"
    
    // Computed properties
    //MARK: TODO := REVIEW THIS FUNCITONALITY FOR WHERE AND WHY IT IS USING AND TELL ME
    var formattedDate: String? {
        guard let estimatedCompletionDate = self.estimatedCompletionDate else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: estimatedCompletionDate)
    }
    
    // MARK: - Equatable implementation
    static func == (lhs: MaintenanceTask, rhs: MaintenanceTask) -> Bool {
        return lhs.id == rhs.id
    }
    
    func generateInvoice() async -> Invoice? {
        guard let completionDate, let expenses, status == .completed else {
            print("Can't generate invoice for in progress maintenance.")
            return nil
        }
        
        if let vehicleLicenseNumber = await IFEDataController.shared
            .getRegisteredVehicle(by: self.vehicleID)?
            .licenseNumber {
            
            let invoice = Invoice(
                id: self.id, // this id is same as maintenance task uuid
                taskID: self.taskID, // this id is same as maintenance task id
                expenses: expenses,
                issueNote: self.issueNote,
                repairNote: self.repairNote,
                createdAt: self.createdAt,
                completionDate: completionDate,
                vehicleID: self.vehicleID,
                vehicleLicenseNumber: vehicleLicenseNumber,
                type: self.type
            )
            
            return invoice
        } else {
            print("Error while generating invoice.")
            return nil
        }
    }
}
