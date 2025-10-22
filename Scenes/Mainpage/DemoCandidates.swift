//
//  DemoCandidates.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 23/10/25.
//

import Foundation

enum DemoCandidates {
    static let meTags: [String] = ["sports", "travel", "food", "fashion"]

    static let creators: [Candidate] = [
        Candidate(id: "u1", name: "Lia Gomez", role: .mediaCreator,
                  bio: "Travel + food content", tags: ["travel","food","photo"],
                  photoURL: nil),
        Candidate(id: "u2", name: "Kai Jones", role: .mediaCreator,
                  bio: "Sneakers & streetwear", tags: ["fashion","sneakers","music"],
                  photoURL: nil),
        Candidate(id: "u3", name: "Marin Ito", role: .mediaCreator,
                  bio: "Surf & outdoor", tags: ["sports","outdoor","travel"],
                  photoURL: nil),
    ]

    static let enterprises: [Candidate] = [
        Candidate(id: "c1", name: "WaveCo", role: .enterprise,
                  bio: "Board brand looking for creators", tags: ["sports","outdoor"],
                  photoURL: nil),
        Candidate(id: "c2", name: "Bistro 88", role: .enterprise,
                  bio: "Restaurant collabs", tags: ["food","travel"],
                  photoURL: nil),
        Candidate(id: "c3", name: "UrbanFit", role: .enterprise,
                  bio: "Athleisure marketing", tags: ["fitness","fashion"],
                  photoURL: nil),
    ]
}
