//
//  WebResquest+run.swift
//  WebResponse
//
//  Created by Tomasz on 05/08/2025.
//
import Foundation

extension WebRequest {
    private static var defaultHeaders: [String: String] {
        ["Content-Type": "application/json"]
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
        guard let url = URL(string: url) else {
            callback(.failure(.invalidUrl))
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
            return allHeaders
        }()
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = self.timeout
        config.timeoutIntervalForResource = self.timeout
        let task = URLSession(configuration: config).dataTask(with: request) { data, response, error in
            if let error = error as? NSError {
                let httpError = HttpError.make(from: error.code)
                callback(.failure(httpError))
                return
            }
            guard let response = (response as? HTTPURLResponse) else {
                callback(.failure(.other))
                return
            }
            let statusCode = response.statusCode
            let headers = response.allHeaderFields as? [String: String] ?? [:]
            if statusCode >= 200, statusCode < 300 {
                if let json = data {
                    if json.isEmpty, "\(T.self)" == "\(EmptyBody.self)" {
                        callback(.response(body: try! .init(json: "{}"), headers: headers))
                    } else
                    if let object = try? T(json: json) {
                        callback(.response(body: object, headers: headers))
                    } else {
                        callback(.failure(.unserializablaResponse(data)))
                    }
                } else {
                    callback(.failure(.unserializablaResponse(data)))
                }
            } else {
                let body = String(data: data ?? Data(), encoding: .utf8)
                callback(.failure(.invalidHttpCode(code: statusCode, body: body)))
            }
        }
        task.resume()
        return task
    }
}
