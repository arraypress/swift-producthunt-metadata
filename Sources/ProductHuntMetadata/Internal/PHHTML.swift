//
//  PHHTML.swift
//  ProductHuntMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Converts Product Hunt comment HTML into readable plain text.
///
/// Comment bodies use a small HTML subset (`<p>` paragraphs, `<a>` links) plus
/// HTML entities. This preserves paragraph breaks and link text while stripping
/// markup and decoding entities.
enum PHHTML {

    /// Renders comment HTML as plain text with paragraph breaks preserved.
    static func toPlainText(_ html: String) -> String {
        var text = html
        text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<p>", with: "", options: .caseInsensitive)
        text = replaceRegex(#"<a\b[^>]*>(.*?)</a>"#, in: text, template: "$1")
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        return unescape(text).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Decodes HTML entities (named, decimal `&#123;`, and hex `&#x1F;`).
    static func unescape(_ input: String) -> String {
        var text = input
        let named: [(String, String)] = [
            ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
            ("&#x27;", "'"), ("&#39;", "'"), ("&#x2F;", "/"), ("&apos;", "'"), ("&nbsp;", " ")
        ]
        for (entity, replacement) in named {
            text = text.replacingOccurrences(of: entity, with: replacement)
        }
        text = decodeNumericEntities(text)
        text = text.replacingOccurrences(of: "&amp;", with: "&")
        return text
    }

    private static func decodeNumericEntities(_ input: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"&#(x?)([0-9a-fA-F]+);"#) else { return input }
        let ns = input as NSString
        var result = input
        for match in regex.matches(in: input, range: NSRange(location: 0, length: ns.length)).reversed() {
            let isHex = ns.substring(with: match.range(at: 1)) == "x"
            let digits = ns.substring(with: match.range(at: 2))
            guard let code = UInt32(digits, radix: isHex ? 16 : 10),
                  let scalar = Unicode.Scalar(code),
                  let range = Range(match.range, in: result) else { continue }
            result.replaceSubrange(range, with: String(Character(scalar)))
        }
        return result
    }

    private static func replaceRegex(_ pattern: String, in text: String, template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { return text }
        return regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
    }
}
