//
//  ProductHuntMetadataError.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when calling the Product Hunt API.
///
/// ```swift
/// do {
///     let product = try await ProductHuntMetadata.product("notion")
/// } catch ProductHuntMetadataError.missingToken {
///     print("Set PRODUCT_HUNT_TOKEN or pass a token in the configuration")
/// } catch ProductHuntMetadataError.rateLimited {
///     print("Complexity budget exhausted — wait before retrying")
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum ProductHuntMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// No access token was provided (neither in the configuration nor via the
    /// `PRODUCT_HUNT_TOKEN` environment variable).
    case missingToken

    /// The token is missing, expired, or invalid (`401`).
    case notAuthorized

    /// The Product Hunt API's complexity rate limit has been exceeded (`429`).
    case rateLimited

    /// The requested item (product, post, user…) was not found.
    case itemNotFound

    /// The provided input could not be parsed into a Product Hunt slug or ID.
    case invalidInput

    /// The GraphQL response contained an `errors` array.
    case apiError(String)

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the API response.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .missingToken:
            return "No Product Hunt access token. Set the PRODUCT_HUNT_TOKEN environment variable or pass a token in the configuration."
        case .notAuthorized:
            return "Product Hunt rejected the access token (401). It may be missing, expired, or invalid."
        case .rateLimited:
            return "Product Hunt is rate-limiting requests (complexity budget exceeded). Try again shortly."
        case .itemNotFound:
            return "The requested Product Hunt item was not found."
        case .invalidInput:
            return "Could not parse a Product Hunt slug or ID from the input."
        case .apiError(let message):
            return "Product Hunt API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
