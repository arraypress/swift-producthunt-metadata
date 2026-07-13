//
//  PHParser.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses Product Hunt GraphQL response objects into typed models.
enum PHParser {

    // MARK: - Entry points

    static func post(from data: [String: Any]) throws -> PHPost {
        guard let node = data["post"] as? [String: Any] else {
            throw ProductHuntMetadataError.itemNotFound
        }
        return parsePost(node)
    }

    /// Parses one page of a post's comments.
    static func commentsPage(
        from data: [String: Any]
    ) throws -> (comments: [PHComment], hasNextPage: Bool, endCursor: String?) {
        guard let post = data["post"] as? [String: Any] else {
            throw ProductHuntMetadataError.itemNotFound
        }
        guard let connection = post["comments"] as? [String: Any] else {
            return ([], false, nil)
        }
        let edges = connection["edges"] as? [[String: Any]] ?? []
        let comments = edges.compactMap { edge -> PHComment? in
            (edge["node"] as? [String: Any]).map { parseComment($0, depth: 0) }
        }
        let pageInfo = connection["pageInfo"] as? [String: Any]
        return (comments, pageInfo?["hasNextPage"] as? Bool ?? false, pageInfo?["endCursor"] as? String)
    }

    static func postsList(from data: [String: Any]) -> [PHPost] {
        guard let connection = data["posts"] as? [String: Any],
              let edges = connection["edges"] as? [[String: Any]] else { return [] }
        return edges.compactMap { edge in
            (edge["node"] as? [String: Any]).map(parsePost)
        }
    }

    // MARK: - Nodes

    static func parsePost(_ node: [String: Any]) -> PHPost {
        PHPost(
            id: stringValue(node["id"]) ?? "",
            slug: node["slug"] as? String ?? "",
            name: node["name"] as? String ?? "",
            tagline: node["tagline"] as? String,
            description: (node["description"] as? String).flatMap { $0.isEmpty ? nil : $0 },
            votesCount: node["votesCount"] as? Int ?? 0,
            commentsCount: node["commentsCount"] as? Int ?? 0,
            reviewsRating: doubleValue(node["reviewsRating"]),
            createdAt: date(node["createdAt"]),
            featuredAt: date(node["featuredAt"]),
            url: node["url"] as? String,
            website: node["website"] as? String,
            thumbnailURL: (node["thumbnail"] as? [String: Any])?["url"] as? String,
            topics: topicNames(node["topics"]),
            user: parseUser(node["user"])
        )
    }

    static func parseComment(_ node: [String: Any], depth: Int) -> PHComment {
        let html = node["body"] as? String ?? ""
        let replyEdges = (node["replies"] as? [String: Any])?["edges"] as? [[String: Any]] ?? []
        let replies = replyEdges.compactMap { edge -> PHComment? in
            (edge["node"] as? [String: Any]).map { parseComment($0, depth: depth + 1) }
        }
        return PHComment(
            id: stringValue(node["id"]) ?? "",
            text: PHHTML.toPlainText(html),
            bodyHTML: html,
            votesCount: node["votesCount"] as? Int ?? 0,
            createdAt: date(node["createdAt"]),
            user: parseUser(node["user"]),
            parentId: stringValue(node["parentId"]),
            depth: depth,
            replies: replies
        )
    }

    static func parseUser(_ value: Any?) -> PHUser? {
        guard let user = value as? [String: Any] else { return nil }
        return PHUser(
            name: user["name"] as? String,
            username: user["username"] as? String,
            headline: (user["headline"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        )
    }

    // MARK: - Helpers

    private static func topicNames(_ value: Any?) -> [String] {
        guard let topics = value as? [String: Any],
              let edges = topics["edges"] as? [[String: Any]] else { return [] }
        return edges.compactMap { ($0["node"] as? [String: Any])?["name"] as? String }
    }

    /// Product Hunt IDs are `ID` scalars — usually strings, occasionally numbers.
    private static func stringValue(_ value: Any?) -> String? {
        if let s = value as? String { return s }
        if let i = value as? Int { return String(i) }
        return nil
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        return nil
    }

    private static func date(_ value: Any?) -> Date? {
        guard let string = value as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
