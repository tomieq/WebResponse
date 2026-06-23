#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum WebDigestAuthorization {
    static func authorizationHeader(
        for request: URLRequest,
        response: HTTPURLResponse,
        credentials: WebCredentials
    ) -> String? {
        guard case .digest(let login, let password) = credentials,
              let challenge = DigestChallenge.make(from: response),
              let url = request.url,
              let algorithm = challenge.supportedAlgorithm,
              let digestURI = digestURI(for: url) else {
            return nil
        }

        let method = request.httpMethod ?? "GET"
        let cnonce = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let nonceCount = "00000001"

        let ha1: String = {
            let digest = self.md5("\(login):\(challenge.realm):\(password)")
            if algorithm == .md5Sess {
                return self.md5("\(digest):\(challenge.nonce):\(cnonce)")
            }
            return digest
        }()
        let ha2 = self.md5("\(method):\(digestURI)")

        let responseDigest: String = {
            if let qop = challenge.selectedQop {
                return self.md5("\(ha1):\(challenge.nonce):\(nonceCount):\(cnonce):\(qop):\(ha2)")
            }
            return self.md5("\(ha1):\(challenge.nonce):\(ha2)")
        }()

        var components = [
            "username=\"\(escaped(login))\"",
            "realm=\"\(escaped(challenge.realm))\"",
            "nonce=\"\(self.escaped(challenge.nonce))\"",
            "uri=\"\(self.escaped(digestURI))\"",
            "response=\"\(responseDigest)\""
        ]

        if let algorithmName = challenge.algorithmName {
            components.append("algorithm=\(algorithmName)")
        }

        if let opaque = challenge.opaque {
            components.append("opaque=\"\(self.escaped(opaque))\"")
        }

        if let qop = challenge.selectedQop {
            components.append("qop=\(qop)")
            components.append("nc=\(nonceCount)")
            components.append("cnonce=\"\(cnonce)\"")
        }

        return "Digest \(components.joined(separator: ", "))"
    }

    private static func digestURI(for url: URL) -> String? {
        let path = url.path.isEmpty ? "/" : url.path
        if let query = url.query, !query.isEmpty {
            return "\(path)?\(query)"
        }
        return path
    }

    private static func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func md5(_ value: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(value.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

private extension WebDigestAuthorization {
    struct DigestChallenge {
        enum Algorithm {
            case md5
            case md5Sess
        }

        let realm: String
        let nonce: String
        let opaque: String?
        let algorithmName: String?
        let supportedAlgorithm: Algorithm?
        let selectedQop: String?

        static func make(from response: HTTPURLResponse) -> DigestChallenge? {
            guard let headerValue = response.value(forHTTPHeaderField: "WWW-Authenticate"),
                  headerValue.lowercased().hasPrefix("digest ") else {
                return nil
            }

            let rawParameters = String(headerValue.dropFirst("Digest ".count))
            let parameters = self.parseParameters(rawParameters)

            guard let realm = parameters["realm"],
                  let nonce = parameters["nonce"] else {
                return nil
            }

            let algorithmName = parameters["algorithm"]
            let supportedAlgorithm: Algorithm? = {
                guard let algorithmName else {
                    return .md5
                }
                switch algorithmName.lowercased() {
                case "md5":
                    return .md5
                case "md5-sess":
                    return .md5Sess
                default:
                    return nil
                }
            }()

            let selectedQop: String? = {
                guard let qopValue = parameters["qop"] else {
                    return nil
                }

                let values = qopValue
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

                if values.contains("auth") {
                    return "auth"
                }
                if values.isEmpty {
                    return nil
                }
                return nil
            }()

            if parameters["qop"] != nil, selectedQop == nil {
                return nil
            }

            return DigestChallenge(
                realm: realm,
                nonce: nonce,
                opaque: parameters["opaque"],
                algorithmName: algorithmName,
                supportedAlgorithm: supportedAlgorithm,
                selectedQop: selectedQop
            )
        }

        private static func parseParameters(_ value: String) -> [String: String] {
            var parameters: [String: String] = [:]
            var current = ""
            var isInsideQuotes = false
            var isEscaping = false

            func commitCurrent() {
                let part = current.trimmingCharacters(in: .whitespacesAndNewlines)
                defer { current.removeAll(keepingCapacity: true) }
                guard !part.isEmpty,
                      let separatorIndex = part.firstIndex(of: "=") else {
                    return
                }

                let key = part[..<separatorIndex]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                var value = String(part[part.index(after: separatorIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if value.hasPrefix("\""), value.hasSuffix("\""), value.count >= 2 {
                    value.removeFirst()
                    value.removeLast()
                }

                parameters[key] = value
            }

            for character in value {
                if character == "\\", !isEscaping {
                    isEscaping = true
                    current.append(character)
                    continue
                }

                if character == "\"", !isEscaping {
                    isInsideQuotes.toggle()
                    current.append(character)
                    continue
                }

                if character == ",", !isInsideQuotes {
                    commitCurrent()
                    isEscaping = false
                    continue
                }

                current.append(character)
                isEscaping = false
            }

            commitCurrent()
            return parameters
        }
    }
}

private extension HTTPURLResponse {
    func value(forHTTPHeaderField field: String) -> String? {
        for (key, value) in allHeaderFields {
            guard let key = key as? String,
                  key.caseInsensitiveCompare(field) == .orderedSame else {
                continue
            }
            return value as? String
        }
        return nil
    }
}