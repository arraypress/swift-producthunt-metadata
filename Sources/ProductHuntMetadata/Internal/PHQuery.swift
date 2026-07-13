//
//  PHQuery.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// GraphQL query strings for the Product Hunt API.
///
/// All queries use variables (never string interpolation of user input) and
/// bound every connection's page size, since Product Hunt enforces a 500,000
/// query-complexity limit that nested connections multiply against.
enum PHQuery {

    static let postFields = """
    id slug name tagline description votesCount commentsCount reviewsRating createdAt featuredAt url website
    thumbnail { url } topics { edges { node { name } } } user { name username headline }
    """

    static let commentFields = """
    id body votesCount createdAt parentId user { name username headline }
    """

    /// Post metadata by slug or ID.
    static let post = """
    query($id: ID, $slug: String) {
      post(id: $id, slug: $slug) { \(postFields) }
    }
    """

    /// A page of a post's top-level comments, each with a page of replies.
    static let comments = """
    query($id: ID, $slug: String, $first: Int!, $after: String, $order: CommentsOrder, $repliesFirst: Int!) {
      post(id: $id, slug: $slug) {
        comments(first: $first, after: $after, order: $order) {
          pageInfo { hasNextPage endCursor }
          edges { node {
            \(commentFields)
            replies(first: $repliesFirst) { edges { node { \(commentFields) } } }
          } }
        }
      }
    }
    """

    /// A page of a post's top-level comments, without replies (cheaper).
    static let commentsNoReplies = """
    query($id: ID, $slug: String, $first: Int!, $after: String, $order: CommentsOrder) {
      post(id: $id, slug: $slug) {
        comments(first: $first, after: $after, order: $order) {
          pageInfo { hasNextPage endCursor }
          edges { node { \(commentFields) } }
        }
      }
    }
    """

    /// A page of posts (launches), filtered by order and optional topic.
    static let posts = """
    query($first: Int!, $after: String, $order: PostsOrder, $topic: String) {
      posts(first: $first, after: $after, order: $order, topic: $topic) {
        pageInfo { hasNextPage endCursor }
        edges { node { \(postFields) } }
      }
    }
    """
}
