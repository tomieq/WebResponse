import Foundation

public typealias WebObject = Decodable

public struct EmptyBody: Decodable {}

public enum WebResponse<T: WebObject> {
    case failure(HttpError)
    case response(body: T?, headers: [String: String])
    
    public static var `default`: WebRequest<T> {
        WebRequest()
    }
    
    public static func withTimeout(_ timeout: TimeInterval) -> WebRequest<T> {
        WebRequest(timeout: timeout)
    }
}



