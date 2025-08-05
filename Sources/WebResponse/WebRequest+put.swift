//
//  WebRequest+put.swift
//  WebResponse
//
//  Created by Tomasz on 05/08/2025.
//
import Foundation

public extension WebRequest {
    func put(url: String, body: Encodable, headers: [String: String]? = nil) -> WebResponse<T> {
        run(url: url, method: "PUT", body: body.data, headers: headers)
    }
    
    func put(url: String, body: Encodable, headers: [String: String]? = nil, callback: @escaping @Sendable (WebResponse<T>) -> Void) {
        _ = run(url: url, method: "PUT", body: body.data, headers: headers, callback: callback)
    }
    
    func put(url: String, body: Data, headers: [String: String]? = nil) -> WebResponse<T> {
        run(url: url, method: "PUT", body: body, headers: headers)
    }
    
    func put(url: String, body: Data, headers: [String: String]? = nil, callback: @escaping @Sendable (WebResponse<T>) -> Void) {
        _ = run(url: url, method: "PUT", body: body, headers: headers, callback: callback)
    }
}
