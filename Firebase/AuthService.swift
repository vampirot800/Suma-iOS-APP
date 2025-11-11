//
//  AuthService.swift
//  FIT3178-App
//
//  Centralized wrapper around FirebaseAuth + Firestore user documents.
//  Provides sign up / sign in, profile initialization, and photo URL sync.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Errors specific to AuthService flows.
enum AuthError: Error { case missingUID }

/// Singleton service managing authentication and basic profile persistence.
final class AuthService {
    static let shared = AuthService()
    private init() {}

    // MARK: - Dependencies
    private let fs = FirebaseService.shared

    /// Currently signed-in user id, if any.
    var currentUserId: String? { fs.auth.currentUser?.uid }

    // MARK: - Sign Up

    /// Creates a FirebaseAuth user and initializes their Firestore profile document.
    /// - Parameters:
    ///   - email: User email.
    ///   - password: Plain text password.
    ///   - displayName: Display name to set in Auth and Firestore.
    ///   - role: Initial role string (e.g., "media creator").
    ///   - bio: Initial short bio.
    ///   - tags: Initial tags; will also populate a lowercased `searchable` array.
    func signUp(
        email: String,
        password: String,
        displayName: String,
        role: String,
        bio: String,
        tags: [String]
    ) async throws {
        let result = try await fs.auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        // Set display name in Auth profile
        let change = result.user.createProfileChangeRequest()
        change.displayName = displayName
        try await change.commitChanges()

        let normalized = tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let searchable = normalized.map { $0.lowercased() }

        // Initialize user document (photoURL omitted until uploaded)
        let appUser = AppUser(
            id: uid,
            displayName: displayName,
            username: email,
            role: role,
            bio: bio,
            photoURL: nil,
            tags: normalized,
            searchable: searchable
        )
        try await fs.users.document(uid).setData(appUser.asData, merge: true)
    }

    // MARK: - Sign In / Out

    /// Signs in using FirebaseAuth email/password.
    func signIn(email: String, password: String) async throws {
        _ = try await fs.auth.signIn(withEmail: email, password: password)
    }

    /// Signs in and ensures the user's Firestore profile exists.
    func signInAndEnsureUserDoc(
        email: String,
        password: String,
        displayNameFallback: String = "New User"
    ) async throws {
        try await signIn(email: email, password: password)
        try await ensureUserDoc(displayNameFallback: displayNameFallback)
    }

    /// Signs out current user.
    func signOut() throws { try fs.auth.signOut() }

    // MARK: - Profile Helpers

    /// Loads the current user's profile document as `AppUser`.
    func loadCurrentUser() async throws -> AppUser? {
        guard let uid = currentUserId else { return nil }
        let snap = try await fs.users.document(uid).getDocument()
        return AppUser(doc: snap)
    }

    /// Ensures a Firestore user doc exists; creates a minimal one if missing.
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
            try await ref.setData(user.asData, merge: true)
        }
    }

    // MARK: - Photo URL Sync

    /// Sets the FirebaseAuth `photoURL` and mirrors it into Firestore.
    func setUserPhotoURL(_ url: URL) async throws {
        guard let uid = currentUserId, let user = fs.auth.currentUser else {
            throw AuthError.missingUID
        }

        // Update FirebaseAuth profile
        let change = user.createProfileChangeRequest()
        change.photoURL = url
        try await change.commitChanges()

        // Mirror to Firestore
        try await fs.users.document(uid).setData(["photoURL": url.absoluteString], merge: true)
    }
}
