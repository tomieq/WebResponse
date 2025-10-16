import Testing
import WebResponse
import Dispatch

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

@Test func digest() throws {
    let sem = DispatchSemaphore(value: 0)
    DispatchQueue.global().async {
        let response = WebResponse<EmptyBody>.withTimeout(10).get(url: "https://httpbin.org/basic-auth/admin/pass")
        switch response {
        
        case .failure(let error):
            print("Error: \(error)")
        case .response(body: let body, _):
            print(body)
            
        }
        sem.signal()
    }
    _ = sem.wait(timeout: .now() + 12)
}
