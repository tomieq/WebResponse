//
//  WebResquest+run.swift
//  WebResponse
//
//  Created by Tomasz on 05/08/2025.
//
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class URLSessionRequestHandle: @unchecked Sendable {
    private let lock = NSLock()
    private var task: URLSessionTask?
    private var isCancelled = false

    func replaceTask(_ task: URLSessionTask?) {
        self.lock.lock()
        if self.isCancelled {
            task?.cancel()
        } else {
            self.task = task
        }
        self.lock.unlock()
    }

    func cancel() {
        self.lock.lock()
        self.isCancelled = true
        let task = self.task
        self.task = nil
        self.lock.unlock()
        task?.cancel()
    }
}

private final class URLSessionRequestHandleHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var handle: URLSessionRequestHandle?
    private var isCancelled = false

    func set(_ handle: URLSessionRequestHandle?) {
        self.lock.lock()
        if self.isCancelled {
            handle?.cancel()
        } else {
            self.handle = handle
        }
        self.lock.unlock()
    }

    func cancel() {
        self.lock.lock()
        self.isCancelled = true
        let handle = self.handle
        self.handle = nil
        self.lock.unlock()
        handle?.cancel()
    }
}

extension WebRequest {
    private static var defaultHeaders: [String: String] {
        [
            "Content-Type": "application/json",
            "Connection": "close"
        ]
    }

    private func request(url: String, method: String, body: Data?, headers: [String: String]?) -> URLRequest? {
        guard let url = URL(string: url) else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.allHTTPHeaderFields = {
            var allHeaders = Self.defaultHeaders
            for (key, value) in headers ?? [:] {
                allHeaders[key] = value
            }
            if case .basic(let login, let password) = self.credentials {
                let rawValue = "\(login):\(password)"
                let encodedValue = Data(rawValue.utf8).base64EncodedString()
                allHeaders["Authorization"] = "Basic \(encodedValue)"
            }
            return allHeaders
        }()
        return request
    }

    private func sessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = self.timeout
        config.timeoutIntervalForResource = self.timeout
        config.urlCredentialStorage = nil
        #if MACOS
        if let proxy = self.proxy {
            let proxyConfig: [AnyHashable: Any] = [
                kCFNetworkProxiesHTTPSEnable: 1,
                kCFNetworkProxiesHTTPSProxy: proxy.host,
                kCFNetworkProxiesHTTPSPort: proxy.port,

                kCFNetworkProxiesHTTPEnable: 1,
                kCFNetworkProxiesHTTPProxy: proxy.host,
                kCFNetworkProxiesHTTPPort: proxy.port
            ]
            config.connectionProxyDictionary = proxyConfig
        }
        #endif
        return config
    }

    private func response(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        authenticationFailure: HttpError? = nil,
        suppressUnauthorizedBody: Bool = false
    ) -> WebResponse<T> {
        if let error = error as? NSError {
            if error.code == NSURLErrorCancelled,
               let authenticationFailure {
                return .failure(authenticationFailure)
            }
            return .failure(HttpError.make(from: error.code))
        }
        guard let response = (response as? HTTPURLResponse) else {
            return .failure(.other)
        }
        let statusCode = response.statusCode
        let headers = response.allHeaderFields as? [String: String] ?? [:]
        if statusCode >= 200, statusCode < 300 {
            if let data, T.self == Data.self, let body = data as? T {
                return .response(body: body, headers: headers)
            }
            if let json = data {
                if json.isEmpty, T.self == EmptyBody.self, let body = EmptyBody() as? T {
                    return .response(body: body, headers: headers)
                } else if let object = try? T(json: json) {
                    return .response(body: object, headers: headers)
                } else {
                    return .failure(.unserializablaResponse(data))
                }
            } else {
                return .failure(.unserializablaResponse(data))
            }
        } else {
            let body: String?
            if suppressUnauthorizedBody, statusCode == 401 {
                body = nil
            } else {
                body = String(data: data ?? Data(), encoding: .utf8)
            }
            return .failure(.invalidHttpCode(code: statusCode, body: body))
        }
    }

    private func makeSession() -> URLSession {
        URLSession(configuration: self.sessionConfiguration(), delegate: nil, delegateQueue: nil)
    }

    #if MACOS
    private func executeMacOSDigestRequest(
        request: URLRequest,
        handle: URLSessionRequestHandle,
        callback: @escaping (WebResponse<T>) -> Void
    ) {
        let sessionDelegate = WebAuthDelegate(credentials: credentials)
        let session = URLSession(configuration: sessionConfiguration(), delegate: sessionDelegate, delegateQueue: nil)
        let task = session.dataTask(with: request) { data, response, error in
            callback(self.response(
                data: data,
                response: response,
                error: error,
                authenticationFailure: sessionDelegate.authenticationFailure
            ))
        }
        handle.replaceTask(task)
        task.resume()
    }
    #endif

    private func execute(
        request: URLRequest,
        using session: URLSession,
        handle: URLSessionRequestHandle,
        callback: @escaping (WebResponse<T>) -> Void
    ) {
        let task = session.dataTask(with: request) { data, response, error in
            if let retryRequest = self.digestRetryRequest(for: request, response: response, error: error) {
                self.executeDigestRetry(
                    request: retryRequest,
                    using: session,
                    handle: handle,
                    callback: callback
                )
                return
            }

            callback(self.response(data: data, response: response, error: error))
        }
        handle.replaceTask(task)
        task.resume()
    }

    private func executeDigestRetry(
        request: URLRequest,
        using session: URLSession,
        handle: URLSessionRequestHandle,
        callback: @escaping (WebResponse<T>) -> Void
    ) {
        let task = session.dataTask(with: request) { data, response, error in
            callback(self.response(
                data: data,
                response: response,
                error: error,
                suppressUnauthorizedBody: true
            ))
        }
        handle.replaceTask(task)
        task.resume()
    }

    private func digestRetryRequest(
        for request: URLRequest,
        response: URLResponse?,
        error: Error?
    ) -> URLRequest? {
        guard error == nil,
              let credentials,
              case .digest = credentials,
              request.value(forHTTPHeaderField: "Authorization") == nil,
              let response = response as? HTTPURLResponse,
              response.statusCode == 401,
              let authorizationHeader = WebDigestAuthorization.authorizationHeader(
                  for: request,
                  response: response,
                  credentials: credentials
              ) else {
            return nil
        }

        var retryRequest = request
        retryRequest.setValue(authorizationHeader, forHTTPHeaderField: "Authorization")
        return retryRequest
    }

    func run(url: String, method: String, body: Data? = nil, headers: [String: String]? = nil) -> WebResponse<T> {
        let semaphore = DispatchSemaphore(value: 0)
        var result: WebResponse<T>?
        let requestHandle = self.run(url: url, method: method, body: body, headers: headers) {
            result = $0
            semaphore.signal()
        }
        let waitResult = semaphore.wait(timeout: .now() + .seconds(Int(self.timeout)))
        if case .timedOut = waitResult {
            print("Request timed out")
            requestHandle?.cancel()
            return .failure(.timeoutError)
        }
        return result ?? .failure(.other)
    }

    func run(url: String,
             method: String,
             body: Data? = nil,
             headers: [String: String]? = nil,
             callback: @escaping (WebResponse<T>) -> Void) -> URLSessionRequestHandle? {
        guard let request = request(url: url, method: method, body: body, headers: headers) else {
            callback(.failure(.invalidUrl))
            return nil
        }
        let handle = URLSessionRequestHandle()
        #if MACOS
        if let credentials, case .digest = credentials {
            self.executeMacOSDigestRequest(request: request, handle: handle, callback: callback)
            return handle
        }
        #endif
        let session = self.makeSession()
        self.execute(request: request, using: session, handle: handle, callback: callback)
        return handle
    }

    func run(url: String, method: String, body: Data? = nil, headers: [String: String]? = nil) async -> WebResponse<T> {
        let handleHolder = URLSessionRequestHandleHolder()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let handle = self.run(url: url, method: method, body: body, headers: headers) { response in
                    continuation.resume(returning: response)
                }
                handleHolder.set(handle)
            }
        } onCancel: {
            handleHolder.cancel()
        }
    }
}
