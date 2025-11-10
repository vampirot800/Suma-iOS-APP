//
//  SumaRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import Foundation
import FirebaseFirestore

final class SumaRepository {
    private let fs = FirebaseService.shared

    // Live query for a user's sumas, ordered by date desc
    func observeMySumas(uid: String,
                        onChange: @escaping ([Suma]) -> Void) -> ListenerRegistration {
        return fs.sumas
            .whereField("ownerId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .addSnapshotListener { qs, _ in
                let items = qs?.documents.compactMap { Suma(doc: $0) } ?? []
                onChange(items)
            }
    }

    // Create (or upsert) a Suma
    func addSuma(_ s: Suma) async throws {
        try await fs.sumas.addDocument(data: s.asData)
    }

    // Delete by document id
    func deleteSuma(id: String) async throws {
        try await fs.sumas.document(id).delete()
    }
}
