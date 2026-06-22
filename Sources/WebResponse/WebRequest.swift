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
    let credentials: WebCredentials?

    init(timeout: TimeInterval = 3,
         proxy: WebProxy? = nil,
         credentials: WebCredentials? = nil) {
        self.timeout = timeout
        self.proxy = proxy
        self.credentials = credentials
    }

    public func withTimeout(_ timeout: TimeInterval) -> WebRequest<T> {
        WebRequest(timeout: timeout, proxy: self.proxy, credentials: self.credentials)
    }

    public func withCredentials(_ credentials: WebCredentials) -> WebRequest<T> {
        WebRequest(timeout: self.timeout, proxy: self.proxy, credentials: credentials)
    }
}

#if MACOS
public extension WebRequest {
    func withProxy(host: String, port: Int) -> WebRequest<T> {
        WebRequest(timeout: self.timeout,
                   proxy: WebProxy(host: host, port: port),
                   credentials: self.credentials)
    }
}
#endif
