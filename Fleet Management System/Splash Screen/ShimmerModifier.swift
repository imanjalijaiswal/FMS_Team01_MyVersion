import SwiftUI

// A completely renamed shimmer effect to avoid any conflicts
struct ShimmerModifier: ViewModifier {
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

// Extension with a new name for the effect
extension View {
    func applyShimmer() -> some View {
        modifier(ShimmerModifier())
    }
} 