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
        Candidate(id: "u1",
                  name: "Lia Gomez",
                  role: .mediaCreator,
                  website: nil,                 // satisfy new parameters
                  location: nil,
                  bio: "Travel + food content",
                  tags: ["travel","food","photo"],
                  photoURL: nil),
        Candidate(id: "u2",
                  name: "Kai Jones",
                  role: .mediaCreator,
                  website: nil,
                  location: nil,
                  bio: "Sneakers & streetwear",
                  tags: ["fashion","sneakers","music"],
                  photoURL: nil),
        Candidate(id: "u3",
                  name: "Marin Ito",
                  role: .mediaCreator,
                  website: nil,
                  location: nil,
                  bio: "Surf & outdoor",
                  tags: ["sports","outdoor","travel"],
                  photoURL: nil),
    ]

    static let enterprises: [Candidate] = [
        Candidate(id: "c1",
                  name: "WaveCo",
                  role: .enterprise,
                  website: nil,
                  location: nil,
                  bio: "Board brand looking for creators",
                  tags: ["sports","outdoor"],
                  photoURL: nil),
        Candidate(id: "c2",
                  name: "Bistro 88",
                  role: .enterprise,
                  website: nil,
                  location: nil,
                  bio: "Restaurant collabs",
                  tags: ["food","travel"],
                  photoURL: nil),
        Candidate(id: "c3",
                  name: "UrbanFit",
                  role: .enterprise,
                  website: nil,
                  location: nil,
                  bio: "Athleisure marketing",
                  tags: ["fitness","fashion"],
                  photoURL: nil),
    ]
}
