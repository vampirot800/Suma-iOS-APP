//
//  IdeaArticle.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 11/11/25.
//

import Foundation

/// Represents a trending article or discussion item displayed under the “Ideas” tab.
struct IdeaArticle: Identifiable {

    // MARK: - Properties

    var id = UUID().uuidString
    let title: String
    let points: Int
    let author: String
    let date: Date
    let urlString: String

    /// Computed property that safely converts `urlString` into a `URL`.
    var url: URL? { URL(string: urlString) }

    // MARK: - Mock Data

    /// Provides a set of example articles for UI testing and previewing.
    static func fakeData() -> [IdeaArticle] {
        let now = Date()
        return [
            .init(
                title: "SwiftUI vs UIKit in 2025: Tradeoffs in large teams",
                points: 421,
                author: "rbatiste",
                date: now.addingTimeInterval(-3600 * 3),
                urlString: "https://example.com/swiftui-uikit-2025"
            ),
            .init(
                title: "Optimizing Firestore reads with structured subcollections",
                points: 297,
                author: "dataplane",
                date: now.addingTimeInterval(-3600 * 8),
                urlString: "https://example.com/firestore-reads"
            ),
            .init(
                title: "Why product/market fit is a moving target",
                points: 512,
                author: "pmcraft",
                date: now.addingTimeInterval(-3600 * 22),
                urlString: "https://example.com/pmf-moving-target"
            ),
            .init(
                title: "Compositional Layout tips for fast, smooth iOS feeds",
                points: 188,
                author: "iosdan",
                date: now.addingTimeInterval(-3600 * 30),
                urlString: "https://example.com/compositional-layout-tips"
            ),
            .init(
                title: "Algolia HN API mapping to your view models",
                points: 231,
                author: "searchdev",
                date: now.addingTimeInterval(-3600 * 48),
                urlString: "https://hn.algolia.com/api"
            ),
            .init(
                title: "From prototype to scale: carving boundaries in your codebase",
                points: 344,
                author: "archi_labs",
                date: now.addingTimeInterval(-3600 * 54),
                urlString: "https://example.com/boundaries"
            )
        ]
    }
}
