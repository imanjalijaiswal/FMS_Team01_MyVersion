//
//  DriverDashboardSkeletonView.swift
//  Fleet Management System
//
//  Created by Arnav Chauhan on 09/04/25.
//

import SwiftUI

// Driver Task Card Skeleton View
struct DriverTaskCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Trip ID and vehicle info
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        // Trip ID text
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 120, height: 16)
                            .cornerRadius(4)
                            .applyShimmer()
                        
                        Spacer()
                        
                        // Chevron icon placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 12, height: 16)
                            .cornerRadius(4)
                            .applyShimmer()
                    }
                    
                    HStack(spacing: 8) {
                        // Vehicle info
                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 150, height: 12)
                                .cornerRadius(4)
                                .applyShimmer()
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 100, height: 12)
                                .cornerRadius(4)
                                .applyShimmer()
                        }
                        
                        Spacer()
                        
                        // Status badge
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 80, height: 24)
                            .cornerRadius(8)
                            .applyShimmer()
                    }
                }
            }
            
            // Location details
            VStack(alignment: .leading, spacing: 8) {
                // From location
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 16, height: 16)
                        .applyShimmer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 200, height: 14)
                        .cornerRadius(4)
                        .applyShimmer()
                }
                
                // Vertical line between locations
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 2, height: 20)
                        .padding(.leading, 7)
                        .applyShimmer()
                    
                    Spacer()
                }
                
                // To location
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 16, height: 16)
                        .applyShimmer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 200, height: 14)
                        .cornerRadius(4)
                        .applyShimmer()
                }
            }
            .padding(.top, 4)
            
            // Date information
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.gray.opacity(0.4))
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 180, height: 14)
                    .cornerRadius(4)
                    .applyShimmer()
            }
            
            // Action button
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(height: 44)
                .cornerRadius(10)
                .applyShimmer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// Complete Driver Dashboard Skeleton View
struct DriverDashboardSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Add some top padding to match the actual view
                Spacer()
                    .frame(height: 8)
                
                // Active Trip Section
                VStack(alignment: .leading, spacing: 8) {
                    // Title - "Active Trip"
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.4))
                        .frame(width: 100,height: 20)
                        .cornerRadius(10)
                        .padding()
                    
                    // Use the ActiveTripSkeletonView
                    ActiveTripSkeletonView()
                }
                .padding(.vertical, 8)
                
                // My Trips Section Header
                Rectangle()
                    .foregroundColor(Color.gray.opacity(0.4))
                    .frame(width: 100,height: 20)
                    .cornerRadius(10)
                    .padding()
                
                // Task filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<2, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 100, height: 36)
                                .cornerRadius(20)
                                .applyShimmer()
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Task list
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        DriverTaskCardSkeletonView()
                            .shadow(radius: 2, x: 2, y: 2)
                    }
                }
                .padding()
            }
        }
        .background(Color(red: 242/255, green: 242/255, blue: 247/255))
    }
}

#Preview {
    NavigationView {
        DriverDashboardSkeletonView()
            .navigationTitle("Driver")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 35, height: 35)
                        .applyShimmer()
                }
            }
    }
} 
