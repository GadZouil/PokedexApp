//
//  Theme.swift
//  PokedexApp
//
//  Created by Ethan LEGROS on 2/17/25.
//

import SwiftUI

struct Theme {
    static let primaryColor = Color.red
    static let secondaryColor = Color.blue
    static let backgroundGradient = LinearGradient(
        colors: [Color.black.opacity(0.85), Color.red.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
}
