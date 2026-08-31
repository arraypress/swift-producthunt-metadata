//
//  PHEnums.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The order in which Product Hunt returns posts (launches).
public enum PHPostsOrder: String, Sendable {
    /// Product Hunt's ranking for the day.
    case ranking = "RANKING"
    /// Newest first.
    case newest = "NEWEST"
    /// Most votes first.
    case votes = "VOTES"
    /// By the time each post was featured.
    case featured = "FEATURED_AT"
}

/// The order in which a post's comments are returned.
public enum PHCommentsOrder: String, Sendable {
    /// Most-voted first.
    case votes = "VOTES_COUNT"
    /// Newest first.
    case newest = "NEWEST"
}
