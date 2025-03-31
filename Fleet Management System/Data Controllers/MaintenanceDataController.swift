////
////  MaintenanceDataController.swift
////  Fleet Management System
////
////  Created by Vivek kumar on 28/03/25.
////
//
//import Foundation
//import Combine
//
//// MARK: - Data Controller for Maintenance Task Management
//class MaintenanceDataController: ObservableObject {
//    static let shared = MaintenanceDataController()
//    private init() {}
//
//    @Published var tasks: [MaintenanceTask] = []
//
//    // Get first available assigned or in-progress task
//    var currentTask: MaintenanceTask? {
//        return tasks.first { $0.status == .scheduled || $0.status == .inProgress }
//    }
//
//    // MARK: - Update Task
//    func updateMaintenanceTask(_ task: MaintenanceTask) {
//        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
//            tasks[index] = task
//            print("Task updated successfully: \(task)")
//        } else {
//            print("Task not found!")
//        }
//    }
//
//    // MARK: - Start a Task
//    func startTask(task: inout MaintenanceTask) {
//        guard task.status == .scheduled else { return }
//        task.status = .inProgress
//        task.estimatedCompletionDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
//    }
//
//    // MARK: - Complete a Task
//    func completeTask(task: inout MaintenanceTask) {
//        guard task.status == .inProgress else { return }
//        task.status = .completed
//        task.completionDate = Date()
//    }
//
//    // MARK: - Calculate Total Cost
//    func calculateTotalCost(for task: inout MaintenanceTask) -> Double {
//        let partsCostTotal = task.expenses?[.partsCost] ?? 0
//        let laborCostTotal = task.expenses?[.laborsCost] ?? 0
//        let otherCostTotal = task.expenses?[.otherCost] ?? 0
//
//        let totalCost = partsCostTotal + laborCostTotal + otherCostTotal
//        print("Total Maintenance Cost: $\(totalCost)")
//        return totalCost
//    }
//
//    // MARK: - Generate Invoice
//    func generateInvoice(for task: MaintenanceTask) async -> Invoice? {
//        guard task.status == .completed, let completionDate = task.completionDate, let expenses = task.expenses else {
//            print("Cannot generate invoice for an incomplete task.")
//            return nil
//        }
//
//        if let vehicleLicenseNumber = await IFEDataController.shared.getRegisteredVehicle(by: task.vehicleID)?.licenseNumber {
//            let invoice = Invoice(
//                id: task.id,
//                taskID: task.taskID,
//                expenses: expenses,
//                issueNote: task.issueNote,
//                repairNote: task.repairNote,
//                createdAt: task.createdAt,
//                completionDate: completionDate,
//                vehicleID: task.vehicleID,
//                vehicleLicenseNumber: vehicleLicenseNumber,
//                type: task.type
//            )
//            return invoice
//        } else {
//            print("Error retrieving vehicle details for invoice.")
//            return nil
//        }
//    }
//}
