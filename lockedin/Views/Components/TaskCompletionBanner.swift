//
//  TaskCompletionBanner.swift
//  lockedin
//
//  Created by Kevin Le on 3/22/25.
//


//
//  TaskCompletionBanner.swift
//  lockedin
//
//  Created by Kevin Le on 3/22/25.
//

import SwiftUI

struct TaskCompletionBanner: View {
    @Binding var isVisible: Bool
    let taskTitle: String
    
    // Different congratulatory messages
    private let messages = [
        "Great job! 🎉",
        "Light work! 💪",
        "You crushed it! 🔥",
        "Well done! 👏",
        "Let's gooooooo! ⭐",
        "Success! 🏆",
        "Nailed it! 🎯",
        "Fantastic! 🌟",
        "You're on fire! 🔥",
        "Progress made! 📈",
        "Task complete! ✅",
        "Mission accomplished! 🚀",
        "Keep bloomin'! 🌼",
        "No dooming up in here 😤",
        "WOOOOOOO 🤪"
    ]
    
    // Random message selection
    private var randomMessage: String {
        messages.randomElement() ?? "Great job! 🎉"
    }
    
    var body: some View {
        VStack {
            // Swipe indicator line
            Capsule()
                .fill(Color.white.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            HStack {
                Text(randomMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                // Add a subtle indicator that you can swipe to dismiss
                Image(systemName: "chevron.down")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color.green)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 20 {
                        withAnimation {
                            isVisible = false
                        }
                    }
                }
        )
        .onAppear {
            // Auto-dismiss after a few seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isVisible = false
                }
            }
        }
    }
}

struct TaskCompletionBanner_Previews: PreviewProvider {
    static var previews: some View {
        TaskCompletionBanner(isVisible: .constant(true), taskTitle: "Morning Meditation")
    }
}
