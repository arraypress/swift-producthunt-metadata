//
//  PHComment.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single Product Hunt comment, with its nested replies.
///
/// Product Hunt's API returns a post's top-level comments; each comment's direct
/// replies are fetched alongside it. Use ``flattened`` for a depth-first list.
///
/// ```swift
/// let comments = try await ProductHuntMetadata.comments("justvibe-3")
/// for c in comments.flattened {
///     let indent = String(repeating: "  ", count: c.depth)
///     print("\(indent)\(c.user?.username ?? "?"): \(c.text)  ▲\(c.votesCount)")
/// }
/// ```
public struct PHComment: Sendable, Identifiable {

    /// The comment ID.
    public let id: String

    /// The comment body as readable plain text (HTML decoded, paragraphs kept).
    public let text: String

    /// The original comment body as HTML, exactly as Product Hunt served it.
    public let bodyHTML: String

    /// The number of upvotes on the comment.
    public let votesCount: Int

    /// When the comment was posted.
    public let createdAt: Date?

    /// The comment's author.
    public let user: PHUser?

    /// The parent comment's ID, or `nil` for a top-level comment.
    public let parentId: String?

    /// Nesting depth: `0` for top-level, `1` for a reply.
    public let depth: Int

    /// The direct replies to this comment.
    public let replies: [PHComment]

    // MARK: - Computed

    /// Whether this comment has any replies.
    public var hasReplies: Bool { !replies.isEmpty }

    /// The total number of descendant comments beneath this one.
    public var replyCount: Int {
        replies.reduce(replies.count) { $0 + $1.replyCount }
    }

    /// This comment followed by all of its descendants, depth-first.
    public var flattened: [PHComment] {
        [self] + replies.flatMap(\.flattened)
    }

    public init(
        id: String,
        text: String,
        bodyHTML: String,
        votesCount: Int,
        createdAt: Date?,
        user: PHUser?,
        parentId: String?,
        depth: Int,
        replies: [PHComment]
    ) {
        self.id = id
        self.text = text
        self.bodyHTML = bodyHTML
        self.votesCount = votesCount
        self.createdAt = createdAt
        self.user = user
        self.parentId = parentId
        self.depth = depth
        self.replies = replies
    }
}

// MARK: - Array helpers

public extension Array where Element == PHComment {

    /// All comments in the tree, depth-first (each comment followed by its replies).
    var flattened: [PHComment] {
        flatMap(\.flattened)
    }

    /// The total number of comments in the tree (top-level + all replies).
    var totalCount: Int {
        reduce(count) { $0 + $1.replyCount }
    }
}
