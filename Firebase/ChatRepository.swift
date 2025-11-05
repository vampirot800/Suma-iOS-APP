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
