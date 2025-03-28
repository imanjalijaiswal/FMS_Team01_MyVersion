//
//  SpashScreen.swift
//  Fleet Management System
//
//  Created by Arnav Chauhan on 29/03/25.
//

import SwiftUI

struct SpashScreen: View {
    @State private var isActive = false
    @State private var textLocation : CGFloat = 40
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.primaryGradientStart,
                        Color.primaryGradientEnd,
                        Color.primaryGradientStart
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    HStack(spacing: 0) {
                        Text("InFleet")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                        Text(" Express")
                            .foregroundStyle(Color.primaryGradientStart1)
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 40))
                    .offset(y: textLocation)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.textLocation = -50
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                self.isActive = true
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SpashScreen()
}
