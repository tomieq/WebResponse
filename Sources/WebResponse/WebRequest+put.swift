//
//  WebRequest+put.swift
//  WebResponse
//
//  Created by Tomasz on 05/08/2025.
//

public extension WebRequest {
    func put(url: String, headers: [String: String]? = nil) -> WebResponse<T> {
        run(url: url, method: "PUT", headers: headers)
    }
    
    func put(url: String, headers: [String: String]? = nil, callback: @escaping @Sendable (WebResponse<T>) -> Void) {
        _ = run(url: url, method: "PUT", headers: headers, callback: callback)
    }
}
