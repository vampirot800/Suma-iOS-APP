//
//  UserRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import Foundation
import FirebaseFirestore

final class UserRepository {
    private let fs = FirebaseService.shared

    func observeUser(uid: String,
                     onChange: @escaping (AppUser?) -> Void) -> ListenerRegistration {
        fs.users.document(uid).addSnapshotListener { snap, _ in
            let user = try? snap?.data(as: AppUser.self)
            onChange(user)
        }
    }

    func updateProfile(uid: String, displayName: String?, bio: String?, tags: [String]?) async throws {
        var data: [String:Any] = [:]
        if let displayName { data["displayName"] = displayName }
        if let bio { data["bio"] = bio }
        if let tags { data["searchable"] = tags }
        try await fs.users.document(uid).setData(data, merge: true)
    }
}
