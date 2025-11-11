//
//  Candidate.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 23/10/25.
//

import Foundation

/// Represents a potential connection or user profile shown in the app.
/// Used primarily for portfolio and matching features.
struct Candidate: Hashable {

    /// Professional role of the candidate.
    enum Role: String {
        case mediaCreator = "media creator"
        case enterprise = "enterprise"
    }

    // MARK: - Properties

    let id: String
    let name: String
    let role: Role
    let website: String?
    let location: String?
    let bio: String
    let tags: [String]
    let photoURL: URL?

    // MARK: - Utility

    /// Calculates a similarity score based on overlapping tags.
    /// - Parameter myTags: Tags from the current user.
    /// - Returns: The number of matching tags (higher means more similar).
    func similarity(with myTags: [String]) -> Int {
        let a = Set(tags.map { $0.lowercased() })
        let b = Set(myTags.map { $0.lowercased() })
        return a.intersection(b).count
    }
}
