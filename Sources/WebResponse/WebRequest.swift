//
//  WebResquest.swift
//  WebResponse
//
//  Created by Tomasz on 05/08/2025.
//
import Foundation

public struct WebRequest<T: WebObject>: Sendable {
    let timeout: TimeInterval
    let proxy: WebProxy?
    
    init(timeout: TimeInterval = 3, proxy: WebProxy? = nil) {
        self.timeout = timeout
        self.proxy = proxy
    }
    
    public func withProxy(host: String, port: Int) -> WebRequest<T> {
        WebRequest(timeout: self.timeout, proxy: WebProxy(host: host, port: port))
    }
    
    public func withTimeout(_ timeout: TimeInterval) -> WebRequest<T> {
        WebRequest(timeout: timeout, proxy: self.proxy)
    }
}
