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
    
    // MARK: - Users
    func observeUser(uid: String, onChange: @escaping (AppUser?) -> Void) -> ListenerRegistration {
        return fs.users.document(uid).addSnapshotListener { snap, _ in
            onChange(snap.flatMap { AppUser(doc: $0) })
        }
    }
    
    func loadUser(uid: String) async throws -> AppUser? {
        let snap = try await fs.users.document(uid).getDocument()
        return AppUser(doc: snap)
    }
    
    func createUser(_ user: AppUser, uid: String) async throws {
        let data = user.asData
        // These two are required by your rules:
        guard !user.username.isEmpty else { throw NSError(domain: "UserRepository", code: 0, userInfo: [NSLocalizedDescriptionKey:"username required"]) }
        guard !user.role.isEmpty else { throw NSError(domain: "UserRepository", code: 0, userInfo: [NSLocalizedDescriptionKey:"role required"]) }
        try await fs.users.document(uid).setData(data, merge: false)
    }
    
    func updateUser(_ user: AppUser, uid: String) async throws {
        try await fs.users.document(uid).setData(user.asData, merge: true)
    }
    
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
