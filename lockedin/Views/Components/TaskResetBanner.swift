//
//  TaskResetBanner.swift
//  lockedin
//
//  Created by Kevin Le on 3/22/25.
//


//
//  TaskResetBanner.swift
//  lockedin
//
//  Created by Kevin Le on 3/22/25.
//

import SwiftUI

struct TaskResetBanner: View {
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .foregroundColor(.white)
                    .font(.title2)
                
                Text("Your tasks have been reset for the new day!")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(5)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(10)
            .shadow(radius: 3)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
}

struct TaskResetBanner_Previews: PreviewProvider {
    static var previews: some View {
        TaskResetBanner(isVisible: .constant(true))
    }
}