//
//  WeatherNoise.h
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
Hashing and noise helpers shared by the weather shaders. Every function is
 `inline` so that including this header from several `.metal` files in the same
 target does not produce duplicate symbols.
*/

#ifndef WeatherNoise_h
#define WeatherNoise_h

#include <metal_stdlib>
using namespace metal;

/*
 The hash functions come from Dave Hoskins' public domain "Hash without Sine"
 collection (https://www.shadertoy.com/view/4djSRW). They turn a coordinate into
 a repeatable pseudo-random number, which is how every weather shader here gives
 each drop, flake and gust its own size, speed and phase without uploading any
 per-particle data from Swift.
*/

/// A pseudo-random number in 0 ..< 1 for a single scalar seed.
inline float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

/// A pseudo-random number in 0 ..< 1 for a 2D seed, typically a grid cell.
inline float hash21(float2 p) {
    float3 p3 = fract(float3(p.x, p.y, p.x) * 0.1031);
    p3 += dot(p3, float3(p3.y, p3.z, p3.x) + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

/// Smoothly interpolated value noise, the building block of the gust and
/// god ray fields.
inline float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);

    // Smoothstep the cell fraction so the interpolation has no visible seams.
    float2 u = f * f * (3.0 - 2.0 * f);

    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

/// Fractal Brownian motion: several octaves of value noise stacked at halving
/// amplitude, which reads as turbulence rather than a regular wave.
inline float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < 5; i++) {
        value += amplitude * valueNoise(p);
        p *= 2.02;
        amplitude *= 0.5;
    }

    return value;
}

#endif /* WeatherNoise_h */
