//
//  GraphQLClient.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Minimal GraphQL transport for the Product Hunt API, including bearer-token
/// resolution (a supplied token, or a cached `client_credentials` exchange).
enum GraphQLClient {

    static let endpoint = "https://api.producthunt.com/v2/api/graphql"
    static let tokenEndpoint = "https://api.producthunt.com/v2/oauth/token"
    static let userAgent = "swift-producthunt-metadata (https://github.com/arraypress)"

    /// Process-wide cache for tokens obtained via `client_credentials`.
    private actor TokenCache {
        private var token: String?
        func get() -> String? { token }
        func set(_ value: String) { token = value }
    }
    private static let cache = TokenCache()

    // MARK: - Query execution

    /// Executes a GraphQL query and returns its `data` object.
    static func execute(
        query: String,
        variables: [String: Any] = [:],
        configuration: ProductHuntMetadata.Configuration
    ) async throws -> [String: Any] {
        let token = try await resolveToken(configuration)

        guard let url = URL(string: endpoint) else {
            throw ProductHuntMetadataError.networkError("Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let body: [String: Any] = variables.isEmpty
            ? ["query": query]
            : ["query": query, "variables": variables]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw ProductHuntMetadataError.parsingError("Failed to encode GraphQL body")
        }

        let data = try await send(request)

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw ProductHuntMetadataError.parsingError("Invalid GraphQL JSON response")
        }

        if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
            let messages = errors.compactMap { $0["message"] as? String }.joined(separator: "; ")
            throw ProductHuntMetadataError.apiError(messages.isEmpty ? "Unknown GraphQL error" : messages)
        }

        guard let dataObject = json["data"] as? [String: Any] else {
            throw ProductHuntMetadataError.parsingError("GraphQL response missing 'data'")
        }
        return dataObject
    }

    // MARK: - Token resolution

    private static func resolveToken(_ configuration: ProductHuntMetadata.Configuration) async throws -> String {
        if let token = configuration.token, !token.isEmpty {
            return token
        }
        if let cached = await cache.get() {
            return cached
        }
        guard let clientID = configuration.clientID, !clientID.isEmpty,
              let clientSecret = configuration.clientSecret, !clientSecret.isEmpty else {
            throw ProductHuntMetadataError.missingToken
        }
        let token = try await exchangeClientCredentials(clientID: clientID, clientSecret: clientSecret)
        await cache.set(token)
        return token
    }

    /// Exchanges a Confidential app's credentials for a `client_credentials`
    /// access token (read-only `public` scope).
    private static func exchangeClientCredentials(clientID: String, clientSecret: String) async throws -> String {
        guard let url = URL(string: tokenEndpoint) else {
            throw ProductHuntMetadataError.networkError("Invalid token URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let payload: [String: Any] = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "grant_type": "client_credentials"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        let data = try await send(request)
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let token = json["access_token"] as? String else {
            throw ProductHuntMetadataError.notAuthorized
        }
        return token
    }

    // MARK: - Networking

    private static func send(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ProductHuntMetadataError.networkError(error.localizedDescription)
        }
        if let http = response as? HTTPURLResponse {
            switch http.statusCode {
            case 200..<300: break
            case 401: throw ProductHuntMetadataError.notAuthorized
            case 429: throw ProductHuntMetadataError.rateLimited
            default: throw ProductHuntMetadataError.networkError("HTTP \(http.statusCode)")
            }
        }
        return data
    }
}
