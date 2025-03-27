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
        Unwrapping($selection) { event in
            Picker(selection: event) {
                ForEach(events) { event in
                    Text(event.name)
                        .tag(event)
                }
            } label: {
                EmptyView()
            }
        }
    }
}
