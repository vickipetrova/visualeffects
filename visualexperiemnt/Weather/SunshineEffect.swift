//
//  SunshineEffect.swift
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An example of using the `Sunshine` and `HeatHaze` shaders together as SwiftUI
 color and distortion effects.
*/

import SwiftUI

/// A modifier that lights its content with sunshine: god rays from a movable
/// sun, a warm grade, lens flare, and heat rising off the ground.
struct SunshineEffect: ViewModifier {

    /// Where the sun sits, in unit coordinates. `.topTrailing` puts it in the
    /// upper right corner.
    var origin: UnitPoint

    /// How golden the light is. `0` is a cool midday, `1` a late afternoon.
    var warmth: Double

    /// How strong the rays, bloom and flare are.
    var rays: Double

    /// How far the rising heat displaces the content, in points. `0` turns the
    /// shimmer off.
    var shimmer: Double

    /// The shader's clock starts here. See `RainEffect` for why elapsed time
    /// rather than an absolute timestamp goes to the GPU.
    @State private var start = Date()

    init(
        origin: UnitPoint = UnitPoint(x: 0.78, y: 0.18),
        warmth: Double = 0.6,
        rays: Double = 0.8,
        shimmer: Double = 3
    ) {
        self.origin = origin
        self.warmth = warmth
        self.rays = rays
        self.shimmer = shimmer
    }

    func body(content: Content) -> some View {
        let origin = origin
        let warmth = warmth
        let rays = rays
        let shimmer = shimmer
        let maxSampleOffset = maxSampleOffset

        TimelineView(.animation) { context in
            let elapsedTime = context.date.timeIntervalSince(start)

            // Flatten the content first. Without this, SwiftUI can hand
            // the shader each leaf layer on its own, and text ends up
            // rained on separately from the view behind it.
            content
                .compositingGroup()
                .visualEffect { view, proxy in
                    // The sun is authored in unit coordinates so a caller does not
                    // have to know the view's size; the shader wants points.
                    let sun = CGPoint(
                        x: origin.x * proxy.size.width,
                        y: origin.y * proxy.size.height
                    )

                    return view
                        .distortionEffect(
                            ShaderLibrary.HeatHaze(
                                .float2(proxy.size),
                                .float(elapsedTime),

                                // Parameters
                                .float(shimmer)
                            ),
                            maxSampleOffset: maxSampleOffset
                        )
                        .colorEffect(
                            ShaderLibrary.Sunshine(
                                .float2(proxy.size),
                                .float2(sun),
                                .float(elapsedTime),

                                // Parameters
                                .float(warmth),
                                .float(rays)
                            )
                        )
                }
        }
    }

    /// The shimmer displaces by at most `amount` horizontally, so this leaves
    /// plenty of headroom above that.
    var maxSampleOffset: CGSize {
        CGSize(width: shimmer * 2, height: shimmer * 2)
    }
}

extension View {

    /// Lights the view with sunshine.
    /// - Parameters:
    ///   - origin: Where the sun sits, in unit coordinates.
    ///   - warmth: A cool midday at `0`, a golden late afternoon at `1`.
    ///   - rays: How strong the rays, bloom and lens flare are.
    ///   - shimmer: How far rising heat displaces the content, in points.
    func sunshineEffect(
        origin: UnitPoint = UnitPoint(x: 0.78, y: 0.18),
        warmth: Double = 0.6,
        rays: Double = 0.8,
        shimmer: Double = 3
    ) -> some View {
        modifier(SunshineEffect(origin: origin, warmth: warmth, rays: rays, shimmer: shimmer))
    }
}

#Preview("Sunshine") {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.24, green: 0.53, blue: 0.82), Color(red: 0.86, green: 0.78, blue: 0.62)],
            startPoint: .top,
            endPoint: .bottom
        )

        Image(systemName: "mountain.2.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 260)
            .foregroundStyle(Color(red: 0.20, green: 0.30, blue: 0.29))
            .offset(y: 120)
    }
    .sunshineEffect(origin: UnitPoint(x: 0.74, y: 0.22), warmth: 0.7)
    .ignoresSafeArea()
}
