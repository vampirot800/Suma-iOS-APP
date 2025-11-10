//
//  PortfolioRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 10/11/25.
//


//  PortfolioRepository.swift
//  FIT3178-App

import Foundation
import FirebaseFirestore

final class PortfolioRepository {
    private let fs = FirebaseService.shared

    func observePortfolioItems(of userId: String,
                               onChange: @escaping ([PortfolioItem]) -> Void)
    -> ListenerRegistration {
        fs.portfolios(uid: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { qs, _ in
                let items = qs?.documents.compactMap { PortfolioItem(doc: $0) } ?? []
                onChange(items)
            }
    }
}
