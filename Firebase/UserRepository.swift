//
//  UserRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class UserRepository {
    private let fs = FirebaseService.shared

    func observeUser(uid: String, onChange: @escaping (AppUser?) -> Void) -> ListenerRegistration {
        fs.users.document(uid).addSnapshotListener { snap, _ in
            guard let snap else { onChange(nil); return }
            onChange(AppUser(doc: snap))
        }
    }

    func updateProfile(uid: String, displayName: String?, bio: String?, tags: [String]?) async throws {
        var data: [String:Any] = [:]
        if let displayName { data["displayName"] = displayName }
        if let bio { data["bio"] = bio }
        if let tags {
            data["tags"] = tags
            data["searchable"] = tags.map { $0.lowercased() }
        }
        try await fs.users.document(uid).setData(data, merge: true)
    }
}

// MARK: - Search helpers
extension UserRepository {
    func listOthers(excluding uid: String, limit: Int = 25) async throws -> [AppUser] {
        let snap = try await FirebaseService.shared.users
            .whereField(FieldPath.documentID(), isNotEqualTo: uid)
            .limit(to: limit)
            .getDocuments()
        return snap.documents.compactMap { AppUser(doc: $0) }
    }

    func searchUsers(token: String, excluding uid: String, limit: Int = 25) async throws -> [AppUser] {
        let q = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        let snap = try await FirebaseService.shared.users
            .whereField("searchable", arrayContains: q)
            .limit(to: limit)
            .getDocuments()
        return snap.documents
            .compactMap { AppUser(doc: $0) }
            .filter { $0.id != uid }
    }
}
