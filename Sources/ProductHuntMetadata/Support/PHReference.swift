//
//  PHReference.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//
//  The post-reference parser: slugs, numeric IDs, and producthunt.com
//  URLs. A parser is Support, not a vocabulary — it moved here from the
//  Enums file so the rules are where rules live, pinned directly.
//

import Foundation

/// A reference to a Product Hunt post — either a slug or a numeric ID.
///
/// Accepts raw slugs/IDs and `producthunt.com/posts/<slug>` (or `/products/<slug>`) URLs.
public enum PHReference: Sendable, Equatable {
    case slug(String)
    case id(String)

    /// Extracts a post reference from a slug, numeric ID, or Product Hunt URL.
    public static func extract(from input: String) throws -> PHReference {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Numeric ID
        if trimmed.range(of: "^[0-9]+$", options: .regularExpression) != nil {
            return .id(trimmed)
        }

        // producthunt.com/posts/<slug> or /products/<slug>
        if let slug = firstMatch(#"producthunt\.com/(?:posts|products)/([^/?#]+)"#, in: trimmed) {
            return .slug(slug)
        }

        // Bare slug
        if trimmed.range(of: "^[a-zA-Z0-9][a-zA-Z0-9-]*$", options: .regularExpression) != nil {
            return .slug(trimmed)
        }

        throw ProductHuntMetadataError.invalidInput
    }

    private static func firstMatch(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
