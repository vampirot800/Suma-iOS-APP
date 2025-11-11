//
//  IdeaService.swift
//  FIT3178-App
//
//  Created by Ramiro Flores Villarreal on 11/11/25.
//

import Foundation

/// Defines errors that may occur during API calls.
enum IdeaServiceError: Error {
    case badURL
    case badResponse
    case decoding
}

/// Handles fetching of Hacker News-style articles using the Algolia API.
/// Provides both front page and keyword-based results.
final class IdeaService {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Fetches trending stories from Hacker News front page.
    /// - Returns: A list of `IdeaArticle` objects.
    func fetchFrontPage() async throws -> [IdeaArticle] {
        var comps = URLComponents(string: "https://hn.algolia.com/api/v1/search")
        comps?.queryItems = [
            .init(name: "tags", value: "front_page"),
            .init(name: "hitsPerPage", value: "30")
        ]
        guard let url = comps?.url else { throw IdeaServiceError.badURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw IdeaServiceError.badResponse
        }

        let decoded = try JSONDecoder.hn.decode(HNResponse.self, from: data)
        return decoded.hits.map { $0.asIdeaArticle() }
    }

    /// Performs a keyword search for stories.
    /// - Parameter query: Search term.
    /// - Returns: Articles containing the keyword.
    func search(query: String) async throws -> [IdeaArticle] {
        var comps = URLComponents(string: "https://hn.algolia.com/api/v1/search")
        comps?.queryItems = [
            .init(name: "query", value: query),
            .init(name: "tags", value: "story"),
            .init(name: "hitsPerPage", value: "30")
        ]
        guard let url = comps?.url else { throw IdeaServiceError.badURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw IdeaServiceError.badResponse
        }

        let decoded = try JSONDecoder.hn.decode(HNResponse.self, from: data)
        return decoded.hits.map { $0.asIdeaArticle() }
    }
}

// MARK: - Private DTOs

private struct HNResponse: Codable { let hits: [HNHit] }

private struct HNHit: Codable {
    let objectID: String
    let title: String?
    let url: String?
    let points: Int?
    let author: String?
    let created_at: Date?

    /// Converts the API model to `IdeaArticle` format used in the app.
    func asIdeaArticle() -> IdeaArticle {
        let fallback = "https://news.ycombinator.com/item?id=\(objectID)"
        return IdeaArticle(
            title: title ?? "(no title)",
            points: points ?? 0,
            author: author ?? "unknown",
            date: created_at ?? Date(),
            urlString: url ?? fallback
        )
    }
}

// MARK: - JSONDecoder Helper

private extension JSONDecoder {
    /// Provides a decoder configured for ISO8601 with fractional seconds.
    static var hn: JSONDecoder {
        let d = JSONDecoder()
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let str = try c.decode(String.self)
            if let date = iso.date(from: str) { return date }
            if let fallback = ISO8601DateFormatter().date(from: str) { return fallback }
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid date"))
        }
        return d
    }
}
