//
//  Snow.metal
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A shader that layers drifting snow over a view when using it as a SwiftUI color
 effect.
*/

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
#include "WeatherNoise.h"
using namespace metal;

/// Draws one parallax layer of snow and returns its coverage in 0...1.
///
/// Snow reads as depth far more than rain does, so the three things that sell
/// distance — size, speed and how sharply a flake is focused — are all driven
/// from the same layer scale rather than tuned independently.
static float snowLayer(
    float2 uv,
    float aspect,
    float time,
    float cells,
    float speed,
    float wind,
    float flakeSize,
    float softness,
    float density
) {
    // An isotropic space with square cells, so flakes stay round on any view.
    float2 p = float2(uv.x * aspect, uv.y) * cells;

    // Falling and drifting are the same operation: slide the whole grid.
    // Because a flake is identified by its cell index, its hash — and so its
    // size, speed and wobble — travels with it.
    p.y -= time * speed;
    p.x -= time * wind;

    float2 cell = floor(p);
    float2 f = fract(p);

    float seed = hash21(cell);
    float present = step(1.0 - density, seed);

    // Keep the flake well inside its cell. Each layer only looks at its own
    // cell, so a centre that wanders too far would get clipped at the border.
    float2 centre = float2(
        0.28 + 0.44 * hash21(cell + float2(7.3, 1.1)),
        0.28 + 0.44 * hash21(cell + float2(19.1, 5.7))
    );

    // The wobble is what makes snow look like it is falling through air rather
    // than being dropped. Every flake gets its own rate and phase.
    centre.x += sin(time * (0.5 + 1.1 * seed) + seed * 6.2831) * 0.14;
    centre.y += cos(time * (0.4 + 0.8 * seed) + seed * 3.1415) * 0.04;

    float radius = flakeSize * (0.5 + 0.8 * seed);
    float distanceToCentre = distance(f, centre);

    // `softness` at 0 gives a crisp flake, at 1 a soft out-of-focus blob.
    float inner = radius * mix(0.65, 0.0, saturate(softness));
    float flake = smoothstep(radius, inner, distanceToCentre);

    return flake * present * (0.55 + 0.45 * seed);
}

[[ stitchable ]]
half4 Snow(
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

    // Far flakes are small, slow, sharp and numerous; near flakes are large,
    // fast and defocused, as if passing close to the lens.
    float far = snowLayer(uv, aspect, time, 26.0, 0.10 * speed, 0.05 * wind,
                          0.070, 0.15, 0.55 * intensity);
    float mid = snowLayer(uv, aspect, time, 15.0, 0.16 * speed, 0.09 * wind,
                          0.085, 0.45, 0.45 * intensity);
    float near = snowLayer(uv, aspect, time, 7.0, 0.26 * speed, 0.15 * wind,
                           0.110, 0.95, 0.35 * intensity);

    float coverage = saturate(far * 0.55 + mid * 0.75 + near * 0.55);

    half4 result = color;

    // A cold, slightly lifted grade. Snow scenes read as bright and low
    // contrast, the opposite of the darkening that rain gets.
    half chill = half(saturate(intensity) * 0.20);
    result.rgb = mix(result.rgb, result.rgb * half3(0.94h, 0.97h, 1.05h) + 0.04h, chill);

    // Source-over with premultiplied alpha, which is what SwiftUI expects back.
    half alpha = half(coverage);
    half3 tint = half3(0.98h, 0.99h, 1.0h);

    return result * (1.0h - alpha) + half4(tint * alpha, alpha);
}
