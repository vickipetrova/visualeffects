//
//  WindEffect.swift
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An example of using the `Wind` and `WindStreaks` shaders together as SwiftUI
 distortion and color effects.
*/

import SwiftUI

/// A modifier that blows gusts of wind across its content.
///
/// Two shaders run back to back: `Wind` bends the content, then `WindStreaks`
/// draws the moving air over the result. Both read the same gust field, so a
/// streak only ever appears where the view is actually being pushed.
struct WindEffect: ViewModifier {

    /// How far a gust displaces the content, in points.
    var strength: Double

    /// The direction the wind blows in, in degrees. `0` blows to the right.
    var direction: Double

    /// How visible the streaks of moving air are. Set to `0` for an invisible
    /// wind that only bends the content.
    var streaks: Double

    /// The shader's clock starts here. See `RainEffect` for why elapsed time
    /// rather than an absolute timestamp goes to the GPU.
    @State private var start = Date()

    init(strength: Double = 14, direction: Double = 0, streaks: Double = 0.8) {
        self.strength = strength
        self.direction = direction
        self.streaks = streaks
    }

    func body(content: Content) -> some View {
        let strength = strength
        let radians = direction * .pi / 180
        let streaks = streaks
        let maxSampleOffset = maxSampleOffset

        TimelineView(.animation) { context in
            let elapsedTime = context.date.timeIntervalSince(start)

            // Flatten the content first. Without this, SwiftUI can hand
            // the shader each leaf layer on its own, and text ends up
            // rained on separately from the view behind it.
            content
                .compositingGroup()
                .visualEffect { view, proxy in
                    view
                        .distortionEffect(
                            ShaderLibrary.Wind(
                                .float2(proxy.size),
                                .float(elapsedTime),

                                // Parameters
                                .float(strength),
                                .float(radians)
                            ),
                            maxSampleOffset: maxSampleOffset
                        )
                        .colorEffect(
                            ShaderLibrary.WindStreaks(
                                .float2(proxy.size),
                                .float(elapsedTime),

                                // Parameters
                                .float(streaks),
                                .float(radians)
                            )
                        )
                }
        }
    }

    /// The furthest the distortion can reach for a pixel. The shader offsets
    /// by at most `strength * (1.5 + 0.4 * turbulence)` along either axis, so
    /// this leaves headroom above that — too small a value clips the edges.
    var maxSampleOffset: CGSize {
        CGSize(width: strength * 2.5, height: strength * 2.5)
    }
}

extension View {

    /// Blows gusts of wind across the view.
    /// - Parameters:
    ///   - strength: How far a gust displaces the content, in points.
    ///   - direction: The direction the wind blows in, in degrees. `0` blows right.
    ///   - streaks: How visible the moving air is. `0` bends the content invisibly.
    func windEffect(strength: Double = 14, direction: Double = 0, streaks: Double = 0.8) -> some View {
        modifier(WindEffect(strength: strength, direction: direction, streaks: streaks))
    }
}

#Preview("Wind") {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.30, green: 0.38, blue: 0.47), Color(red: 0.62, green: 0.70, blue: 0.74)],
            startPoint: .top,
            endPoint: .bottom
        )

        VStack(spacing: 24) {
            Image(systemName: "wind")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 140)
                .foregroundStyle(.white.opacity(0.9))

            Text("WINDSWEPT")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
    .windEffect(strength: 16, direction: -8)
    .ignoresSafeArea()
}
