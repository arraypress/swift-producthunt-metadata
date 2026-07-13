//
//  PHPost.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A Product Hunt user (maker, hunter, or commenter).
public struct PHUser: Sendable, Equatable {
    /// The user's display name.
    public let name: String?
    /// The user's `@username`.
    public let username: String?
    /// The user's headline/bio, if present.
    public let headline: String?

    public init(name: String?, username: String?, headline: String?) {
        self.name = name
        self.username = username
        self.headline = headline
    }
}

/// A Product Hunt post (a product launch).
///
/// Fetched from the Product Hunt GraphQL API. A "post" is a launch — the object
/// behind a `producthunt.com/posts/<slug>` page.
///
/// ```swift
/// let post = try await ProductHuntMetadata.post("justvibe-3")
/// print("\(post.name) — \(post.votesCount) votes, \(post.commentsCount) comments")
/// ```
public struct PHPost: Sendable, Identifiable {

    /// The post's ID.
    public let id: String

    /// The post slug (the `/posts/<slug>` segment).
    public let slug: String

    /// The product name.
    public let name: String

    /// The one-line tagline.
    public let tagline: String?

    /// The full description, if requested.
    public let description: String?

    /// The number of upvotes.
    public let votesCount: Int

    /// The number of comments.
    public let commentsCount: Int

    /// The average review rating (0–5), if any.
    public let reviewsRating: Double?

    /// When the post was created.
    public let createdAt: Date?

    /// When the post was featured, if it was.
    public let featuredAt: Date?

    /// The Product Hunt URL for this post.
    public let url: String?

    /// The product's own website URL.
    public let website: String?

    /// The thumbnail image URL.
    public let thumbnailURL: String?

    /// The topic names this post is filed under.
    public let topics: [String]

    /// The submitter (hunter).
    public let user: PHUser?

    public init(
        id: String,
        slug: String,
        name: String,
        tagline: String?,
        description: String?,
        votesCount: Int,
        commentsCount: Int,
        reviewsRating: Double?,
        createdAt: Date?,
        featuredAt: Date?,
        url: String?,
        website: String?,
        thumbnailURL: String?,
        topics: [String],
        user: PHUser?
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.tagline = tagline
        self.description = description
        self.votesCount = votesCount
        self.commentsCount = commentsCount
        self.reviewsRating = reviewsRating
        self.createdAt = createdAt
        self.featuredAt = featuredAt
        self.url = url
        self.website = website
        self.thumbnailURL = thumbnailURL
        self.topics = topics
        self.user = user
    }
}
