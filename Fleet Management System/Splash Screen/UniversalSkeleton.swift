//
//  UniversalSkeleton.swift
//  Fleet Management System
//
//  Created by Arnav Chauhan on 03/04/25.
//

import SwiftUI

//
//  UniversalSkeletonView.swift
//  Fleet Management System
//
//  Created by Arnav Chauhan on 30/03/25.
//

import SwiftUI

struct CustomSegementedcontrolView : View{
    var width : CGFloat?
    var body: some View {
        HStack{
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: width,height: 30)
        }
    }
}

struct contentInsideView : View{
    var body: some View {
        VStack(alignment : .leading,spacing: 8){
            HStack(){
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 50, height: 50)
                
                VStack(){
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width : 100,height : 20)
                        .cornerRadius(12)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width : 100,height : 16)
                        .cornerRadius(12)
                }
                //.cornerRadius(12)
                Spacer()
                
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width : 80,height : 20)
                
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
                    }
        .padding(.vertical)
        }
    }


struct ContentInsideView : View{
    var body: some View {
        VStack(alignment : .leading,spacing: 8){
            HStack(){
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 50, height: 50)
                
                VStack(){
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width : 100,height : 20)
                        .cornerRadius(12)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width : 100,height : 16)
                        .cornerRadius(12)
                }
                //.cornerRadius(12)
                Spacer()
                
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width : 80,height : 20)
                
                
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
                    }
        .padding(.vertical)
        }
    }


// Adding Skeleton for Trip Card
struct TripCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Driver name and status badge
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 18)
                        .frame(width: 150)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 14)
                        .frame(width: 180)
                        .cornerRadius(4)
                }
                Spacer()
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 100, height: 24)
                    .cornerRadius(12)
            }
            
            Divider()
            
            // Location rows
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 14)
                    .cornerRadius(4)
            }
            
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 12, height: 12)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(height: 14)
                    .cornerRadius(4)
            }
            
            // Date
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.gray.opacity(0.4))
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 180, height: 14)
                    .cornerRadius(4)
            }
            
            // Optional View Invoice button for completed tasks
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(height: 44)
                .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Adding Skeleton for Maintenance Task Card
struct MaintenanceTaskCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with maintenance task type and status
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 150, height: 18)
                    .cornerRadius(4)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 100, height: 24)
                    .cornerRadius(12)
            }
            
            Divider()
            
            // Vehicle details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 80, height: 14)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 100, height: 14)
                        .cornerRadius(4)
                }
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 180, height: 14)
                    .cornerRadius(4)
            }
            
            // Description
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(height: 60)
                .cornerRadius(4)
            
            // Action button
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(height: 44)
                .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    //titleView()
    //SegementedcontrolView()
    //UniversalSkeletonView()
    //SearchBarView()
    //CustomSegementedcontrolView()
    TripCardSkeletonView()
    //MaintenanceTaskCardSkeletonView()
}
