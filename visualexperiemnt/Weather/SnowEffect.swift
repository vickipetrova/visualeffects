//
//  SnowEffect.swift
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An example of using the `Snow` shader as a SwiftUI color effect.
*/

import SwiftUI

/// A modifier that snows over its content for as long as it is on screen.
struct SnowEffect: ViewModifier {

    /// How much snow falls, from a few flakes at `0` to a blizzard at `1`.
    var intensity: Double

    /// How far the wind carries the flakes sideways. Negative values blow them
    /// the other way.
    var wind: Double

    /// A multiplier on how fast the flakes fall.
    var speed: Double

    /// The shader's clock starts here. See `RainEffect` for why elapsed time
    /// rather than an absolute timestamp goes to the GPU.
    @State private var start = Date()

    init(intensity: Double = 0.7, wind: Double = 0.3, speed: Double = 1.0) {
        self.intensity = intensity
        self.wind = wind
        self.speed = speed
    }

    func body(content: Content) -> some View {
        let intensity = intensity
        let wind = wind
        let speed = speed

        TimelineView(.animation) { context in
            let elapsedTime = context.date.timeIntervalSince(start)

            // Flatten the content first. Without this, SwiftUI can hand
            // the shader each leaf layer on its own, and text ends up
            // rained on separately from the view behind it.
            content
                .compositingGroup()
                .visualEffect { view, proxy in
                    view.colorEffect(
                        ShaderLibrary.Snow(
                            .float2(proxy.size),
                            .float(elapsedTime),

                            // Parameters
                            .float(intensity),
                            .float(wind),
                            .float(speed)
                        )
                    )
                }
        }
    }
}

extension View {

    /// Snows over the view.
    /// - Parameters:
    ///   - intensity: A few flakes at `0`, a blizzard at `1`.
    ///   - wind: The sideways drift. Negative blows the other way.
    ///   - speed: A multiplier on how fast the flakes fall.
    func snowEffect(intensity: Double = 0.7, wind: Double = 0.3, speed: Double = 1.0) -> some View {
        modifier(SnowEffect(intensity: intensity, wind: wind, speed: speed))
    }
}

#Preview("Snow") {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.13, green: 0.17, blue: 0.28), Color(red: 0.42, green: 0.48, blue: 0.60)],
            startPoint: .top,
            endPoint: .bottom
        )

        Image(systemName: "snowflake")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120)
            .foregroundStyle(.white.opacity(0.75))
    }
    .snowEffect(intensity: 0.8, wind: 0.4)
    .ignoresSafeArea()
}
