# WebResponse

WebResponse is a simple Swift library acting as an HTTP client. It is a thin wrapper over `URLSessionDataTask` with synchronous, async/await, and closure-based APIs.

## Usage

### GET

```swift
struct SampleDto: Codable {
    let id: Int
    let title: String
    let body: String
}

let response = WebResponse<SampleDto>.default.get(url: "https://jsonplaceholder.typicode.com/todos/1")

switch response {
case .response(let body, let headers):
    print(body)
    print(headers)
case .failure(let error):
    print(error)
}
```

### Async/await

Async methods are available for `GET`, `POST`, and `PUT`:

```swift
struct UpdateItemRequest: Codable {
    let title: String
    let body: String
}

let request = UpdateItemRequest(title: "Hello", body: "World")

let getResponse = await WebResponse<SampleDto>.default.get(url: "https://example.com/items/1")

let postResponse = await WebResponse<SampleDto>.default.post(
    url: "https://example.com/items",
    body: request
)

let putResponse = await WebResponse<SampleDto>.default.put(
    url: "https://example.com/items/1",
    body: request
)
```

Async calls return `WebResponse<T>` and do not throw. Network, HTTP, and decoding errors are returned as `.failure(HttpError)`.

### Custom headers

All request methods accept an optional `headers` parameter:

```swift
let response = WebResponse<SampleDto>.default.get(
    url: "https://example.com/resource",
    headers: ["Accept": "application/json", "X-Custom": "value"]
)

let postResponse = await WebResponse<SampleDto>.default.post(
    url: "https://example.com/items",
    body: request,
    headers: ["Authorization": "Bearer token"]
)
```

### Closure version

```swift
WebResponse<SampleDto>.default.get(url: "https://jsonplaceholder.typicode.com/todos/1") { result in
    switch result {
    case .response(let body, _):
        print(body)
    case .failure(let error):
        print(error)
    }
}
```

Closure-based callbacks are also available for POST and PUT, with both `Encodable` and `Data` body types:

```swift
WebResponse<SampleDto>.default.post(
    url: "https://example.com/items",
    body: request
) { result in
    switch result {
    case .response(let body, _): print(body)
    case .failure(let error): print(error)
    }
}

WebResponse<SampleDto>.default.put(
    url: "https://example.com/items/1",
    body: Data()
) { result in
    // handle result
}
```

### POST and PUT

```swift
struct CreatePostRequest: Codable {
    let title: String
    let body: String
}

let request = CreatePostRequest(title: "Hello", body: "World")

let postResponse = WebResponse<SampleDto>.default.post(
    url: "https://example.com/posts",
    body: request
)

let putResponse = WebResponse<SampleDto>.default.put(
    url: "https://example.com/posts/1",
    body: request
)
```

You can also pass raw `Data` as the request body. Async and closure variants are available as well:

```swift
let response = WebResponse<SampleDto>.default.post(
    url: "https://example.com/posts",
    body: Data()
)

let asyncResponse = await WebResponse<SampleDto>.default.put(
    url: "https://example.com/posts/1",
    body: Data()
)

WebResponse<SampleDto>.default.post(
    url: "https://example.com/posts",
    body: Data()
) { result in
    // handle result
}
```

### Custom timeout

```swift
let response = WebResponse<SampleDto>.withTimeout(3).get(url: "https://jsonplaceholder.typicode.com/todos/1")
```

### Use proxy

Proxy configuration is available on macOS.

```swift
let response = WebResponse<SampleDto>
    .withTimeout(3)
    .withProxy(host: "localhost", port: 3128)
    .get(url: "https://jsonplaceholder.typicode.com/todos/1")
```

### Authentication

The library supports HTTP Basic and Digest authentication.

```swift
// Basic auth
let basicResponse = WebResponse<SampleDto>.default
    .withCredentials(.basic(login: "user", password: "pass"))
    .get(url: "https://example.com/protected")

// Digest auth (macOS only)
let digestResponse = WebResponse<SampleDto>.default
    .withCredentials(.digest(login: "user", password: "pass"))
    .get(url: "https://example.com/digest-protected")
```

`withCredentials` can be chained with other modifiers:

```swift
let response = WebResponse<SampleDto>
    .withTimeout(5)
    .withCredentials(.basic(login: "user", password: "pass"))
    .get(url: "https://example.com/protected")
```

### Empty response

Use `EmptyBody` when the endpoint returns an empty response body.

```swift
let response = WebResponse<EmptyBody>.withTimeout(3).get(url: "https://jsonplaceholder.typicode.com/todos/1")
```

### Raw Data response

Use `WebResponse<Data>` when you need the raw response bytes instead of decoding JSON:

```swift
let response = WebResponse<Data>.default.get(url: "https://example.com/image.jpg")
switch response {
case .response(let body, _):
    print("Got \(body.count) bytes")
case .failure(let error):
    print(error)
}
```

### Error handling

All methods return `WebResponse<T>` containing either `.response(body:headers:)` or `.failure(HttpError)`. The possible error cases are:

| Error | Description |
|-------|-------------|
| `.invalidUrl` | The provided URL string could not be parsed |
| `.timeoutError` | Request timed out |
| `.noInternet` | No internet connection or network was lost |
| `.dnsError` | DNS lookup failed |
| `.serverIsDown` | Cannot connect to the host |
| `.sslError` | SSL/TLS error (untrusted certificate, etc.) |
| `.invalidHttpCode(code, body)` | Non-2xx HTTP status code with optional response body |
| `.proxyError` | Proxy connection error |
| `.unserializablaResponse(Data?)` | Response could not be decoded into the expected type |
| `.other` | An unspecified error occurred |

## Swift Package Manager

```swift
import PackageDescription

let package = Package(
    name: "MyServer",
    dependencies: [
        .package(url: "https://github.com/tomieq/WebResponse.git", branch: "master")
    ]
)
```

In the target:

```swift
targets: [
    .executableTarget(
        name: "AppName",
        dependencies: [
            .product(name: "WebResponse", package: "WebResponse")
        ])
]
```
