//
//  Fleet_Management_SystemApp.swift
//  Fleet Management System
//
//  Created by Aditya Mathur on 17/03/25.
//

import SwiftUI

@main
struct Fleet_Management_SystemApp: App {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // Set the selected tab color to teal
        UITabBar.appearance().tintColor = .systemTeal
        UINavigationBar.appearance().tintColor = UIColor(Color.primaryGradientStart)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    var body: some Scene {
        WindowGroup {
            SpashScreen()
        }
    }
}
