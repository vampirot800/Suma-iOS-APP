//
//  ChatRepository.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 05/10/25.
//

import Foundation
import FirebaseFirestore

final class ChatRepository {
    private let fs = FirebaseService.shared

    // Get chats where current user participates
    func observeMyChats(uid: String,
                        onChange: @escaping ([ChatThread]) -> Void) -> ListenerRegistration {
        return fs.chats.whereField("participants", arrayContains: uid)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { qs, _ in
                let items = qs?.documents.compactMap { try? $0.data(as: ChatThread.self) } ?? []
                onChange(items)
            }
    }

    // Messages subcollection listener
    func observeMessages(chatId: String,
                         onChange: @escaping ([Message]) -> Void) -> ListenerRegistration {
        fs.chats.document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { qs, _ in
                let msgs = qs?.documents.compactMap { try? $0.data(as: Message.self) } ?? []
                onChange(msgs)
            }
    }

    // Send a message; also updates chat summary
    func sendMessage(chatId: String, from uid: String, text: String) async throws {
        let msg = Message(id: nil, senderID: uid, text: text, status: "sent", createdat: Date(), type: "text")
        try fs.chats.document(chatId).collection("messages").addDocument(from: msg)

        try await fs.chats.document(chatId).setData([
            "lastMessage": text,
            "lastMessageTime": FieldValue.serverTimestamp()
        ], merge: true)
    }

    // Create (or reuse) a 1:1 chat for two uids
    func ensureDirectChat(between a: String, and b: String) async throws -> String {
        // Simple: search a chat with both participants
        let qs = try await fs.chats
            .whereField("participants", arrayContains: a).getDocuments()

        if let existing = qs.documents.first(where: {
            let arr = $0["participants"] as? [String] ?? []
            return Set(arr) == Set([a,b])
        })?.documentID {
            return existing
        }

        let new = ChatThread(id: nil, participants: [a, b],
                             lastmessage: nil, lastmessagetime: nil,
                             participantphotos: nil, isgroupchat: false)

        let ref = try fs.chats.addDocument(from: new)
        return ref.documentID
    }
}
