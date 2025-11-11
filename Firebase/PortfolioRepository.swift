//
//  PortfolioRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//
//  Description:
//  Read-only convenience repository for observing a user's portfolio items
//  under `/users/{uid}/portfolios`, ordered by `createdAt` (desc).
//

import Foundation
import FirebaseFirestore

/// Repository for portfolio items (observe-only).
final class PortfolioRepository {
    private let fs = FirebaseService.shared

    /// Live-updates a user's portfolio list.
    /// - Parameters:
    ///   - userId: Target user id (document id under `/users`).
    ///   - onChange: Callback with parsed `PortfolioItem` array.
    /// - Returns: A Firestore listener registration.
    func observePortfolioItems(
        of userId: String,
        onChange: @escaping ([PortfolioItem]) -> Void
    ) -> ListenerRegistration {
        fs.portfolios(uid: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { qs, _ in
                let items = qs?.documents.compactMap { PortfolioItem(doc: $0) } ?? []
                onChange(items)
            }
    }
}
