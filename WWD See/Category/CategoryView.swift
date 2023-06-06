//
//  CategoryView.swift
//  WWD See
//
//  Created by Michael Skiba on 06/06/2023.
//

import SwiftUI
import SwiftData

struct CategoryView: View {
    @Environment(\.modelContext) private var modelContext
    var category: Category

    var body: some View {
        List {
            ForEach(category.videos) { video in
                Text(video.name)
            }
        }
        .navigationTitle(category.name)
    }
}

#Preview {
//    CategoryView()
}
