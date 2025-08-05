import Testing
import WebResponse
import Dispatch

@Test func example() throws {
    struct SampleDto: Codable {
        let id: Int
        let title: String
    }
    
    let sem = DispatchSemaphore(value: 0)
    DispatchQueue.global().async {
//        WebResponse<EmptyBody>.default.get(url: "https://jsonplaceholder.typicode.com/todos/1") { result in
//            
//        }
        let response = WebResponse<SampleDto>.withTimeout(3).get(url: "https://jsonplaceholder.typicode.com/todos/1")
        switch response {
        
        case .failure(let error):
            print("Error: \(error)")
        case .response(body: let body, headers: let headers):
            print(body)
            
        }
        sem.signal()
    }
    sem.wait(timeout: .now() + 4)
}
