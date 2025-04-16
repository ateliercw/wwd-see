//
//  RootView.swift
//  WWD See
//
//  Created by Michael Skiba on 27/03/2025.
//

import SwiftUI
import WWDCData
import IssueReporting

struct RootView: View {
    @State private var coordinator = RootCoordinator()
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar

    var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
            topicsList
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        EventPicker(events: coordinator.events, selection: $coordinator.selectedEvent)
                    }
                }
                .navigationTitle("WWD See")
        } detail: {
            NavigationStack {
                if let event = coordinator.selectedEvent {
                    VideosView(event: event, topic: coordinator.selectedTopic)
                } else {
                    ContentUnavailableView("Select a topic to view videos.", systemImage: "play.display")
                }
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

    @ViewBuilder
    private var topicsList: some View {
        if let event = coordinator.selectedEvent {
            TopicList(event: event, selectedTopic: $coordinator.selectedTopic)
        } else {
            ContentUnavailableView("Select an event to get started", systemImage: "play.display")
        }
    }
}
#Preview {
    RootView()
}
