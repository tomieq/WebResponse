//
//  PortManager.swift
//  WebResponse
//
//  Created by: tomieq on 23/06/2026
//

actor PortManager {
    static let shared = PortManager()
    private var port: UInt16 = 8081

    private init() {}

    var openPort: UInt16 {
        defer {
            port = port + 1
        }
        return self.port
    }
}
