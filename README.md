# Info

This repo containts examples in SwiftUI of visual effects. 

# Contents

## Ripple Effect
An effect using the Metal Library. 

Two examples:
- Ripple effect applied to a Circle Shape or Image
- A shower scene with a water drop trigerring a ripple effect through water. 

## Stripe Effect
Stripe background with an array of colors. 

## Weather Effects
Four weather shaders built on the Metal Library, each one a reusable modifier
that works on any view.

| Effect | Modifier | What it does |
| --- | --- | --- |
| Rain | `.rainEffect(intensity:wind:speed:)` | Three parallax layers of streaks, sheared by the wind so the slant and the fall direction stay consistent, over a cool overcast grade. |
| Snow | `.snowEffect(intensity:wind:speed:)` | Depth-layered flakes that wobble as they fall — near ones large, fast and out of focus, far ones small, slow and sharp. |
| Wind | `.windEffect(strength:direction:streaks:)` | A gust field that bends the view as it sweeps across, with streaks of moving air drawn only where the air is actually moving. |
| Sunny | `.sunshineEffect(origin:warmth:rays:shimmer:)` | God rays from a movable sun, a warm grade, lens flare, and heat rising off the ground. |

```swift
Image("photo")
    .rainEffect(intensity: 0.8, wind: 0.3)
```

Every drop, flake and gust comes from hashing its grid cell rather than from a
particle list, so a layer costs the same no matter how full it looks.

`WeatherScene` shows all four over the same landscape, with a picker to switch
between them.
