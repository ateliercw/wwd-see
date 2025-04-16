//
//  EventPicker.swift
//  WWD See
//
//  Created by Michael Skiba on 26/03/2025.
//

import SwiftUI
import WWDCData

struct EventPicker: View {
    var events: [EventRecord]
    @Binding var selection: EventRecord?

    var body: some View {
        Picker(selection: $selection) {
            ForEach(events) { event in
                Text(event.name)
                    .tag(Optional(event))
            }
        } label: {
            EmptyView()
        }
    }
}
