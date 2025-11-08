//
//  AuthService.swift
//  FIT3178-App
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

    // MARK: - Sign Up
    func signUp(email: String,
                password: String,
                displayName: String,
                role: String,
                bio: String,
                tags: [String]) async throws {
        let result = try await fs.auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        // Set display name in Auth
        let change = result.user.createProfileChangeRequest()
        change.displayName = displayName
        try await change.commitChanges()

        // Create user doc with an empty photoURL so your app can read it safely
        let appUser = AppUser(
            id: uid,
            displayName: displayName,
            username: email,
            role: role,
            bio: bio,
            photoURL: nil,            // stored as missing/empty in Firestore (see asData)
            tags: tags,
            searchable: tags
        )
        try await fs.users.document(uid).setData(appUser.asData, merge: true)
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        _ = try await fs.auth.signIn(withEmail: email, password: password)
    }

    func signInAndEnsureUserDoc(email: String,
                                password: String,
                                displayNameFallback: String = "New User") async throws {
        try await signIn(email: email, password: password)
        try await ensureUserDoc(displayNameFallback: displayNameFallback)
    }

    func signOut() throws { try fs.auth.signOut() }

    // MARK: - Profile helpers
    func loadCurrentUser() async throws -> AppUser? {
        guard let uid = currentUserId else { return nil }
        let snap = try await fs.users.document(uid).getDocument()
        return AppUser(doc: snap)
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
                photoURL: nil,         // will serialize to missing/empty
                tags: [],
                searchable: []
            )
            try await ref.setData(user.asData, merge: true)
        }
    }

    // MARK: - Photo URL sync (Auth + Firestore)
    /// Call after uploading an avatar to Storage and obtaining a downloadURL.
    func setUserPhotoURL(_ url: URL) async throws {
        guard let uid = currentUserId, let user = fs.auth.currentUser else { throw AuthError.missingUID }

        // 1) Update FirebaseAuth profile
        let change = user.createProfileChangeRequest()
        change.photoURL = url
        try await change.commitChanges()

        // 2) Mirror in Firestore
        try await fs.users.document(uid).setData(["photoURL": url.absoluteString], merge: true)
    }
}
