//
//  ActiveTripSkeletonView.swift
//  Fleet Management System
//
//  Created by Arnav Chauhan on 10/04/25.
//

import SwiftUI

// Active Trip section skeleton
struct ActiveTripSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Trip ID and vehicle info
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        // Trip ID text
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 140, height: 18)
                            .cornerRadius(4)
                            .applyShimmer()
                        
                        Spacer()
                        
                        // Chevron icon placeholder
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 14, height: 18)
                            .cornerRadius(4)
                            .applyShimmer()
                    }
                    
                    HStack(spacing: 8) {
                        // Vehicle info
                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 150, height: 14)
                                .cornerRadius(4)
                                .applyShimmer()
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 100, height: 14)
                                .cornerRadius(4)
                                .applyShimmer()
                        }
                        
                        Spacer()
                        
                        // Status badge
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 90, height: 24)
                            .cornerRadius(12)
                            .applyShimmer()
                    }
                }
            }
            
            // Middle section - date and description
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(height: 16)
                .cornerRadius(4)
                .applyShimmer()
            
            Divider()
                .background(Color.gray.opacity(0.4))
            
            // Location details
            VStack(alignment: .leading, spacing: 12) {
                // Pickup location
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 12, height: 12)
                        .applyShimmer()
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 70, height: 12)
                            .cornerRadius(3)
                            .applyShimmer()
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 250, height: 16)
                            .cornerRadius(4)
                            .applyShimmer()
                    }
                }
                .padding(.vertical, 2)
                
                // Destination location
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 12, height: 12)
                        .applyShimmer()
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 80, height: 12)
                            .cornerRadius(3)
                            .applyShimmer()
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 250, height: 16)
                            .cornerRadius(4)
                            .applyShimmer()
                    }
                }
                .padding(.vertical, 2)
            }
            
            // Distance and time
            HStack(spacing: 10) {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 16, height: 16)
                    .cornerRadius(4)
                    .applyShimmer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 70, height: 14)
                    .cornerRadius(3)
                    .applyShimmer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 16, height: 16)
                    .cornerRadius(4)
                    .applyShimmer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 80, height: 14)
                    .cornerRadius(3)
                    .applyShimmer()
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// Alternative Active Trip section skeleton for "No Active Trip" state
struct NoActiveTripSkeletonView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            // Truck icon placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 70, height: 70)
                .cornerRadius(8)
                .applyShimmer()
            
            // "No Active Trip" text placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 140, height: 22)
                .cornerRadius(4)
                .applyShimmer()
            
            // Description text placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 280, height: 16)
                .cornerRadius(4)
                .applyShimmer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        ActiveTripSkeletonView()
        NoActiveTripSkeletonView()
    }
} 
