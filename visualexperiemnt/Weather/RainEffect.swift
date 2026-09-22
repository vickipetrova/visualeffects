//
//  RainEffect.swift
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An example of using the `Rain` shader as a SwiftUI color effect.
*/

import SwiftUI

/// A modifier that rains over its content for as long as it is on screen.
///
/// The rain is drawn entirely by the shader, so this works on any view —
/// a shape, an image, or a whole scene — and costs the same either way.
struct RainEffect: ViewModifier {

    /// How much rain falls, from a drizzle at `0` to a downpour at `1`.
    var intensity: Double

    /// How far the wind pushes the rain sideways. Negative values blow it
    /// the other way.
    var wind: Double

    /// A multiplier on how fast the drops fall.
    var speed: Double

    /// The shader's clock starts here. Elapsed time is what gets sent to the
    /// GPU: an absolute timestamp is far too large to survive the conversion
    /// to a 32-bit float with any sub-second precision left.
    @State private var start = Date()

    init(intensity: Double = 0.7, wind: Double = 0.25, speed: Double = 1.0) {
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
                        ShaderLibrary.Rain(
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

    /// Rains over the view.
    /// - Parameters:
    ///   - intensity: A drizzle at `0`, a downpour at `1`.
    ///   - wind: The sideways push on the drops. Negative blows the other way.
    ///   - speed: A multiplier on how fast the drops fall.
    func rainEffect(intensity: Double = 0.7, wind: Double = 0.25, speed: Double = 1.0) -> some View {
        modifier(RainEffect(intensity: intensity, wind: wind, speed: speed))
    }
}

#Preview("Rain") {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.16, green: 0.20, blue: 0.29), Color(red: 0.36, green: 0.42, blue: 0.51)],
            startPoint: .top,
            endPoint: .bottom
        )

        Image(systemName: "cloud.rain.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120)
            .foregroundStyle(.white.opacity(0.85))
    }
    .rainEffect(intensity: 0.8, wind: 0.3)
    .ignoresSafeArea()
}
