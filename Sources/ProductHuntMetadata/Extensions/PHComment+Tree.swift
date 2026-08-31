//
//  PHComment+Tree.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//
//  The comment tree's derived facts — flattening and counting — kept
//  out of the model file so the shape reads alone.
//

import Foundation

extension PHComment {

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
