//
//  ChatRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//
    
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ChatRepository {
    static let shared = ChatRepository()
    private init() {}

    private let fs = FirebaseService.shared

    // Create or return an existing 1:1 chat with `otherUid`
    func ensureDirectThread(with otherUid: String) async throws -> String {
        guard let currentUid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        }

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

        let data: [String: Any] = [
            "participants": [currentUid, otherUid],
            "isgroupchat": false,
            "lastmessage": "",
            "lastmessagetime": FieldValue.serverTimestamp(),
            "participantphotos": [String:String]()
        ]
        let ref = try await fs.chats.addDocument(data: data)
        return ref.documentID
    }

    // Observe all threads for uid
    func observeThreads(for uid: String,
                        onChange: @escaping ([ChatThread]) -> Void) -> ListenerRegistration {
        fs.chats
            .whereField("participants", arrayContains: uid)
            .order(by: "lastmessagetime", descending: true)
            .addSnapshotListener { qs, _ in
                let threads = qs?.documents.compactMap { ChatThread(doc: $0) } ?? []
                onChange(threads)
            }
    }

    // Observe messages for a chat
    func observeMessages(chatId: String,
                         onChange: @escaping ([Message]) -> Void) -> ListenerRegistration {
        fs.chats.document(chatId)
            .collection("messages")
            .order(by: "createdat")
            .addSnapshotListener { qs, _ in
                let msgs = qs?.documents.compactMap { Message(doc: $0) } ?? []
                onChange(msgs)
            }
    }
    
    // MARK: Started 1:1 threads (for Inbox)
    func observeStartedThreads(for uid: String,
                               handler: @escaping ([ChatThread]) -> Void) -> ListenerRegistration {

        let db = Firestore.firestore()
        let epoch = Timestamp(date: Date(timeIntervalSince1970: 1)) // tiny > 0

        // Base: chats that include me
        var query: Query = db.collection("chats")
            .whereField("participants", arrayContains: uid)
            .whereField("isgroupchat", isEqualTo: false)

        // We want “started” chats:
        // ( lastmessage != "" ) OR ( lastmessagetime > epoch )
        // Firestore doesn’t allow OR + orderBy in one pass without composite indexes,
        // so we’ll do the OR in memory after listening.
        query = query.order(by: "lastmessagetime", descending: true)

        return query.addSnapshotListener { snap, _ in
            let list = snap?.documents.compactMap { ChatThread(doc: $0) } ?? []
            let started = list.filter { ($0.lastmessage?.isEmpty == false) || ($0.lastmessagetime != nil) }
            handler(started)
        }
    }



    // Send message
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
