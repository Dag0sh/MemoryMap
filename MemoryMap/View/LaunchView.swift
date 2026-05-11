import SwiftUI

struct LaunchView: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.13, green: 0.25, blue: 0.60), Color(red: 0.42, green: 0.18, blue: 0.68)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulse ? 1.12 : 1.0)
                        .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)

                    Circle()
                        .fill(Color.white.opacity(0.07))
                        .frame(width: 110, height: 110)

                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 10) {
                    Text("MemoryMap")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Ваши воспоминания на карте")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                }

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.4)
            }
        }
        .onAppear { pulse = true }
    }
}
