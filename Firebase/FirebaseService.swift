//
//  FirebaseService.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    let auth = Auth.auth()
    let db = Firestore.firestore()

    // Collections
    var users: CollectionReference { db.collection("users") }
    var chats: CollectionReference { db.collection("chats") }
    var sumas: CollectionReference { db.collection("sumas") }
}
