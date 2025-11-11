//
//  FirebaseService.swift
//  FIT3178-App
//
//  Thin façade holding Firebase singletons, collection roots, and convenience paths.
//  Used by repositories/services to avoid scattering SDK calls.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Provides shared Firebase SDK instances and common collection/storage references.
final class FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    // MARK: - SDK Singletons
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()

    // MARK: - Top-level Collections
    var users: CollectionReference { db.collection("users") }
    var chats: CollectionReference { db.collection("chats") }
    var sumas: CollectionReference { db.collection("sumas") }

    // MARK: - Subcollections

    /// Convenience accessor for `users/{uid}/portfolios`.
    func portfolios(uid: String) -> CollectionReference {
        users.document(uid).collection("portfolios")
    }

    // MARK: - Storage Roots

    /// Storage root for user avatars.
    var avatarsRoot: StorageReference { storage.reference().child("avatars") }

    /// Storage root for user files (per-user folder).
    func userFiles(uid: String) -> StorageReference {
        storage.reference().child("userFiles").child(uid)
    }
}
