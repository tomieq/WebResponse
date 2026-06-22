//
//  AuthTests.swift
//  WebResponse
//
//  Created by: tomieq on 22/06/2026
//
import WebResponse
import Testing
import Swifter

@Suite(.serialized)
class AuthTests {
    struct ServerResponse: Codable {
        let username: String
    }

    let server = HttpServer()
    var requestCounter = 0

    init() throws {
        try self.server.start(8081)
        self.server.middleware.append { [unowned self] request, header in
            print("Request \(request.id) \(request.method) \(request.path) from \(request.clientIP ?? "")")
            self.requestCounter += 1
            request.onFinished { summary in
                print("Request \(summary.requestID) finished with \(summary.responseCode) [\(summary.responseSize)] in \(String(format: "%.3f", summary.durationInSeconds)) seconds")
            }
            return nil
        }
    }

    deinit {
        server.stop()
    }

    @Test
    func basicAuth() throws {
        self.server.get["/basic"] = { request, _ in
            let basic = BasicAuthentication(credentialsProvider: { login in
                return switch login {
                case "user": "12345"
                default: nil
                }
            })
            if let login = basic.authorizedUser(request) {
                return .ok(.jsonString("{ \"username\": \"\(login)\"}"))
            }
            return .unauthorized(.text("Please authorize with basic"))
        }

        let response = WebResponse<ServerResponse>
            .default
            .withCredentials(.basic(login: "user", password: "12345"))
            .get(url: "http://localhost:8081/basic")
        switch response {
        case .failure(let error):
            Issue.record("Error: \(error)")
        case .response(let body, _):
            #expect(body.username == "user")
            #expect(self.requestCounter == 1)
        }
    }

    @Test
    func basicInvalidCredetials() throws {
        self.server.get["/basic"] = { request, _ in
            let basic = BasicAuthentication(credentialsProvider: { login in
                return switch login {
                case "user": "12345"
                default: nil
                }
            })
            if let login = basic.authorizedUser(request) {
                return .ok(.jsonString("{ \"username\": \"\(login)\"}"))
            }
            return .unauthorized(.text("Please authorize with basic"))
        }

        let response = WebResponse<ServerResponse>
            .default
            .withCredentials(.basic(login: "user", password: "123456"))
            .get(url: "http://localhost:8081/basic")
        switch response {
        case .failure(let error):
            #expect(error == .invalidHttpCode(code: 401, body: "Please authorize with basic"))
            #expect(self.requestCounter == 1)
        case .response(_, _):
            Issue.record("Expected a failure, got a successful response")
        }
    }

    @Test
    func digestAuth() throws {
        self.server.get["/digest"] = { request, _ in
            let digest = DigestAuthentication(realm: "Swifter Digest", credentialsProvider: { login in
                switch login {
                case "user": "12345"
                default: nil
                }
            })
            let login = try digest.authorizedUser(request)
            return .ok(.jsonString("{ \"username\": \"\(login)\"}"))
        }

        let response = WebResponse<ServerResponse>
            .default
            .withCredentials(.digest(login: "user", password: "12345"))
            .get(url: "http://localhost:8081/digest")
        switch response {
        case .failure(let error):
            Issue.record("Error: \(error)")
        case .response(let body, _):
            #expect(body.username == "user")
            #expect(self.requestCounter == 2)
        }
    }

    @Test
    func digestInvalidCredentials() throws {
        self.server.get["/digest"] = { request, _ in
            let digest = DigestAuthentication(realm: "Swifter Digest", credentialsProvider: { login in
                switch login {
                case "user": "12345"
                default: nil
                }
            })
            let login = try digest.authorizedUser(request)
            return .ok(.jsonString("{ \"username\": \"\(login)\"}"))
        }

        let response = WebResponse<ServerResponse>
            .default
            .withCredentials(.digest(login: "user", password: "123456"))
            .get(url: "http://localhost:8081/digest")
        switch response {
        case .failure(let error):
            #expect(error == .invalidHttpCode(code: 401, body: nil))
            #expect(self.requestCounter == 2)
        case .response(let body, _):
            Issue.record("Error, expected 401, got \(body)")
        }
    }
}
