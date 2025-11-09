//
//  Models.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 22/10/25.
//

import Foundation
import FirebaseFirestore

// MARK: - Safe value helpers
fileprivate extension Dictionary where Key == String, Value == Any {
    func str(_ k: String, default def: String = "") -> String { self[k] as? String ?? def }
    func strOpt(_ k: String) -> String? { self[k] as? String }
    func bool(_ k: String, default def: Bool = false) -> Bool { self[k] as? Bool ?? def }
    func arrStr(_ k: String) -> [String] { self[k] as? [String] ?? [] }
    func date(_ k: String) -> Date? {
        if let ts = self[k] as? Timestamp { return ts.dateValue() }
        if let d = self[k] as? Date { return d }
        return nil
    }
}

// MARK: - USERS
struct AppUser: Identifiable {
    var id: String?                // == auth uid (doc id)
    var displayName: String
    var username: String
    var role: String
    var bio: String
    var photoURL: String?
    var tags: [String]
    var searchable: [String]

    init(id: String? = nil, displayName: String, username: String, role: String,
         bio: String, photoURL: String?, tags: [String], searchable: [String]) {
        self.id = id; self.displayName = displayName; self.username = username
        self.role = role; self.bio = bio; self.photoURL = photoURL
        self.tags = tags; self.searchable = searchable
    }

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

    var asData: [String:Any] {
        var d: [String:Any] = [
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
struct ChatThread: Identifiable {
    var id: String?
    var participants: [String]
    var lastmessage: String?
    var lastmessagetime: Date?
    var participantphotos: [String:String]?
    var isgroupchat: Bool

    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        self.id = doc.documentID
        self.participants = data.arrStr("participants")
        self.lastmessage = data.strOpt("lastmessage")
        self.lastmessagetime = data.date("lastmessagetime")
        self.participantphotos = data["participantphotos"] as? [String:String]
        self.isgroupchat = data.bool("isgroupchat")
    }
}

// MARK: - MESSAGES
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
