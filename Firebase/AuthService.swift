//
//  AuthService.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AuthError: Error { case missingUID }

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let fs = FirebaseService.shared

    var currentUserId: String? { fs.auth.currentUser?.uid }

    // MARK: - Sign Up (Email/Password)
    func signUp(email: String,
                password: String,
                displayName: String,
                role: String,
                bio: String,
                tags: [String]) async throws {
        let result = try await fs.auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        // (Optional) also set the FirebaseAuth displayName so it's available in Auth
        let change = result.user.createProfileChangeRequest()
        change.displayName = displayName
        try await change.commitChanges()

        let appUser = AppUser(
            id: uid,
            displayName: displayName,
            username: email, // or derive from displayName if your model expects a separate username
            role: role,
            bio: bio,
            photoURL: nil,
            tags: tags,
            searchable: tags
        )

        try fs.users.document(uid).setData(from: appUser, merge: true)
    }

    // MARK: - Sign In (Email/Password)
    func signIn(email: String, password: String) async throws {
        _ = try await fs.auth.signIn(withEmail: email, password: password)
    }

    /// Convenience: sign in and ensure there is a Firestore user doc (first login support)
    func signInAndEnsureUserDoc(email: String,
                                password: String,
                                displayNameFallback: String = "New User") async throws {
        try await signIn(email: email, password: password)
        try await ensureUserDoc(displayNameFallback: displayNameFallback)
    }

    func signOut() throws {
        try fs.auth.signOut()
    }

    // MARK: - Profile helpers
    func loadCurrentUser() async throws -> AppUser? {
        guard let uid = currentUserId else { return nil }
        let snap = try await fs.users.document(uid).getDocument()
        return try snap.data(as: AppUser.self)
    }

    func ensureUserDoc(displayNameFallback: String = "New User") async throws {
        guard let uid = currentUserId else { return }
        let ref = fs.users.document(uid)
        if try await !ref.getDocument().exists {
            let user = AppUser(
                id: uid,
                displayName: displayNameFallback,
                username: fs.auth.currentUser?.email ?? uid,
                role: "media creator",
                bio: "",
                photoURL: nil,
                tags: [],
                searchable: []
            )
            try ref.setData(from: user, merge: true)
        }
    }
}

