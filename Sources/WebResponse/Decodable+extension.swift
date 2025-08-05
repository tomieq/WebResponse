//
//  Decodable+extension.swift
//  WebResponse
//
//  Created by Tomasz on 05/08/2025.
//

import Foundation

extension Decodable {
    init(json: String) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: json.data(using: .utf8)!)
    }

    init(json: Data) throws {
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: json)
    }
}
