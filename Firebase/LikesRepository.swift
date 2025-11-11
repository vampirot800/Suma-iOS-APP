//
//  LikesRepository.swift
//  FIT3178-App
//
//  Manages "likes" between users and creates a direct chat on mutual like.
//  Contains read/write helpers and a listener for my liked IDs.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Repository for like-related operations and mutual-match chat creation.
final class LikesRepository {

    // MARK: - Dependencies
    private let fs = FirebaseService.shared
    private let auth = Auth.auth()

    // MARK: - Observing

    /// Observes my liked user IDs (documents under `/users/{me}/likes/*`).
    /// - Returns: An optional listener registration (nil if not signed in).
    func observeMyLikedIDs(onChange: @escaping (Set<String>) -> Void) -> ListenerRegistration? {
        guard let uid = auth.currentUser?.uid else {
            print("❌ [LikesRepo] observeMyLikedIDs: no signed-in user.")
            return nil
        }

        let ref = fs.users.document(uid).collection("likes")
        print("🔎 [LikesRepo] Listening to \(ref.path)")

        return ref.addSnapshotListener { qs, err in
            if let err = err {
                print("❌ [LikesRepo] likes snapshot error:", err)
                return
            }
            let ids = Set(qs?.documents.map { $0.documentID } ?? [])
            print("📥 [LikesRepo] likes snapshot → \(ids.count) liked IDs:", Array(ids))
            onChange(ids)
        }
    }

    // MARK: - Write

    /// Writes a "like" for `likedUid`. If mutual, ensures a direct chat exists.
    func like(user likedUid: String) async {
        guard let myUid = auth.currentUser?.uid else {
            print("❌ [LikesRepo] like(\(likedUid)) aborted: no signed-in user.")
            return
        }

        let doc = fs.users.document(myUid).collection("likes").document(likedUid)
        print("➡️  [LikesRepo] Try write like: \(myUid) → \(likedUid) at \(doc.path)")

        do {
            try await doc.setData([
                "by": myUid,
                "target": likedUid,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
            print("✅ [LikesRepo] Like saved OK at \(doc.path)")

            // Optional: verify we can read it back (useful for rule debugging)
            do {
                let snap = try await doc.getDocument()
                print("🧪 [LikesRepo] Read-back exists?", snap.exists, "data:", snap.data() ?? [:])
            } catch {
                let ns = error as NSError
                print("❌ [LikesRepo] Read-back FAILED (\(ns.domain)/\(ns.code)):", ns.localizedDescription)
            }

            // Mutual check: did they like me?
            let otherDoc = fs.users.document(likedUid).collection("likes").document(myUid)
            let theyLikedMe = try await otherDoc.getDocument().exists
            print("🔁 [LikesRepo] Mutual check \(otherDoc.path) exists? \(theyLikedMe)")

            if theyLikedMe {
                try await ensureDirectChat(between: myUid, and: likedUid)
            }
        } catch {
            let ns = error as NSError
            print("❌ [LikesRepo] Like write FAILED (\(ns.domain) / code \(ns.code)):", ns.localizedDescription)
            if ns.code == 7 {
                print("🛡️  [LikesRepo] Permission denied. Check rules for /users/{uid}/likes/{otherUid} create.")
            }
        }
    }

    // MARK: - Private Helpers

    /// Ensures a direct chat exists between two users; creates one if not.
    private func ensureDirectChat(between a: String, and b: String) async throws {
        print("💬 [LikesRepo] Ensure direct chat between \(a) & \(b)")

        let qs = try await fs.chats
            .whereField("participants", arrayContains: a)
            .getDocuments()

        let existing = qs.documents.first { doc in
            let parts = (doc["participants"] as? [String]) ?? []
            return parts.count == 2 && Set(parts) == Set([a, b])
        }

        if let doc = existing {
            print("ℹ️  [LikesRepo] Chat already exists:", doc.reference.path)
            return
        }

        let data: [String: Any] = [
            "participants": [a, b],
            "isgroupchat": false,
            "lastmessage": "",
            "lastmessagetime": FieldValue.serverTimestamp(),
            "participantphotos": [:]
        ]
        let ref = try await fs.chats.addDocument(data: data)
        print("✅ [LikesRepo] Chat created:", ref.path)
    }
}
