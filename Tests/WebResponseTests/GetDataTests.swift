//
//  GetDataTests.swift
//  WebResponse
//
//  Created by: tomieq on 22/06/2026
//

import WebResponse
import Testing
import Swifter
import Foundation

@Suite(.serialized)
class GetDataTests {
    let server = HttpServer()

    init() throws {
        try self.server.start(8082)
        self.server.middleware.append { request, header in
            print("Request \(request.id) \(request.method) \(request.path) from \(request.clientIP ?? "")")
            request.onFinished { summary in
                print("Request \(summary.requestID) finished with \(summary.responseCode) [\(summary.responseSize)] in \(String(format: "%.3f", summary.durationInSeconds)) seconds")
            }
            return nil
        }
    }

    deinit {
        server.stop()
    }

    @Test
    func getData() throws {
        self.server.get["/data"] = { request, _ in
            .raw(200, "OK") { writer in
                try writer.write(Data([0x52]))
            }
        }

        let response = WebResponse<Data>
            .default
            .get(url: "http://localhost:8082/data")
        switch response {
        case .failure(let error):
            Issue.record("Error: \(error)")
        case .response(let body, _):
            #expect(body == Data([0x52]))
        }
    }
}
