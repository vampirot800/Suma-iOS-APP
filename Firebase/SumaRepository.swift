//
//  SumaRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//
//  Description:
//  CRUD and observation helpers for `Suma` items in `/sumas`.
//

import Foundation
import FirebaseFirestore

/// Repository for Suma content (discovery/feed items).
final class SumaRepository {
    private let fs = FirebaseService.shared

    /// Observes all Sumas owned by `uid`, ordered by `date` (desc).
    func observeMySumas(
        uid: String,
        onChange: @escaping ([Suma]) -> Void
    ) -> ListenerRegistration {
        fs.sumas
            .whereField("ownerId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .addSnapshotListener { qs, _ in
                let items = qs?.documents.compactMap { Suma(doc: $0) } ?? []
                onChange(items)
            }
    }

    /// Adds a new Suma document.
    func addSuma(_ s: Suma) async throws {
        try await fs.sumas.addDocument(data: s.asData)
    }

    /// Deletes a Suma by document id.
    func deleteSuma(id: String) async throws {
        try await fs.sumas.document(id).delete()
    }
}
