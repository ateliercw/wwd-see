//
//  FilterView.swift
//  WWD See
//
//  Created by Michael Skiba on 08/06/2023.
//

import SwiftUI
import SwiftData

struct FilterView: View {
    @Query(sort: \Category.name) private var categories: [Category]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(categories) { category in
                        Toggle(category.name, isOn: Binding {
                            category.isVisible
                        } set: {
                            category.isVisible = $0
                        })
                        .multilineTextAlignment(.leading)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Button("Show all") {
                        for category in categories {
                            category.isVisible = true
                        }
                    }
                    Divider()
                    Button("Hide all") {
                        for category in categories {
                            category.isVisible = false
                        }

                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 4)
            }
            .navigationTitle("Showing")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Done", systemImage: "xmark")
                    }
                }
            }
        }
    }
}
