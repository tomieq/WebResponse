# WebResponse

WebResponse is a simple Swift library acting as a http client.

```swift
struct SampleDto: Codable {
    let id: Int
    let title: String
    let body: String
}
let response = WebResponse<SampleDto>.default.get(url: "https://jsonplaceholder.typicode.com/todos/1")
```

Closure version:
```swift
WebResponse<EmptyBody>.default.get(url: "https://jsonplaceholder.typicode.com/todos/1") { result in

}
```

### Custom timeout
```swift
let response = WebResponse<SampleDto>.withTimeout(3).get(url: "https://jsonplaceholder.typicode.com/todos/1")
```
### Empty response
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
in the target:
```swift
targets: [
    .executableTarget(
        name: "AppName",
        dependencies: [
            .product(name: "WebResponse", package: "WebResponse")
        ])
]
```
