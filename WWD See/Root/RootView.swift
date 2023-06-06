//
//  ContentView.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]

    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    NavigationLink {
                        CategoryView(category: category)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(category.name)
                            Text("\(category.viewedCount) / \(category.videos.count)")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("WWD See")
        }
        .task {
            guard categories.isEmpty else { return }
            do {
                try modelContext.loadStoredCategories()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}

extension Category {
    var viewedCount: Int {
        videos.filter(\.watched).count
    }
}

#Preview {
    RootView()
        .modelContainer(for: Category.self, inMemory: true)
}
