//
//  UserRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//
//  Description:
//  User profile reads/writes and search utilities on `/users` collection.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Repository for user profiles.
final class UserRepository {
    private let fs = FirebaseService.shared

    // MARK: - Users

    /// Observes a user document and emits `AppUser?` on change.
    func observeUser(uid: String, onChange: @escaping (AppUser?) -> Void) -> ListenerRegistration {
        fs.users.document(uid).addSnapshotListener { snap, _ in
            onChange(snap.flatMap { AppUser(doc: $0) })
        }
    }

    /// Loads a single user document once.
    func loadUser(uid: String) async throws -> AppUser? {
        let snap = try await fs.users.document(uid).getDocument()
        return AppUser(doc: snap)
    }

    /// Creates a user document (non-merge) with basic validation.
    /// - Note: Your Firestore rules require `username` and `role`.
    func createUser(_ user: AppUser, uid: String) async throws {
        let data = user.asData
        guard !user.username.isEmpty else {
            throw NSError(domain: "UserRepository", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "username required"])
        }
        guard !user.role.isEmpty else {
            throw NSError(domain: "UserRepository", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "role required"])
        }
        try await fs.users.document(uid).setData(data, merge: false)
    }

    /// Updates a user document (merge semantics).
    func updateUser(_ user: AppUser, uid: String) async throws {
        try await fs.users.document(uid).setData(user.asData, merge: true)
    }

    /// Case-insensitive token search using the `searchable` array.
    /// - Parameters:
    ///   - token: Raw user-entered search query; will be trimmed and lowercased.
    ///   - uid: Current user's uid to exclude from results.
    ///   - limit: Max results (default 25).
    func searchUsers(token: String, excluding uid: String, limit: Int = 25) async throws -> [AppUser] {
        let q = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }

        let snap = try await fs.users
            .whereField("searchable", arrayContains: q)
            .limit(to: limit)
            .getDocuments()

        return snap.documents
            .compactMap { AppUser(doc: $0) }
            .filter { $0.id != uid }
    }
}
