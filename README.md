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

```swift
let response = await WebResponse<SampleDto>.default.get(url: "https://jsonplaceholder.typicode.com/todos/1")
```

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

You can also pass raw `Data` as the request body:

```swift
let response = WebResponse<SampleDto>.default.post(
    url: "https://example.com/posts",
    body: Data()
)
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

### Empty response

Use `EmptyBody` when the endpoint returns an empty response body.

```swift
let response = WebResponse<EmptyBody>.withTimeout(3).get(url: "https://jsonplaceholder.typicode.com/todos/1")
```

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
