//
//  ProductHuntMetadataTests.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import ProductHuntMetadata

final class ProductHuntMetadataTests: XCTestCase {

    // MARK: - Reference extraction

    func testReferenceFromSlug() throws {
        XCTAssertEqual(try PHReference.extract(from: "justvibe-3"), .slug("justvibe-3"))
    }

    func testReferenceFromNumericID() throws {
        XCTAssertEqual(try PHReference.extract(from: "123456"), .id("123456"))
    }

    func testReferenceFromPostURL() throws {
        XCTAssertEqual(
            try PHReference.extract(from: "https://www.producthunt.com/posts/justvibe-3"),
            .slug("justvibe-3")
        )
    }

    func testReferenceFromProductURL() throws {
        XCTAssertEqual(
            try PHReference.extract(from: "https://www.producthunt.com/products/notion?ref=x"),
            .slug("notion")
        )
    }

    func testReferenceInvalidThrows() {
        XCTAssertThrowsError(try PHReference.extract(from: "not a slug!"))
    }

    // MARK: - HTML

    func testHTMLToPlainText() {
        XCTAssertEqual(PHHTML.toPlainText("<p>a</p><p>b &amp; c</p>"), "a\n\nb & c")
        XCTAssertEqual(
            PHHTML.toPlainText("Check <a href=\"https://x.com\">this</a> &#x27;out&#x27;"),
            "Check this 'out'"
        )
    }

    // MARK: - Post parsing

    func testParsePost() throws {
        let data = try json(Fixture.post)
        let post = try PHParser.post(from: data)

        XCTAssertEqual(post.id, "123")
        XCTAssertEqual(post.slug, "justvibe-3")
        XCTAssertEqual(post.name, "JustVibe")
        XCTAssertEqual(post.tagline, "Vibe coding")
        XCTAssertEqual(post.votesCount, 318)
        XCTAssertEqual(post.commentsCount, 26)
        XCTAssertEqual(post.reviewsRating, 5.0)
        XCTAssertEqual(post.topics, ["Web App", "Search"])
        XCTAssertEqual(post.user?.username, "lianghao")
        XCTAssertEqual(post.thumbnailURL, "https://ph.example/thumb.png")
        XCTAssertNotNil(post.createdAt)
    }

    // MARK: - Comment parsing

    func testParseCommentsPage() throws {
        let data = try json(Fixture.comments)
        let page = try PHParser.commentsPage(from: data)

        XCTAssertFalse(page.hasNextPage)
        XCTAssertEqual(page.comments.count, 2)

        let top = page.comments[0]
        XCTAssertEqual(top.id, "c1")
        XCTAssertEqual(top.votesCount, 16)
        XCTAssertEqual(top.depth, 0)
        XCTAssertNil(top.parentId)
        XCTAssertEqual(top.user?.username, "alice")
        XCTAssertEqual(top.text, "Hey PH 👋\n\nCheck this & that")
        XCTAssertTrue(top.bodyHTML.contains("<p>"))
        XCTAssertEqual(top.replies.count, 1)

        let reply = top.replies[0]
        XCTAssertEqual(reply.id, "c2")
        XCTAssertEqual(reply.depth, 1)
        XCTAssertEqual(reply.parentId, "c1")

        XCTAssertEqual(page.comments.flattened.map(\.id), ["c1", "c2", "c3"])
        XCTAssertEqual(page.comments.totalCount, 3)
    }

    // MARK: - Live tests (opt-in, require a token)

    private var liveConfig: ProductHuntMetadata.Configuration? {
        let env = ProcessInfo.processInfo.environment
        guard env["PH_LIVE_TESTS"] == "1", env["PRODUCT_HUNT_TOKEN"] != nil else { return nil }
        return .default
    }

    func testLivePostWithComments() async throws {
        try XCTSkipUnless(liveConfig != nil, "Set PH_LIVE_TESTS=1 and PRODUCT_HUNT_TOKEN to run.")
        let (post, comments) = try await ProductHuntMetadata.postWithComments(
            "justvibe-3", sortBy: .votes, limit: 20, configuration: liveConfig!
        )
        XCTAssertFalse(post.name.isEmpty)
        XCTAssertGreaterThan(post.votesCount, 0)
        XCTAssertFalse(comments.isEmpty)

        if ProcessInfo.processInfo.environment["PH_PRINT"] == "1" {
            print("=== \(post.name): \(post.tagline ?? "") — \(post.votesCount) votes, \(post.commentsCount) comments ===")
            print("topics: \(post.topics.joined(separator: ", "))")
            for c in comments.flattened.prefix(5) {
                let indent = String(repeating: "  ", count: c.depth)
                print("\(indent)▲\(c.votesCount) \(c.user?.username ?? "?"): \(c.text.prefix(70))")
            }
        }
    }

    func testLivePosts() async throws {
        try XCTSkipUnless(liveConfig != nil, "Set PH_LIVE_TESTS=1 and PRODUCT_HUNT_TOKEN to run.")
        let posts = try await ProductHuntMetadata.posts(order: .ranking, limit: 5, configuration: liveConfig!)
        XCTAssertFalse(posts.isEmpty)
        XCTAssertTrue(posts.allSatisfy { !$0.name.isEmpty })
    }

    // MARK: - Helpers

    private func json(_ string: String) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(string.utf8)) as? [String: Any])
    }
}

// MARK: - Fixtures (mirror the verified GraphQL response shapes)

private enum Fixture {
    static let post = """
    { "post": {
        "id": "123", "slug": "justvibe-3", "name": "JustVibe", "tagline": "Vibe coding",
        "description": "A thing", "votesCount": 318, "commentsCount": 26, "reviewsRating": 5.0,
        "createdAt": "2026-07-01T10:00:00Z", "featuredAt": "2026-07-02T00:00:00Z",
        "url": "https://www.producthunt.com/posts/justvibe-3", "website": "https://justvibe.example",
        "thumbnail": { "url": "https://ph.example/thumb.png" },
        "topics": { "edges": [ { "node": { "name": "Web App" } }, { "node": { "name": "Search" } } ] },
        "user": { "name": "Lianghao", "username": "lianghao", "headline": "Founder" }
    } }
    """

    static let comments = """
    { "post": { "comments": {
        "pageInfo": { "hasNextPage": false, "endCursor": "cursor1" },
        "edges": [
          { "node": {
              "id": "c1",
              "body": "<p>Hey PH 👋</p><p>Check <a href=\\"https://x.com\\">this</a> &amp; that</p>",
              "votesCount": 16, "createdAt": "2026-07-01T11:00:00Z", "parentId": null,
              "user": { "name": "Alice", "username": "alice", "headline": "Maker" },
              "replies": { "edges": [
                { "node": { "id": "c2", "body": "A reply", "votesCount": 2,
                            "createdAt": "2026-07-01T12:00:00Z", "parentId": "c1",
                            "user": { "name": "Bob", "username": "bob" } } }
              ] }
          } },
          { "node": {
              "id": "c3", "body": "Second comment", "votesCount": 0,
              "createdAt": "2026-07-01T13:00:00Z", "parentId": null,
              "user": { "name": "Carol", "username": "carol" }, "replies": { "edges": [] }
          } }
        ]
    } } }
    """
}
