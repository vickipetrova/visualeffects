//
//  Wind.metal
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Two shaders that together make wind visible: `Wind` pushes a view around as a
 SwiftUI distortion effect, and `WindStreaks` draws the moving air over it as a
 color effect.
*/

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
#include "WeatherNoise.h"
using namespace metal;

/// How hard the wind is blowing at `uv`, in 0...1.
///
/// The field is sampled along the wind direction and scrolled against it, so
/// gusts sweep across the view and pass rather than every pixel pulsing in
/// place. That arrival and release is most of what makes wind legible.
static float gustField(float2 uv, float2 direction, float time) {
    float travel = dot(uv, direction);

    float gust = fbm(float2(travel * 2.4 - time * 0.4, dot(uv, float2(-direction.y, direction.x)) * 3.0 + time * 0.12));

    // Bias toward calm. Without this the view never settles and the gusts stop
    // registering as gusts.
    return smoothstep(0.32, 0.86, gust);
}

[[ stitchable ]]
float2 Wind(
    float2 position,
    float2 size,
    float time,
    float strength,
    float direction
) {
    float2 size1 = max(size, float2(1.0));
    float2 uv = position / size1;
    float2 windDirection = float2(cos(direction), sin(direction));

    float gust = gustField(uv, windDirection, time);

    // The gust is an envelope in 0...1, which on its own is a constant push in
    // one direction: it drags the whole view off one edge and exposes the
    // background behind it. Riding it on a signed carrier makes the
    // displacement average out to zero, so the view is pushed and released.
    float carrier = sin(dot(uv, windDirection) * 5.5 - time * 2.3);

    // Fine turbulence riding on top of the gust, so the surface ripples while
    // it is being pushed instead of sliding rigidly.
    float2 turbulence = float2(
        sin(uv.y * 17.0 + time * 3.1) * 0.6 + sin(uv.y * 6.5 - time * 1.7) * 0.4,
        cos(uv.x * 13.0 + time * 2.4) * 0.5
    );

    // Turbulence is scaled by the gust as well: still air should be still.
    float2 offset = (windDirection * gust * carrier * 1.5 + turbulence * gust * 0.4) * strength;

    // Ease the displacement down near the borders, so the edges of the view
    // stay roughly where they belong.
    float fadeX = smoothstep(0.0, 0.08, uv.x) * smoothstep(1.0, 0.92, uv.x);
    float fadeY = smoothstep(0.0, 0.08, uv.y) * smoothstep(1.0, 0.92, uv.y);
    offset *= fadeX * fadeY;

    // A distortion effect returns the position to sample from. Anything it
    // asks for outside the view comes back empty, which tears a transparent
    // notch in the border, so keep the sample inside. Fading alone is not
    // enough: it only makes the notch small.
    float2 target = clamp(position + offset, float2(0.0), size1);

    // This shader also runs across the margin that `maxSampleOffset` reserves
    // around the view. Clamping out there would smear the edge pixels into a
    // halo, so leave those positions alone.
    bool inside = all(position >= float2(0.0)) && all(position <= size1);

    return inside ? target : position;
}

[[ stitchable ]]
half4 WindStreaks(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float intensity,
    float direction
) {
    float2 size1 = max(size, float2(1.0));
    float2 uv = position / size1;
    float2 windDirection = float2(cos(direction), sin(direction));
    float2 acrossWind = float2(-windDirection.y, windDirection.x);

    // Measure along and across the wind in unit coordinates, so a fixed number
    // of streaks spans the view whatever shape it is. Correcting for aspect
    // here instead makes the travel axis shorter than one streak segment on a
    // narrow view, and the streaks smear into single view-wide blobs.
    float along = dot(uv, windDirection);
    float across = dot(uv, acrossWind);

    // Lanes of air running parallel to the wind.
    float lanePosition = across * 22.0;
    float lane = floor(lanePosition);
    float laneFraction = fract(lanePosition);
    float laneSeed = hash11(lane);

    // Each lane carries a stream of streaks at its own pace.
    float travel = along * 3.4 - time * (0.7 + 1.1 * laneSeed) + laneSeed * 11.0;
    float segment = floor(travel);
    float segmentFraction = fract(travel);

    float seed = hash21(float2(lane, segment));

    // Most lanes are empty at any moment; the gaps are what make the streaks
    // read as individual gusts of air.
    float present = step(0.62, seed);

    // Taper both ends so a streak looks like a wisp rather than a dash.
    float streakLength = 0.16 + 0.30 * seed;
    float body = smoothstep(0.0, streakLength * 0.35, segmentFraction)
               * smoothstep(streakLength, streakLength * 0.55, segmentFraction);

    float line = smoothstep(0.17, 0.0, abs(laneFraction - 0.5));

    // Only show streaks where the air is actually moving, so they appear and
    // die away with the same gusts that bend the view underneath.
    float gust = gustField(uv, windDirection, time);

    float coverage = saturate(line * body * present * gust * intensity * 0.9);

    half alpha = half(coverage);
    half3 tint = half3(1.0h, 1.0h, 1.0h);

    return color * (1.0h - alpha) + half4(tint * alpha, alpha);
}
