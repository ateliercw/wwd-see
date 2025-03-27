//
//  Unwrapping.swift
//  WWD See
//
//  Created by Michael Skiba on 26/03/2025.
//

import SwiftUI

struct Unwrapping<Variable, Content: View>: View {
    @Binding var value: Variable?
    @ViewBuilder var content: (Binding<Variable>) -> Content

    init(_ value: Binding<Variable?>, content: @escaping (Binding<Variable>) -> Content) {
        self._value = value
        self.content = content
    }

    var body: some View {
        if let value {
            content(.init(get: { value }, set: { self.value = $0 }))
        }
    }
}
