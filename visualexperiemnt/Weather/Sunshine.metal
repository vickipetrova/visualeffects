//
//  Sunshine.metal
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Two shaders that together make a view look sunlit: `Sunshine` adds god rays, a
 warm grade and lens flare as a SwiftUI color effect, and `HeatHaze` shimmers
 the air as a distortion effect.
*/

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
#include "WeatherNoise.h"
using namespace metal;

/// The brightness of the god rays at a given angle, in 0...1.
///
/// Stacked harmonics rather than noise, deliberately: every term is an integer
/// multiple of the angle, so the pattern closes seamlessly at the wraparound
/// from +pi to -pi. Sampling noise by angle instead leaves a visible slit down
/// one side of the sun.
static float rayPattern(float angle, float time) {
    float value = sin(angle * 9.0 + time * 0.25) * 0.50
                + sin(angle * 17.0 - time * 0.17) * 0.30
                + sin(angle * 31.0 + time * 0.11) * 0.20;

    return value * 0.5 + 0.5;
}

[[ stitchable ]]
half4 Sunshine(
    float2 position,
    half4 color,
    float2 size,
    float2 origin,
    float time,
    float warmth,
    float rays
) {
    float2 size1 = max(size, float2(1.0));
    float aspect = size1.x / size1.y;

    // An isotropic space, so the sun's glow is round rather than stretched.
    float2 uv = position / size1;
    float2 originUV = origin / size1;
    float2 p = float2(uv.x * aspect, uv.y);
    float2 sun = float2(originUV.x * aspect, originUV.y);

    float2 toPixel = p - sun;
    float distanceToSun = length(toPixel);
    float angle = atan2(toPixel.y, toPixel.x);

    // The core: a tight disc inside a wide, soft bloom.
    float disc = smoothstep(0.085, 0.0, distanceToSun);
    float bloom = exp(-distanceToSun * 4.6);

    // The shafts. They fade in just outside the disc — rays that reach all the
    // way into the centre make the sun look striped instead of bright — and
    // fall off gently so they still carry across the frame.
    float shaftFalloff = exp(-distanceToSun * 1.5) * smoothstep(0.04, 0.3, distanceToSun);
    float shafts = smoothstep(0.42, 0.95, rayPattern(angle, time)) * shaftFalloff;

    // Lens flare ghosts, spaced along the line from the sun through the centre
    // of the frame, which is where a real lens throws them.
    float2 centre = float2(aspect * 0.5, 0.5);
    float2 axis = centre - sun;
    float ghosts = 0.0;

    for (int i = 1; i <= 3; i++) {
        float spacing = 0.85 + float(i) * 0.72;
        float2 ghostCentre = sun + axis * spacing;
        float radius = 0.055 + 0.035 * float(i);
        float d = distance(p, ghostCentre);

        // A ring rather than a disc: brighter at the rim, like a real ghost.
        float ring = smoothstep(radius, radius * 0.55, d) * (0.35 + 0.65 * smoothstep(radius * 0.4, radius * 0.85, d));
        ghosts += ring * (0.13 / float(i));
    }

    half4 result = color;

    // Warm the scene before the light goes on top, so the sun looks like it is
    // lighting the view rather than sitting in front of it.
    half warmAmount = half(saturate(warmth));
    result.rgb = mix(result.rgb, result.rgb * half3(1.16h, 1.02h, 0.82h), warmAmount * 0.55h);

    float light = saturate((disc * 0.9 + bloom * 0.22) * (0.4 + 0.6 * rays)
                           + shafts * rays * 0.38
                           + ghosts * rays);

    half alpha = half(light);
    half3 tint = mix(half3(1.0h, 0.95h, 0.86h), half3(1.0h, 0.84h, 0.58h), warmAmount);

    // Source-over with premultiplied alpha, which is what SwiftUI expects back.
    return result * (1.0h - alpha) + half4(tint * alpha, alpha);
}

[[ stitchable ]]
float2 HeatHaze(
    float2 position,
    float2 size,
    float time,
    float amount
) {
    float2 size1 = max(size, float2(1.0));
    float2 uv = position / size1;

    // Rising heat pools near the ground, so the shimmer builds toward the
    // bottom of the view and leaves the sky alone.
    float mask = smoothstep(0.35, 1.0, uv.y);

    // A tight vertical ripple riding on slower turbulence, which is what stops
    // it reading as a uniform wobble.
    float ripple = sin(uv.y * 42.0 - time * 3.6) * 0.45
                 + (fbm(float2(uv.x * 6.0, uv.y * 11.0 - time * 1.1)) - 0.5) * 1.1;

    // Ease down at the left and right borders, then keep the sample inside the
    // view outright — see `Wind` for why the fade alone is not enough.
    float fade = smoothstep(0.0, 0.06, uv.x) * smoothstep(1.0, 0.94, uv.x);

    float2 target = clamp(position + float2(ripple * amount * mask * fade, 0.0),
                          float2(0.0), size1);

    bool inside = all(position >= float2(0.0)) && all(position <= size1);

    return inside ? target : position;
}
