//
//  Models.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 22/10/25.
//

import Foundation
import FirebaseFirestore

// USERS
struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?           // == Firebase Auth uid
    var displayName: String
    var username: String
    var role: String
    var bio: String
    var photoURL: String?
    var tags: [String]
    var searchable: [String]
}

// CHATS
struct ChatThread: Codable, Identifiable {
    @DocumentID var id: String?
    var participants: [String]            // uids
    var lastmessage: String?
    var lastmessagetime: Date?
    var participantphotos: [String:String]? // uid->url (optional)
    var isgroupchat: Bool
}

// MESSAGES (subcollection: chats/{chatId}/messages)
struct Message: Codable, Identifiable {
    @DocumentID var id: String?
    var senderID: String
    var text: String
    var status: String
    var createdat: Date
    var type: String
    
}

// SUMAS (achievements) – top level docs keyed like "suma.user1"
struct Suma: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var orgName: String
    var date: Date
    var link: String
    var summary: String

}
