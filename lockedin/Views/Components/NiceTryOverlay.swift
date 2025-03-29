//
//  NiceTryOverlay.swift
//  lockedin
//
//  Created by Kevin Le on 3/28/25.
//

import SwiftUI

struct NiceTryOverlay: View {
    // Animation properties
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -5

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Custom message with animation
            VStack(spacing: 25) {
                Text("Nice Try Diddy")
                    .font(.custom("Zapfino", size: 36)) // Cursive font
                    .foregroundColor(.white)
                    .shadow(color: .pink.opacity(0.8), radius: 4, x: 0, y: 2)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Optional subtitle
                Text("Complete your tasks first!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 5)
                    .opacity(opacity)
                
                // Optional emoji
                Text("😉")
                    .font(.system(size: 48))
                    .padding(.top, 10)
                    .opacity(opacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.7), .blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
            )
            .scaleEffect(scale)
            .onAppear {
                // Animate in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    opacity = 1.0
                    scale = 1.0
                }
                
                // Subtle rotation animation
                withAnimation(
                    Animation.easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true)
                ) {
                    rotation = 5
                }
            }
        }
    }
}

// Alternative version that uses a custom font file if available
struct NiceTryOverlayAlt: View {
    // Animation properties
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var rotation: Double = -5
    
    // Font fallback handling
    private var cursiveFont: Font {
        // Try to use these fonts in order of preference
        // These are fonts that should be available on iOS
        for fontName in ["Zapfino", "Snell Roundhand", "Savoye LET", "Noteworthy-Bold"] {
            if UIFont(name: fontName, size: 36) != nil {
                return Font.custom(fontName, size: 36)
            }
        }
        // Fallback to system italic
        return Font.system(size: 36, weight: .medium, design: .serif).italic()
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Custom message with animation
            VStack(spacing: 25) {
                Text("Nice Try Diddy")
                    .font(cursiveFont)
                    .foregroundColor(.white)
                    .shadow(color: .pink.opacity(0.8), radius: 4, x: 0, y: 2)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Optional subtitle
                Text("Complete your tasks first!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 5)
                    .opacity(opacity)
                
                // Optional emoji
                Text("😉")
                    .font(.system(size: 48))
                    .padding(.top, 10)
                    .opacity(opacity)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.7), .blue.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 10)
            )
            .scaleEffect(scale)
            .onAppear {
                // Animate in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    opacity = 1.0
                    scale = 1.0
                }
                
                // Subtle rotation animation
                withAnimation(
                    Animation.easeInOut(duration: 2.5)
                        .repeatForever(autoreverses: true)
                ) {
                    rotation = 5
                }
            }
        }
    }
}

// Preview
struct NiceTryOverlay_Previews: PreviewProvider {
    static var previews: some View {
        NiceTryOverlay()
    }
}
