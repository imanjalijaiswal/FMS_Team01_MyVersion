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
extension View {
    @ViewBuilder
    func shimmer() -> some View {
        if #available(iOS 17.0, *) {
            self.modifier(ShimmerEffect())
        } else {
            self
        }
    }
}

@available(iOS 17.0, *)
struct ShimmerEffect: ViewModifier {
    @State private var moveRight = false

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.2),
                            Color.gray.opacity(0.6),
                            Color.gray.opacity(0.2)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: moveRight ? geometry.size.width : -geometry.size.width)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false)
                        ) {
                            moveRight.toggle()
                        }
                    }
                }
            }
            .mask(content) // Ensures shimmer effect only applies within view bounds
    }
}


#Preview {
    SkeltonView()
}
