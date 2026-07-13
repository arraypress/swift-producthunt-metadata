# Swift Product Hunt Metadata

A Swift library for fetching Product Hunt posts (launches) and their comment threads via the official Product Hunt GraphQL API.

> Unlike this author's keyless metadata libraries, **Product Hunt requires an OAuth access token** (see [Authentication](#authentication)).

## Features

- 🚀 **Posts (launches)** — name, tagline, description, votes, comments count, rating, topics, maker, thumbnail, website
- 💬 **Comment threads** — top-level comments with nested `replies`, vote counts, authors; `flattened` for a depth-first list
- 📃 **Browse posts** — list by ranking / newest / votes / featured, optionally filtered by topic
- 🔑 **Flexible auth** — a developer token, or a Confidential app's client ID/secret (auto-exchanged via `client_credentials`), from config or environment
- 🧹 **Readable text** — comment HTML decoded to plain text, with raw `bodyHTML` retained
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS · Swift 6 · async/await
- 🛡️ **Typed error handling**

## Authentication

Product Hunt's API is token-gated. Two ways to provide credentials:

1. **Developer token** (simplest): generate one on your app's page at
   `https://www.producthunt.com/v2/oauth/applications`. Pass it as
   `Configuration(token:)` or set `PRODUCT_HUNT_TOKEN`.
2. **Confidential app** (client credentials): create a *Confidential* app, then
   pass `Configuration(clientID:clientSecret:)` or set `PRODUCT_HUNT_CLIENT_ID` /
   `PRODUCT_HUNT_CLIENT_SECRET`. The library exchanges them for a read-only
   `public`-scope token and caches it.

```swift
// From the environment (PRODUCT_HUNT_TOKEN or client id/secret):
let post = try await ProductHuntMetadata.post("notion")

// Explicit:
let config = ProductHuntMetadata.Configuration(token: "…")
let post2 = try await ProductHuntMetadata.post("notion", configuration: config)
```

## Usage

### Post + comments

```swift
let (post, comments) = try await ProductHuntMetadata.postWithComments("justvibe-3")

print("\(post.name): \(post.tagline ?? "") — \(post.votesCount) votes, \(post.commentsCount) comments")
print("Topics: \(post.topics.joined(separator: ", "))")

for c in comments.flattened {
    let indent = String(repeating: "  ", count: c.depth)
    print("\(indent)▲\(c.votesCount) \(c.user?.username ?? "?"): \(c.text)")
}
```

### Comments only

```swift
let comments = try await ProductHuntMetadata.comments(
    "justvibe-3", sortBy: .votes, includeReplies: true, limit: 100
)
```

### Browse posts

```swift
// Product Hunt has no free-text search — browse by order + topic instead.
let top = try await ProductHuntMetadata.posts(order: .ranking, limit: 10)
let aiPosts = try await ProductHuntMetadata.posts(order: .votes, topic: "artificial-intelligence", limit: 20)
```

## Models

| Type | Description |
|------|-------------|
| `PHPost` | `id`, `slug`, `name`, `tagline`, `description`, `votesCount`, `commentsCount`, `reviewsRating`, `createdAt`, `featuredAt`, `url`, `website`, `thumbnailURL`, `topics`, `user` |
| `PHComment` | `id`, `text`, `bodyHTML`, `votesCount`, `createdAt`, `user`, `parentId`, `depth`, `replies`, plus `hasReplies`, `replyCount`, `flattened` |
| `PHUser` | `name`, `username`, `headline` |
| `ProductHuntMetadataError` | Typed errors with `errorDescription` |

## Notes

- **No free-text search.** The Product Hunt API filters posts by order, topic, and date only — there's no query-string search.
- **Complexity limit.** The API caps query complexity at 500,000, which nested connections multiply against. This library bounds comment/reply page sizes and paginates automatically to stay within budget.
- **Comment scores are public** on Product Hunt (each `PHComment` has a `votesCount`), unlike some platforms.

## Testing

```bash
swift test                                             # offline unit tests (fixtures)
PH_LIVE_TESTS=1 PRODUCT_HUNT_TOKEN=… swift test        # also run live network tests
```

## License

MIT

## Author

David Sherlock
