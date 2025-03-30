//
//  RootView.swift
//  WWD See
//
//  Created by Michael Skiba on 27/03/2025.
//

#if !os(macOS)
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
                .navigationTitle("WWD See")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        EventPicker(events: coordinator.events, selection: $coordinator.selectedEvent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial, ignoresSafeAreaEdges: .top)
                    }
                }
            }
        } detail: {
            if let event = coordinator.selectedEvent {
                VideosView(event: event, topic: coordinator.selectedTopic)
                    .navigationTitle(coordinator.selectedTopic?.name ?? "All Videos")
                    .toolbarRole(.editor)
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
