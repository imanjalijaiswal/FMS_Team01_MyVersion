//
//  SkeltonView.swift
//  Fleet Management System
//
//  Created by Arnav Chauhan on 29/03/25.
//

import SwiftUI

struct SkeltonView: View {
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 50, height: 50)
                        .shimmer()
                }
                .padding(.trailing, 8)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 200, height: 50)
                    .cornerRadius(12)
                    .shimmer()
                
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 170, height: 50)
                    .cornerRadius(12)
                    .shimmer()
            }
            .padding(.leading, 8)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(0..<4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 8) {
                            GeometryReader { geometry in
                                VStack {
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack {
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.4))
                                                        .frame(width: geometry.size.width * 0.3, height: 30)
                                                        .cornerRadius(12)
                                                        .shimmer()
                                                    Spacer()
                                                    Rectangle()
                                                        .fill(Color.gray.opacity(0.4))
                                                        .frame(width: geometry.size.width * 0.4, height: 30)
                                                        .cornerRadius(12)
                                                        .shimmer()
                                                }
                                                
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.4))
                                                    .frame(width: geometry.size.width, height: 8)
                                                    .cornerRadius(12)
                                                    .shimmer()
                                                
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.4))
                                                    .frame(width: geometry.size.width, height: 50)
                                                    .cornerRadius(12)
                                                    .shimmer()
                                            }
                                        }
                                    }
                                }
                            
                            .frame(height: 100)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                    }
                }
                .padding()
            }
        }
    }
//}

#Preview {
    SkeltonView()
}
