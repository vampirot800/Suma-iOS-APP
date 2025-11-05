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

    func observeMySumas(uid: String,
                        onChange: @escaping ([Suma]) -> Void) -> ListenerRegistration {
        fs.sumas
            .whereField("ownerId", isEqualTo: uid)
            .order(by: "date", descending: true)
            .addSnapshotListener { qs, _ in
                let items = qs?.documents.compactMap { Suma(doc: $0) } ?? []
                onChange(items)
            }
    }

    func addSuma(_ s: Suma) async throws {
        try await fs.sumas.addDocument(data: s.asData)
    }

    func deleteSuma(id: String) async throws {
        try await fs.sumas.document(id).delete()
    }
}
