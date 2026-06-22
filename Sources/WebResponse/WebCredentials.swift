//
//  WebCredentials.swift
//  WebResponse
//
//  Created by: tomieq on 22/06/2026
//

public enum WebCredentials: Sendable {
    case basic(login: String, password: String)
    case digest(login: String, password: String)
}

extension WebCredentials {
    var login: String {
        switch self {
        case .basic(login: let login, _), .digest(login: let login, _):
            return login
        }
    }

    var password: String {
        switch self {
        case .basic(_, let password), .digest(_, let password):
            return password
        }
    }
}
