//
//  ChatRepository.swift
//  FIT3178-App
//
//  Repository for creating/observing 1:1 chats and messages.
//  Keeps query logic out of view controllers.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Repository for chat threads and messages.
final class ChatRepository {
    static let shared = ChatRepository()
    private init() {}

    // MARK: - Dependencies
    private let fs = FirebaseService.shared

    // MARK: - Threads

    /// Returns an existing 1:1 thread with `otherUid`, or creates one.
    func ensureDirectThread(with otherUid: String) async throws -> String {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "Auth",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Not signed in"]
            )
        }

        // Check existing chats that include me and are 1:1
        let snap = try await fs.chats
            .whereField("isgroupchat", isEqualTo: false)
            .whereField("participants", arrayContains: currentUid)
            .getDocuments()

        if let doc = snap.documents.first(where: {
            let arr = $0["participants"] as? [String]
            return arr?.sorted() == [currentUid, otherUid].sorted()
        }) {
            return doc.documentID
        }

        // Create a new thread
        let data: [String: Any] = [
            "participants": [currentUid, otherUid],
            "isgroupchat": false,
            "lastmessage": "",
            "lastmessagetime": FieldValue.serverTimestamp(),
            "participantphotos": [String: String]()
        ]
        let ref = try await fs.chats.addDocument(data: data)
        return ref.documentID
    }

    /// Observes all threads for a given `uid`, ordered by last message time.
    func observeThreads(
        for uid: String,
        onChange: @escaping ([ChatThread]) -> Void
    ) -> ListenerRegistration {
        fs.chats
            .whereField("participants", arrayContains: uid)
            .order(by: "lastmessagetime", descending: true)
            .addSnapshotListener { qs, _ in
                let threads = qs?.documents.compactMap { ChatThread(doc: $0) } ?? []
                onChange(threads)
            }
    }

    /// Observes messages for a conversation.
    func observeMessages(
        chatId: String,
        onChange: @escaping ([Message]) -> Void
    ) -> ListenerRegistration {
        fs.chats.document(chatId)
            .collection("messages")
            .order(by: "createdat")
            .addSnapshotListener { qs, _ in
                let msgs = qs?.documents.compactMap { Message(doc: $0) } ?? []
                onChange(msgs)
            }
    }

    // MARK: - Inbox: “Started” Threads

    /// Observes 1:1 threads that have been started (have a last message or timestamp).
    func observeStartedThreads(
        for uid: String,
        handler: @escaping ([ChatThread]) -> Void
    ) -> ListenerRegistration {
        let db = Firestore.firestore()
        let epoch = Timestamp(date: Date(timeIntervalSince1970: 1)) // tiny > 0

        // Base: chats that include me, are not group chats
        var query: Query = db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .whereField("isgroupchat", isEqualTo: false)
        query = query.order(by: "lastmessagetime", descending: true)

        return query.addSnapshotListener { snap, _ in
            let list = snap?.documents.compactMap { ChatThread(doc: $0) } ?? []
            let started = list.filter { ($0.lastmessage?.isEmpty == false) || ($0.lastmessagetime != nil) }
            handler(started)
        }
    }

    // MARK: - Messages

    /// Sends a text message and updates thread summary fields.
    func sendText(chatId: String, text: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let now = Date()

        let msgData: [String: Any] = [
            "senderID": uid,
            "text": text,
            "status": "sent",
            "createdat": Timestamp(date: now),
            "type": "text"
        ]

        let ref = fs.chats.document(chatId)
        _ = try await ref.collection("messages").addDocument(data: msgData)

        try await ref.setData([
            "lastmessage": text,
            "lastmessagetime": FieldValue.serverTimestamp()
        ], merge: true)
    }
}
