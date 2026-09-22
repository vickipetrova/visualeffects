//
//  Rain.metal
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A shader that layers falling rain over a view when using it as a SwiftUI color
 effect.
*/

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
#include "WeatherNoise.h"
using namespace metal;

/// Draws one parallax layer of rain and returns its coverage in 0...1.
///
/// The layer is a grid of cells, one drop per cell. Because the grid is built
/// from a hash of the cell index rather than from a particle list, an entire
/// layer costs a handful of instructions no matter how many drops it appears
/// to contain.
static float rainLayer(
    float2 uv,
    float aspect,
    float time,
    float columns,
    float speed,
    float wind,
    float thickness,
    float density
) {
    // Work in a space where one unit of x matches one unit of y, so drops keep
    // their shape on any view. Shearing x by y slants the columns, which tilts
    // both the streaks and the direction they travel in — they stay consistent.
    float2 p = float2(uv.x * aspect + uv.y * wind, uv.y);

    float columnPosition = p.x * columns;
    float column = floor(columnPosition);
    float fx = fract(columnPosition);

    // Every column falls at its own rate and starts at its own offset, so the
    // layer never visibly marches in step.
    float columnSeed = hash11(column);
    float columnSpeed = speed * (0.65 + 0.7 * columnSeed);

    // Cells are 2.5x taller than they are wide, which is the room a streak
    // needs. Subtracting time moves a drop toward increasing y, and y grows
    // downward in SwiftUI's coordinate space, so the drops fall.
    float rows = columns * 0.4;
    float rowPosition = p.y * rows - time * columnSpeed + columnSeed * 17.0;
    float row = floor(rowPosition);
    float fy = fract(rowPosition);

    float seed = hash21(float2(column, row));

    // Leave some cells empty. At low density most cells drop out, which reads
    // as drizzle rather than as a thinner downpour.
    float present = step(1.0 - density, seed);

    // Scatter the drop across the width of its cell so the columns do not
    // line up into visible stripes.
    float offset = 0.15 + 0.7 * hash21(float2(column + 13.7, row));
    float dx = fx - offset;
    float line = smoothstep(thickness, 0.0, abs(dx));

    // The streak is brightest at its leading edge and fades out along the
    // trail behind it.
    float streakLength = 0.28 + 0.42 * seed;
    float trail = smoothstep(0.0, streakLength, fy) * smoothstep(streakLength + 0.03, streakLength, fy);

    // A small bright head sells the drop as water rather than as a scratch.
    float head = smoothstep(streakLength * 0.82, streakLength, fy) * smoothstep(streakLength + 0.03, streakLength, fy);

    return line * (trail * 0.85 + head * 0.2) * present;
}

[[ stitchable ]]
half4 Rain(
    float2 position,
    half4 color,
    float2 size,
    float time,
    float intensity,
    float wind,
    float speed
) {
    float2 uv = position / max(size, float2(1.0));
    float aspect = size.x / max(size.y, 1.0);

    // Three layers at different scales and speeds read as depth: the far layer
    // is thin, slow and faint, the near layer is thick, fast and bright.
    float far  = rainLayer(uv, aspect, time, 34.0, 0.75 * speed, wind * 0.75, 0.028, 0.60 * intensity);
    float mid  = rainLayer(uv, aspect, time, 21.0, 1.05 * speed, wind,        0.042, 0.55 * intensity);
    float near = rainLayer(uv, aspect, time, 15.0, 1.50 * speed, wind * 1.3,  0.060, 0.45 * intensity);

    float coverage = saturate(far * 0.32 + mid * 0.5 + near * 0.62);

    half4 result = color;

    // Grade the view toward a cool overcast before the drops go on top, so the
    // rain looks like it is falling through the scene rather than over it.
    half haze = half(saturate(intensity) * 0.22);
    result.rgb = mix(result.rgb, result.rgb * half3(0.80h, 0.88h, 1.0h), haze);

    // Composite the drops with source-over using premultiplied alpha, which is
    // what SwiftUI expects back. Doing it this way keeps the effect correct
    // over transparent pixels instead of blowing them out.
    half alpha = half(coverage);
    half3 tint = half3(0.86h, 0.93h, 1.0h);

    return result * (1.0h - alpha) + half4(tint * alpha, alpha);
}
