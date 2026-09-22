//
//  WeatherScene.swift
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/09/2026.
//

/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A scene that shows the four weather shaders over the same landscape, so they
 can be compared side by side.
*/

import SwiftUI

/// The four kinds of weather in the scene, and the look each one gives the
/// landscape underneath the shader.
///
/// Retinting the scene matters as much as the particles do: rain over a sunny
/// sky reads as confetti. The sky and the hills move with the weather, and the
/// shader finishes the job.
enum Weather: String, CaseIterable, Identifiable {
    case rain
    case snow
    case wind
    case sunshine

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .wind: return "Wind"
        case .sunshine: return "Sunny"
        }
    }

    var symbol: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .snow: return "snowflake"
        case .wind: return "wind"
        case .sunshine: return "sun.max.fill"
        }
    }

    var sky: [Color] {
        switch self {
        case .rain:
            return [Color(red: 0.11, green: 0.14, blue: 0.22),
                    Color(red: 0.33, green: 0.39, blue: 0.48)]
        case .snow:
            return [Color(red: 0.16, green: 0.21, blue: 0.34),
                    Color(red: 0.61, green: 0.68, blue: 0.79)]
        case .wind:
            return [Color(red: 0.20, green: 0.31, blue: 0.40),
                    Color(red: 0.66, green: 0.74, blue: 0.74)]
        case .sunshine:
            return [Color(red: 0.16, green: 0.47, blue: 0.82),
                    Color(red: 0.92, green: 0.80, blue: 0.60)]
        }
    }

    /// Far hills first, nearest last.
    var hills: [Color] {
        switch self {
        case .rain:
            return [Color(red: 0.20, green: 0.26, blue: 0.34),
                    Color(red: 0.14, green: 0.19, blue: 0.26),
                    Color(red: 0.08, green: 0.12, blue: 0.17)]
        case .snow:
            return [Color(red: 0.72, green: 0.78, blue: 0.86),
                    Color(red: 0.55, green: 0.62, blue: 0.73),
                    Color(red: 0.36, green: 0.43, blue: 0.55)]
        case .wind:
            return [Color(red: 0.42, green: 0.50, blue: 0.47),
                    Color(red: 0.29, green: 0.37, blue: 0.35),
                    Color(red: 0.17, green: 0.24, blue: 0.24)]
        case .sunshine:
            return [Color(red: 0.42, green: 0.56, blue: 0.45),
                    Color(red: 0.26, green: 0.40, blue: 0.33),
                    Color(red: 0.14, green: 0.25, blue: 0.23)]
        }
    }
}

struct WeatherScene: View {

    @State private var weather: Weather = .rain
    @Namespace private var pickerNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            effect(on: landscape)
                .ignoresSafeArea()

            picker
                .padding(.bottom, 28)
        }
    }

    /// Applies the weather's shader to the landscape.
    ///
    /// Each branch returns a different type, which is what `@ViewBuilder` is
    /// for. Switching cases tears down one effect and builds the next, so each
    /// one starts from a clean clock.
    @ViewBuilder
    private func effect(on view: some View) -> some View {
        switch weather {
        case .rain:
            view.rainEffect(intensity: 0.85, wind: 0.28, speed: 1.1)
        case .snow:
            view.snowEffect(intensity: 0.8, wind: 0.35, speed: 1.0)
        case .wind:
            view.windEffect(strength: 15, direction: -6, streaks: 0.85)
        case .sunshine:
            view.sunshineEffect(origin: UnitPoint(x: 0.76, y: 0.2), warmth: 0.65, rays: 0.85, shimmer: 3.5)
        }
    }

    private var landscape: some View {
        GeometryReader { geometry in
            let height = geometry.size.height

            ZStack(alignment: .top) {
                LinearGradient(colors: weather.sky, startPoint: .top, endPoint: .bottom)

                // Three ridges at different heights and roughness. The nearest
                // is the roughest, which is the cheapest way to get depth out
                // of flat silhouettes.
                Hills(crest: 0.62, roughness: 0.6, phase: 0.4)
                    .fill(weather.hills[0])
                    .frame(height: height)

                Hills(crest: 0.74, roughness: 1.0, phase: 2.1)
                    .fill(weather.hills[1])
                    .frame(height: height)

                Hills(crest: 0.86, roughness: 1.5, phase: 4.7)
                    .fill(weather.hills[2])
                    .frame(height: height)

                title
                    .padding(.top, 72)
                    .frame(maxWidth: .infinity)
            }
            .animation(.easeInOut(duration: 0.6), value: weather)
        }
    }

    private var title: some View {
        VStack(spacing: 6) {
            Text(weather.title.uppercased())
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .kerning(6)
                .foregroundStyle(.white.opacity(0.92))

            Text("Metal shader")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .kerning(3)
                .foregroundStyle(.white.opacity(0.6))
        }
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
    }

    private var picker: some View {
        HStack(spacing: 4) {
            ForEach(Weather.allCases) { option in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        weather = option
                    }
                } label: {
                    Image(systemName: option.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 58, height: 44)
                        .foregroundStyle(weather == option ? .black : .white)
                        .background {
                            if weather == option {
                                Capsule()
                                    .fill(.white)
                                    .matchedGeometryEffect(id: "selection", in: pickerNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(option.title)
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 18, y: 8)
    }
}

/// A band of rolling hills filling everything below its ridge.
///
/// Two sine waves at different rates make a ridge that does not visibly
/// repeat across the width of a phone.
private struct Hills: Shape {

    /// Where the ridge sits, as a fraction of the height.
    var crest: CGFloat

    /// How tall the hills are.
    var roughness: CGFloat

    /// Slides the ridge sideways, so stacked bands do not line up.
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let baseline = rect.height * crest
        let steps = 64

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))

        for step in 0...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let x = rect.minX + t * rect.width
            let y = baseline
                - sin(t * .pi * 3.0 + phase) * rect.height * 0.055 * roughness
                - sin(t * .pi * 7.4 + phase * 1.7) * rect.height * 0.022 * roughness

            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

#Preview("Weather") {
    WeatherScene()
}
