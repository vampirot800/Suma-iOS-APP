//
//  Candidate.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 23/10/25.
//

import Foundation

struct Candidate: Hashable {
    enum Role: String { case mediaCreator = "media creator", enterprise = "enterprise" }

    let id: String
    let name: String
    let role: Role
    let website: String? 
    let location: String?
    let bio: String
    let tags: [String]
    let photoURL: URL?

    // Quick similarity score: overlapping tags
    func similarity(with myTags: [String]) -> Int {
        let a = Set(tags.map { $0.lowercased() })
        let b = Set(myTags.map { $0.lowercased() })
        return a.intersection(b).count
    }
}
