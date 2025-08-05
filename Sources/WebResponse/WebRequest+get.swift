//
//  WebResquest+get.swift
//  WebResponse
//
//  Created by Tomasz on 05/08/2025.
//

public extension WebRequest {
    func get(url: String, headers: [String: String]? = nil) -> WebResponse<T> {
        run(url: url, method: "GET", headers: headers)
    }
    
    func get(url: String, headers: [String: String]? = nil, callback: @escaping @Sendable (WebResponse<T>) -> Void) {
        _ = run(url: url, method: "GET", headers: headers, callback: callback)
    }
}
