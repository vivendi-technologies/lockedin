//
//  AppUnlockBanner.swift
//  lockedin
//
//  Created by Kevin Le on 3/21/25.
//

import SwiftUI

struct AppUnlockBanner: View {
    @Binding var isVisible: Bool
    
    private let unlockMessages = [
        "All tasks complete! You've unlocked your apps!",
        "Great job! Your apps are now available!",
        "Mission accomplished! Enjoy your apps!",
        "You did it! Apps unlocked!",
        "Tasks completed! Apps are now accessible!",
        "Happy scrolling!"
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent background for fullscreen overlay
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        isVisible = false
                    }
                }
            
            // Banner content
            VStack(spacing: 20) {
                // Success checkmark icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                    .padding(.top)
                
                // Unlock message
                Text(unlockMessages.randomElement() ?? "All tasks complete! You've unlocked your apps!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Close button
                Button(action: {
                    withAnimation {
                        isVisible = false
                    }
                }) {
                    Text("Let's go!")
                        .fontWeight(.medium)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color(UIColor.label).opacity(0.2), radius: 10, x: 0, y: 4)
            )
            .transition(.scale.combined(with: .opacity))
        }
        .zIndex(10) // Ensure it appears above everything else
    }
}

// Preview
struct AppUnlockBanner_Previews: PreviewProvider {
    static var previews: some View {
        AppUnlockBanner(isVisible: .constant(true))
    }
}
