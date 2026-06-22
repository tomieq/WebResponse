import Testing
import WebResponse
import Dispatch
import Foundation

@Test(.disabled())
func example() throws {
    struct SampleDto: Codable {
        let id: Int
        let title: String
    }

    let sem = DispatchSemaphore(value: 0)
    DispatchQueue.global().async {
//        WebResponse<EmptyBody>.default.get(url: "https://jsonplaceholder.typicode.com/todos/1") { result in
//
//        }
        let response = WebResponse<SampleDto>.withTimeout(4).get(url: "https://jsonplaceholder.typicode.com/todos/1")
        switch response {
        case .failure(let error):
            print("Error: \(error)")
        case .response(body: let body, _):
            print(body)
        }
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 4)
}

@Test func asyncGetReturnsInvalidUrl() async throws {
    let response = await WebResponse<EmptyBody>.default.get(url: "http://[::1")

    guard case .failure(.invalidUrl) = response else {
        Issue.record("Expected invalid URL failure")
        return
    }
}

@Test func asyncPostReturnsInvalidUrl() async throws {
    let response = await WebResponse<EmptyBody>.default.post(url: "http://[::1", body: Data())

    guard case .failure(.invalidUrl) = response else {
        Issue.record("Expected invalid URL failure")
        return
    }
}

@Test func asyncPutReturnsInvalidUrl() async throws {
    let response = await WebResponse<EmptyBody>.default.put(url: "http://[::1", body: Data())

    guard case .failure(.invalidUrl) = response else {
        Issue.record("Expected invalid URL failure")
        return
    }
}
