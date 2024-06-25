//
//  WaterDropScene.swift
//  visualexperiemnt
//
//  Created by Victoria Petrova on 25/06/2024.
import SwiftUI

struct WaterDropScene: View {
    @State private var counter: Int = 0
    @State private var dropPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width/2, y: 50)
    private var targetWaterDropPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width/2, y: 600)
    @State private var waterHeight: CGFloat = 200.0

    var body: some View {
        ZStack {
            tiles
                .ignoresSafeArea()
            showerHead
            
            // Falling water drop
            Raindrop()
                .frame(width: 20, height: 40)
                .position(dropPosition)
                .onAppear {
                    startFalling()
                }
            
            // Water surface
            ZStack {
                Rectangle()
                    .fill(Color.white)
                Rectangle()
                    .fill(Color.blue.opacity(0.7))
            }
            .frame(width: UIScreen.main.bounds.width+20, height: waterHeight)
            .position(x: targetWaterDropPosition.x, y: targetWaterDropPosition.y + waterHeight/2 + 20)
            .modifier(RippleEffect(at: targetWaterDropPosition, trigger: counter, amplitude: -12, frequency: 15, decay: 8, speed: 800))
        }
    }
    
    var showerHead: some View {
        Image(systemName: "shower.sidejet.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .rotationEffect(Angle(degrees: 90))
            .zIndex(1.0)
            .position(x: UIScreen.main.bounds.width/2, y: 50)
            .foregroundStyle(.black, .blue, .blue)
            .symbolEffect(.variableColor.cumulative)
            .symbolEffect(.variableColor.cumulative, options: .speed(0.03))
    }
    
    var tiles: some View {
        GeometryReader { geometry in
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<100) { _ in
                    Rectangle()
                        .fill(.blue.opacity(0.06))
                        .frame(height: geometry.size.width / 5 - 8)
                        .aspectRatio(1, contentMode: .fill)
                }
            }
            .padding(8)
        }
    }

    func startFalling() {
        let duration = 2.0
        withAnimation(Animation.easeIn(duration: duration)) {
            dropPosition = targetWaterDropPosition
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration ) {
            counter += 1
            // Reset the drop position and start again
            dropPosition = CGPoint(x: targetWaterDropPosition.x, y: 50)
            startFalling()
        }
    }
}

#Preview {
    WaterDropScene()
}
