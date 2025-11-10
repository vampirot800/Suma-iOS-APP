//
//  FirebaseService.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    // MARK: - SDK singletons
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()

    // MARK: - Top-level collections
    var users: CollectionReference { db.collection("users") }
    var chats: CollectionReference { db.collection("chats") }
    var sumas: CollectionReference { db.collection("sumas") }

    // MARK: - Subcollections
    func portfolios(uid: String) -> CollectionReference {
        users.document(uid).collection("portfolios")
    }

    // MARK: - Storage roots
    var avatarsRoot: StorageReference { storage.reference().child("avatars") }
    func userFiles(uid: String) -> StorageReference {
        storage.reference().child("userFiles").child(uid)
    }
}
