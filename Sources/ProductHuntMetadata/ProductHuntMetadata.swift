//
//  ProductHuntMetadata.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Fetch products, launches (posts), and their comments from Product Hunt.
///
/// Unlike this author's other metadata libraries, the Product Hunt API is **not**
/// keyless — it requires an OAuth access token. Provide one of:
///
/// - A **developer token** (generated on your app's page), passed as
///   ``Configuration/token`` or via the `PRODUCT_HUNT_TOKEN` environment variable.
/// - A **Confidential app's** `clientID` + `clientSecret`, which this library
///   exchanges for a `client_credentials` access token automatically (read-only
///   `public` scope), via ``Configuration/clientID``/``Configuration/clientSecret``
///   or the `PRODUCT_HUNT_CLIENT_ID` / `PRODUCT_HUNT_CLIENT_SECRET` variables.
///
/// ```swift
/// import ProductHuntMetadata
///
/// // Reads PRODUCT_HUNT_TOKEN (or client id/secret) from the environment:
/// let product = try await ProductHuntMetadata.product("notion")
///
/// // Or pass credentials explicitly:
/// let config = ProductHuntMetadata.Configuration(token: "…")
/// let product2 = try await ProductHuntMetadata.product("notion", configuration: config)
/// ```
public enum ProductHuntMetadata {

    // MARK: - Configuration

    /// Credentials and options for talking to the Product Hunt API.
    ///
    /// Resolution order for the access token:
    /// 1. ``token`` if set,
    /// 2. otherwise a `client_credentials` exchange using ``clientID`` + ``clientSecret``.
    ///
    /// ``default`` reads all three from the environment
    /// (`PRODUCT_HUNT_TOKEN`, `PRODUCT_HUNT_CLIENT_ID`, `PRODUCT_HUNT_CLIENT_SECRET`).
    public struct Configuration: Sendable {

        /// A ready-to-use bearer token (e.g. a developer token).
        public var token: String?

        /// A Confidential app's client ID (for the `client_credentials` exchange).
        public var clientID: String?

        /// A Confidential app's client secret (for the `client_credentials` exchange).
        public var clientSecret: String?

        public init(token: String? = nil, clientID: String? = nil, clientSecret: String? = nil) {
            self.token = token
            self.clientID = clientID
            self.clientSecret = clientSecret
        }

        /// Reads credentials from the environment.
        public static var `default`: Configuration {
            let env = ProcessInfo.processInfo.environment
            return Configuration(
                token: env["PRODUCT_HUNT_TOKEN"],
                clientID: env["PRODUCT_HUNT_CLIENT_ID"],
                clientSecret: env["PRODUCT_HUNT_CLIENT_SECRET"]
            )
        }
    }

    // MARK: - Public API

    /// Fetches a Product Hunt post's (launch's) metadata.
    ///
    /// - Parameters:
    ///   - input: A post slug, numeric ID, or `producthunt.com/posts/<slug>` URL.
    ///   - configuration: Credentials/options. Defaults to ``Configuration/default``.
    /// - Returns: The ``PHPost`` metadata.
    public static func post(
        _ input: String,
        configuration: Configuration = .default
    ) async throws -> PHPost {
        let ref = try PHReference.extract(from: input)
        let data = try await GraphQLClient.execute(
            query: PHQuery.post, variables: refVariables(ref), configuration: configuration
        )
        return try PHParser.post(from: data)
    }

    /// Fetches a post's comments (top-level comments, each with its replies).
    ///
    /// Pages through top-level comments automatically. Each comment carries its
    /// direct ``PHComment/replies``; use ``PHComment/flattened`` for a flat list.
    ///
    /// - Parameters:
    ///   - input: A post slug, ID, or URL.
    ///   - sortBy: Comment ordering. Defaults to ``PHCommentsOrder/votes``.
    ///   - includeReplies: Whether to fetch each comment's replies. Defaults to `true`.
    ///   - limit: Optional cap on the number of top-level comments.
    ///   - configuration: Credentials/options.
    /// - Returns: The post's top-level comments.
    public static func comments(
        _ input: String,
        sortBy: PHCommentsOrder = .votes,
        includeReplies: Bool = true,
        limit: Int? = nil,
        configuration: Configuration = .default
    ) async throws -> [PHComment] {
        let ref = try PHReference.extract(from: input)
        let query = includeReplies ? PHQuery.comments : PHQuery.commentsNoReplies

        var collected: [PHComment] = []
        var after: String?
        // Product Hunt caps query complexity at 500k, which nested connections
        // multiply against; comments×replies must stay well under ~150.
        let pageSize = includeReplies ? 10 : 20

        while true {
            var variables = refVariables(ref)
            variables["first"] = pageSize
            variables["order"] = sortBy.rawValue
            if includeReplies { variables["repliesFirst"] = 10 }
            if let after { variables["after"] = after }

            let data = try await GraphQLClient.execute(
                query: query, variables: variables, configuration: configuration
            )
            let page = try PHParser.commentsPage(from: data)
            collected.append(contentsOf: page.comments)

            if let limit, collected.count >= limit {
                return Array(collected.prefix(limit))
            }
            guard page.hasNextPage, let cursor = page.endCursor else { break }
            after = cursor
        }
        return collected
    }

    /// Fetches a post's metadata and comments concurrently.
    ///
    /// - Returns: The ``PHPost`` and its top-level comments (with replies).
    public static func postWithComments(
        _ input: String,
        sortBy: PHCommentsOrder = .votes,
        includeReplies: Bool = true,
        limit: Int? = nil,
        configuration: Configuration = .default
    ) async throws -> (post: PHPost, comments: [PHComment]) {
        async let post = post(input, configuration: configuration)
        async let comments = comments(
            input, sortBy: sortBy, includeReplies: includeReplies, limit: limit, configuration: configuration
        )
        return try await (post: post, comments: comments)
    }

    /// Lists Product Hunt posts (launches).
    ///
    /// The Product Hunt API has no free-text search; browse by ranking/date and
    /// optionally filter to a topic slug (e.g. `"artificial-intelligence"`).
    ///
    /// - Parameters:
    ///   - order: Ordering. Defaults to ``PHPostsOrder/ranking``.
    ///   - topic: Optional topic slug to filter by.
    ///   - limit: Maximum number of posts to return. Defaults to `20`.
    ///   - configuration: Credentials/options.
    /// - Returns: The matching posts.
    public static func posts(
        order: PHPostsOrder = .ranking,
        topic: String? = nil,
        limit: Int = 20,
        configuration: Configuration = .default
    ) async throws -> [PHPost] {
        var collected: [PHPost] = []
        var after: String?

        while collected.count < limit {
            var variables: [String: Any] = [
                "first": min(limit - collected.count, 20),
                "order": order.rawValue
            ]
            if let topic { variables["topic"] = topic }
            if let after { variables["after"] = after }

            let data = try await GraphQLClient.execute(
                query: PHQuery.posts, variables: variables, configuration: configuration
            )
            let posts = PHParser.postsList(from: data)
            collected.append(contentsOf: posts)

            let pageInfo = (data["posts"] as? [String: Any])?["pageInfo"] as? [String: Any]
            guard posts.isEmpty == false,
                  pageInfo?["hasNextPage"] as? Bool == true,
                  let cursor = pageInfo?["endCursor"] as? String else { break }
            after = cursor
        }
        return Array(collected.prefix(limit))
    }

    /// Runs a raw GraphQL query and returns the `data` object. The typed helpers
    /// above are built on top of this.
    public static func rawQuery(
        _ query: String,
        variables: [String: Any] = [:],
        configuration: Configuration = .default
    ) async throws -> [String: Any] {
        try await GraphQLClient.execute(query: query, variables: variables, configuration: configuration)
    }

    // MARK: - Helpers

    private static func refVariables(_ ref: PHReference) -> [String: Any] {
        switch ref {
        case .slug(let slug): return ["slug": slug]
        case .id(let id): return ["id": id]
        }
    }
}
