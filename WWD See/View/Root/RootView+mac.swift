//
//  RootView+mac.swift
//  WWD See
//
//  Created by Michael Skiba on 25/03/2025.
//

#if os(macOS)
import SwiftUI
import WWDCData
import IssueReporting

struct RootView: View {
    @State private var coordinator = RootCoordinator()
    var body: some View {
        NavigationSplitView {
            if let event = coordinator.selectedEvent {
                TopicPicker(
                    event: event,
                    selection: $coordinator.selectedTopic
                )
            }
        } detail: {
            if let event = coordinator.selectedEvent {
                VideosView(event: event, topic: coordinator.selectedTopic)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                EventPicker(
                    events: coordinator.events,
                    selection: $coordinator.selectedEvent
                )
            }
        }
        .task {
            do {
                try await coordinator.loadData()
            } catch {
                reportIssue(error)
            }
        }
    }
}

#Preview {
    RootView()
}
#endif
