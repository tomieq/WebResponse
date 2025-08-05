//
//  WebResquest.swift
//  WebResponse
//
//  Created by Tomasz on 05/08/2025.
//
import Foundation

public struct WebRequest<T: WebObject>: Sendable {
    let timeout: TimeInterval
    
    init(timeout: TimeInterval = 3) {
        self.timeout = timeout
    }
}
