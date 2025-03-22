//
//  CongratulationView.swift
//  lockedin
//
//  Created by Kevin Le on 3/21/25.
//


//
//  CongratulationView.swift
//  lockedin
//
//  Created by Kevin Le on 3/21/25.
//

import SwiftUI

struct CongratulationView: View {
    let taskTitle: String
    var onDismiss: () -> Void
    
    // Animation states
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
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
    
    // Add some confetti data
    private struct ConfettiPiece: Identifiable {
        let id = UUID()
        let color: Color
        let rotation: Double
        let position: CGPoint
        let size: CGFloat
        
        static func generatePieces(count: Int) -> [ConfettiPiece] {
            let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
            
            return (0..<count).map { _ in
                ConfettiPiece(
                    color: colors.randomElement()!,
                    rotation: Double.random(in: 0...360),
                    position: CGPoint(
                        x: CGFloat.random(in: -150...150),
                        y: CGFloat.random(in: -200...0)
                    ),
                    size: CGFloat.random(in: 5...10)
                )
            }
        }
    }
    
    @State private var confetti = ConfettiPiece.generatePieces(count: 30)
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation {
                        opacity = 0
                        scale = 0.5
                    }
                    
                    // Dismiss after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }
            
                            // Confetti animation
            ForEach(confetti) { piece in
                Rectangle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 2.5)
                    .rotationEffect(.degrees(piece.rotation))
                    .position(
                        x: UIScreen.main.bounds.width / 2 + piece.position.x,
                        y: UIScreen.main.bounds.height / 2 + piece.position.y
                    )
                    .opacity(opacity)
                    .animation(
                        Animation.easeOut(duration: 2)
                            .delay(Double.random(in: 0...0.3)),
                        value: opacity
                    )
            }
            
            // Popup content
            VStack(spacing: 20) {
                // Emoji animation
                HStack(spacing: 10) {
                    ForEach(0..<5) { i in
                        Text(["🎉", "🎊", "✨", "⭐", "🌟"][i % 5])
                            .font(.system(size: 30))
                            .offset(y: i % 2 == 0 ? -10 : 0)
                    }
                }
                // Celebration emoji with rotation animation
                Text("🎊")
                    .font(.system(size: 70))
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            rotation = 20
                        }
                    }
                
                // Congratulatory message
                Text(randomMessage)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Task completed
                Text("You completed:")
                    .fontWeight(.medium)
                
                Text(taskTitle)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Achievement message
                Text("Keep up the great momentum!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
                
                // Dismiss button
                Button(action: {
                    withAnimation {
                        opacity = 0
                        scale = 0.5
                    }
                    
                    // Dismiss after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }) {
                    Text("Continue")
                        .fontWeight(.medium)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.4), radius: 10, x: 0, y: 4)
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // Animate popup when view appears
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
}

struct CongratulationView_Previews: PreviewProvider {
    static var previews: some View {
        CongratulationView(taskTitle: "Morning Meditation") {
            print("Dismissed")
        }
    }
}
