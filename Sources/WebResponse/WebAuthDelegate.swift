//
//  WebAuthDelegate.swift
//  WebResponse
//
//  Created by: tomieq on 22/06/2026
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if MACOS
final class WebAuthDelegate: NSObject, URLSessionTaskDelegate {
    private let credentials: WebCredentials?
    private let lock = NSLock()
    private var authenticationFailureStatusCode: Int?

    init(credentials: WebCredentials?) {
        self.credentials = credentials
    }

    var authenticationFailure: HttpError? {
        self.lock.lock()
        let statusCode = self.authenticationFailureStatusCode
        self.lock.unlock()

        guard let statusCode else {
            return nil
        }
        return .invalidHttpCode(code: statusCode, body: nil)
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let credentials, case .digest = credentials else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPDigest else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard challenge.previousFailureCount == 0 else {
            self.lock.lock()
            self.authenticationFailureStatusCode = (challenge.failureResponse as? HTTPURLResponse)?.statusCode
            self.lock.unlock()
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let credential = URLCredential(user: credentials.login,
                                       password: credentials.password,
                                       persistence: .none)
        completionHandler(.useCredential, credential)
    }
}
#endif