//
//  SupportTests.swift
//  ProductHuntMetadataTests
//
//  Created by David Sherlock on 2026.
//
//  The reference parser pinned directly.
//

import XCTest
@testable import ProductHuntMetadata

final class SupportTests: XCTestCase {

    func testReferenceParserEdges() throws {
        XCTAssertEqual(try PHReference.extract(from: "12345"), .id("12345"))
        XCTAssertEqual(try PHReference.extract(from: "https://www.producthunt.com/products/justvibe-3?utm=x"), .slug("justvibe-3"))
        XCTAssertEqual(try PHReference.extract(from: "justvibe-3"), .slug("justvibe-3"))
        XCTAssertThrowsError(try PHReference.extract(from: "not a slug!"))
    }
}
