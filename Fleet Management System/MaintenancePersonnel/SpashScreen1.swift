////
////  SpashScreen.swift
////  Fleet Management System
////
////  Created by Arnav Chauhan on 29/03/25.
////
//
//import SwiftUI
//
//struct SpashScreen: View {
//    @State private var isLoading = false
//    @State private var textLocation : CGFloat = 50
//    var body: some View {
//        ZStack{
//            //background
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color(red: 70/255, green: 11/255, blue: 134/255),  // Deep Purple
//                    Color(red: 153/255, green: 27/255, blue: 171/255), // Medium Purple
//                    Color(red: 241/255, green: 90/255, blue: 89/255),  // Coral
//                    Color(red: 251/255, green: 176/255, blue: 59/255)  // Orange
//                ]),
//                startPoint: .topLeading,
//                endPoint: .bottomTrailing
//            ).ignoresSafeArea()
//            
//            HStack{
//                Text("InFleet")
//                    .foregroundStyle(.white) +
//                Text("Express")
//                    .foregroundStyle(Color(red: 251/255, green: 176/255, blue: 59/255)) // Orange color for "Express"
//            }.offset(y:textLocation)
//                .font(.system(size: 40))
//                .bold()
//                .onAppear{
//                    withAnimation(.easeInOut(duration: 2)){
//                        self.textLocation = -60
//                    }
//                }
//        }
//    }
//}
//#Preview {
//    SpashScreen()
//}
