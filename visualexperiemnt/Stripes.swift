//
//  Stripes.swift
//  visualexperiemnt
//
//  Created by Victoria Petrova on 21/06/2024.
//

/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example of using the `Stripes` shader as a `ShapeStyle`.
*/

import SwiftUI

#Preview("Stripes") {
    
    VStack {
        let fill = ShaderLibrary.Stripes(
            .float(20),
            .colorArray([
                .red, .orange, .yellow, .green, .blue, .indigo
            ])
        )

        Circle().fill(fill)
    }
    .padding()
}
