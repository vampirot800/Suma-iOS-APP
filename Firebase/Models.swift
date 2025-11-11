//
//  Models.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 22/10/25.
//
//  Description:
//  Firestore-backed domain models used across the app: AppUser, ChatThread,
//  Message, Suma, and PortfolioItem. Includes safe casting helpers.
//

import Foundation
import FirebaseFirestore

// MARK: - Safe value helpers

/// Lightweight helpers for safely extracting typed values from Firestore dictionaries.
fileprivate extension Dictionary where Key == String, Value == Any {
    func str(_ k: String, default def: String = "") -> String { self[k] as? String ?? def }
    func strOpt(_ k: String) -> String? { self[k] as? String }
    func bool(_ k: String, default def: Bool = false) -> Bool { self[k] as? Bool ?? def }
    func arrStr(_ k: String) -> [String] { self[k] as? [String] ?? [] }
    func date(_ k: String) -> Date? {
        if let ts = self[k] as? Timestamp { return ts.dateValue() }
        if let d  = self[k] as? Date { return d }
        return nil
    }
}

// MARK: - USERS

/// Represents a user profile document under `/users/{uid}`.
struct AppUser: Identifiable {
    var id: String?                // == auth uid (doc id)
    var displayName: String
    var username: String
    var role: String
    var bio: String
    var photoURL: String?
    var tags: [String]
    var searchable: [String]

    init(id: String? = nil,
         displayName: String,
         username: String,
         role: String,
         bio: String,
         photoURL: String?,
         tags: [String],
         searchable: [String]) {
        self.id = id
        self.displayName = displayName
        self.username = username
        self.role = role
        self.bio = bio
        self.photoURL = photoURL
        self.tags = tags
        self.searchable = searchable
    }

    /// Initializes from a Firestore document snapshot.
    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        self.id = doc.documentID
        self.displayName = data.str("displayName")
        self.username = data.str("username")
        self.role = data.str("role", default: "media creator")
        self.bio = data.str("bio")
        self.photoURL = data.strOpt("photoURL")
        self.tags = data.arrStr("tags")
        self.searchable = data.arrStr("searchable")
    }

    /// Encodes a user for Firestore writes/merges.
    var asData: [String: Any] {
        var d: [String: Any] = [
            "displayName": displayName,
            "username": username,
            "role": role,
            "bio": bio,
            "tags": tags,
            "searchable": searchable
        ]
        if let photoURL { d["photoURL"] = photoURL }
        return d
    }
}

// MARK: - CHATS

/// Summary info for a chat thread under `/chats/{chatId}`.
struct ChatThread: Identifiable {
    var id: String?
    var participants: [String]
    var lastmessage: String?
    var lastmessagetime: Date?
    var participantphotos: [String: String]?
    var isgroupchat: Bool

    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        self.id = doc.documentID
        self.participants = data.arrStr("participants")
        self.lastmessage = data.strOpt("lastmessage")
        self.lastmessagetime = data.date("lastmessagetime")
        self.participantphotos = data["participantphotos"] as? [String: String]
        self.isgroupchat = data.bool("isgroupchat")
    }
}

// MARK: - MESSAGES

/// A single chat message under `/chats/{chatId}/messages/{messageId}`.
struct Message: Identifiable {
    var id: String?
    var senderID: String
    var text: String
    var status: String
    var createdat: Date
    var type: String

    init?(doc: DocumentSnapshot) {
        guard let data = doc.data(),
              let created = data.date("createdat")
        else { return nil }
        self.id = doc.documentID
        self.senderID = data.str("senderID")
        self.text = data.str("text")
        self.status = data.str("status", default: "sent")
        self.createdat = created
        self.type = data.str("type", default: "text")
    }
}

// MARK: - SUMA (tinder-like cards)

/// Content item shown in “For You” / discovery experiences.
struct Suma: Identifiable {
    var id: String?
    var ownerId: String
    var title: String
    var orgName: String
    var date: Date
    var link: String
    var summary: String

    init?(doc: DocumentSnapshot) {
        guard let data = doc.data(),
              let date = (data["date"] as? Timestamp)?.dateValue()
        else { return nil }
        self.id = doc.documentID
        self.ownerId = data["ownerId"] as? String ?? ""
        self.title = data["title"] as? String ?? ""
        self.orgName = data["orgName"] as? String ?? ""
        self.date = date
        self.link = data["link"] as? String ?? ""
        self.summary = data["summary"] as? String ?? ""
    }

    var asData: [String: Any] {
        [
            "ownerId": ownerId,
            "title": title,
            "orgName": orgName,
            "date": Timestamp(date: date),
            "link": link,
            "summary": summary
        ]
    }
}

// MARK: - PORTFOLIOS

/// Portfolio card shown in the user’s profile and portfolio lists.
struct PortfolioItem: Identifiable {
    var id: String?
    var title: String
    var role: String
    var description: String
    var startDate: Date?
    var endDate: Date?
    var skills: [String]
    var mediaURLs: [String]
    var createdAt: Date?

    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        self.id = doc.documentID
        self.title = data["title"] as? String ?? ""
        self.role = data["role"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.startDate = (data["startDate"] as? Timestamp)?.dateValue()
        self.endDate = (data["endDate"] as? Timestamp)?.dateValue()
        self.skills = data["skills"] as? [String] ?? []
        self.mediaURLs = data["mediaURLs"] as? [String] ?? []
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
    }

    /// Encodes a portfolio card for Firestore writes/merges.
    var asData: [String: Any] {
        [
            "title": title,
            "role": role,
            "description": description,
            "startDate": startDate != nil ? Timestamp(date: startDate!) : NSNull(),
            "endDate": endDate != nil ? Timestamp(date: endDate!) : NSNull(),
            "skills": skills,
            "mediaURLs": mediaURLs,
            "createdAt": Timestamp(date: createdAt ?? Date())
        ]
    }
}
