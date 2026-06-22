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

private final class URLSessionDataTaskHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var task: URLSessionDataTask?
    private var isCancelled = false

    func set(_ task: URLSessionDataTask?) {
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
        sessionDelegate: WebAuthDelegate
    ) -> WebResponse<T> {
        if let error = error as? NSError {
            if error.code == NSURLErrorCancelled,
               let authenticationFailure = sessionDelegate.authenticationFailure {
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
            let body = String(data: data ?? Data(), encoding: .utf8)
            return .failure(.invalidHttpCode(code: statusCode, body: body))
        }
    }

    func run(url: String, method: String, body: Data? = nil, headers: [String: String]? = nil) -> WebResponse<T> {
        let semaphore = DispatchSemaphore(value: 0)
        var result: WebResponse<T>?
        let task = self.run(url: url, method: method, body: body, headers: headers) {
            result = $0
            semaphore.signal()
        }
        let waitResult = semaphore.wait(timeout: .now() + .seconds(Int(self.timeout)))
        if case .timedOut = waitResult {
            print("Request timed out")
            task?.cancel()
            return .failure(.timeoutError)
        }
        return result ?? .failure(.other)
    }

    func run(url: String,
             method: String,
             body: Data? = nil,
             headers: [String: String]? = nil,
             callback: @escaping (WebResponse<T>) -> Void) -> URLSessionDataTask? {
        guard let request = request(url: url, method: method, body: body, headers: headers) else {
            callback(.failure(.invalidUrl))
            return nil
        }
        let sessionDelegate = WebAuthDelegate(credentials: credentials)
        let session = URLSession(configuration: sessionConfiguration(), delegate: sessionDelegate, delegateQueue: nil)
        let task: URLSessionDataTask = session.dataTask(with: request) { data, response, error in
            callback(self.response(data: data, response: response, error: error, sessionDelegate: sessionDelegate))
        }
        task.resume()
        return task
    }

    func run(url: String, method: String, body: Data? = nil, headers: [String: String]? = nil) async -> WebResponse<T> {
        let taskHolder = URLSessionDataTaskHolder()
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let task = self.run(url: url, method: method, body: body, headers: headers) { response in
                    continuation.resume(returning: response)
                }
                taskHolder.set(task)
            }
        } onCancel: {
            taskHolder.cancel()
        }
    }
}
