//
//  ChatRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import Foundation
import FirebaseFirestore

final class ChatRepository {
    static let shared = ChatRepository()
    private init() {}

    private let fs = FirebaseService.shared

    // Create (or find) a 1:1 thread for two users
    func ensureDirectThread(with otherUid: String, currentUid: String) async throws -> String {
        // Look for an existing chat with exactly these two participants
        let snap = try await fs.chats
            .whereField("isgroupchat", isEqualTo: false)
            .whereField("participants", arrayContains: currentUid)
            .getDocuments()

        if let doc = snap.documents.first(where: { ($0["participants"] as? [String])?.sorted() == [currentUid, otherUid].sorted() }) {
            return doc.documentID
        }

        // Create new
        var data: [String: Any] = [
            "participants": [currentUid, otherUid],
            "isgroupchat": false,
            "lastmessage": "",
            "lastmessagetime": FieldValue.serverTimestamp()
        ]
        // Optional: prefill participantphotos as an empty map
        data["participantphotos"] = [String:String]()
        let ref = try await fs.chats.addDocument(data: data)
        return ref.documentID
    }

    // Observe the current user's threads (ordered by lastmessagetime desc)
    func observeThreads(for uid: String,
                        onChange: @escaping ([ChatThread]) -> Void) -> ListenerRegistration {
        fs.chats
            .whereField("participants", arrayContains: uid)
            .order(by: "lastmessagetime", descending: true)
            .addSnapshotListener { qs, _ in
                let threads: [ChatThread] = qs?.documents.compactMap { try? $0.data(as: ChatThread.self) } ?? []
                onChange(threads)
            }
    }

    // Observe messages within a thread
    func observeMessages(chatId: String,
                         onChange: @escaping ([Message]) -> Void) -> ListenerRegistration {
        fs.chats.document(chatId)
            .collection("messages")
            .order(by: "createdat")
            .addSnapshotListener { qs, _ in
                let msgs: [Message] = qs?.documents.compactMap { try? $0.data(as: Message.self) } ?? []
                onChange(msgs)
            }
    }

    // Send a text message
    func sendText(chatId: String, text: String, from uid: String) async throws {
        let msg = Message(id: nil,
                          senderID: uid,
                          text: text,
                          status: "sent",
                          createdat: Date(),
                          type: "text")

        let ref = fs.chats.document(chatId)
        _ = try await ref.collection("messages").addDocument(data: [
            "senderID": msg.senderID,
            "text": msg.text,
            "status": msg.status,
            "createdat": Timestamp(date: msg.createdat),
            "type": msg.type
        ])

        try await ref.setData([
            "lastmessage": msg.text,
            "lastmessagetime": FieldValue.serverTimestamp()
        ], merge: true)
    }
}
