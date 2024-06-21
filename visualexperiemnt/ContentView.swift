//
//  ContentView.swift
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/06/2024.
//

/*
See the LICENSE.txt file for this sample’s licensing information.
*/

import SwiftUI

struct ContentView: View {

    @State var counter: Int = 0
    @State var origin: CGPoint = .zero
    
    var body: some View {
        VStack {
            let fill = ShaderLibrary.Stripes(
                .float(12),
                .colorArray([
                    .red, .orange, .yellow, .green, .blue, .indigo
                ])
            )

            Circle().fill(fill)
                .modifier(RippleEffect(at: origin, trigger: counter))
                .onTapGesture { location in
                    origin = location
                    counter += 1
                }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
