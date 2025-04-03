import SwiftUI

// Unified ShimmerEffect that works on all iOS versions
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

// Unified extension for all iOS versions
extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}
