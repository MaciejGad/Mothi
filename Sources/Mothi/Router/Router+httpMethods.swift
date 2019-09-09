import Foundation
import NIOHTTP1



public extension Router {
    
    /// Register a middleware which triggers on a `GET`
    /// with a specific path prefix.
    
    func get(_ path: Path = "*", middleware: @escaping Middleware) {
        use(path, method: .GET, middleware: middleware)
    }
    
    func get(_ path: Path = "*", middleware: @escaping NextMiddleware) {
        use(path, method: .GET, middleware: middleware)
    }
    
    func get(_ path: Path = "*", middleware: @escaping SynchMiddleware) {
        use(path, method: .GET, middleware: middleware)
    }
    
    func get<Output>(_ path: Path  = "*", middleware: @escaping EncodableOutput<Output>) where Output: Encodable {
        use(path, method: .GET, middleware: middleware)
    }
    func get<Output>(_ path: Path, middleware: @escaping EncodableSimpleOutput<Output>) where Output: Encodable {
        use(path, method: .GET, middleware: wrapp(middleware))
    }
}

public extension Router {
    
    /// Register a middleware which triggers on a `POST`
    /// with a specific path prefix.
    
    func post(_ path: Path, middleware: @escaping Middleware) {
        use(path, method: .POST, requireBody: true, middleware: middleware)
    }
    
    func post(_ path: Path, middleware: @escaping SynchMiddleware) {
        use(path, method: .POST, middleware: middleware)
    }
    
    func post(_ path: Path, middleware: @escaping NextMiddleware) {
        use(path, method: .POST, middleware: middleware)
    }

    func post<Input, Output>(_ path: Path, middleware: @escaping DecodableInputEncodableOutput<Input, Output>) where Input: Decodable, Output: Encodable {
        use(path, method: .POST, middleware: middleware)
    }
    
    func post<Input>(_ path: Path, middleware: @escaping DecodableInput<Input>) where Input: Decodable {
        use(path, method: .POST, middleware: middleware)
    }
    
    func post<Input>(_ path: Path, middleware: @escaping SynchDecodableInput<Input>) where Input: Decodable {
        use(path, method: .POST, middleware: middleware)
    }
    
    func post<Input>(_ path: Path, middleware: @escaping NextDecodableInput<Input>) where Input: Decodable {
        use(path, method: .POST, middleware: middleware)
    }
    
}

public extension Router {
    
    /// Register a middleware which triggers on a `PUT`
    /// with a specific path prefix.
    
    func put(_ path: Path, middleware: @escaping Middleware) {
        use(path, method: .PUT, requireBody: true, middleware: middleware)
    }
    
    func put<Input, Output>(_ path: Path, middleware: @escaping DecodableInputEncodableOutput<Input, Output>) where Input: Decodable, Output: Encodable {
        use(path, method: .PUT, middleware: middleware)
    }
    
    func put<Input>(_ path: Path, middleware: @escaping DecodableInput<Input>) where Input: Decodable {
        use(path, method: .PUT, middleware: middleware)
    }
    
    func put<Input>(_ path: Path, middleware: @escaping SynchDecodableInput<Input>) where Input: Decodable {
        use(path, method: .PUT, middleware: middleware)
    }
    
    func put<Input>(_ path: Path, middleware: @escaping NextDecodableInput<Input>) where Input: Decodable {
        use(path, method: .PUT, middleware: middleware)
    }
}

public extension Router {
    
    /// Register a middleware which triggers on a `PATCH`
    /// with a specific path prefix.
    
    func patch(_ path: Path, middleware: @escaping Middleware) {
        use(path, method: .PATCH, requireBody: true, middleware: middleware)
    }
    
    func patch<Input, Output>(_ path: Path, middleware: @escaping DecodableInputEncodableOutput<Input, Output>) where Input: Decodable, Output: Encodable {
        use(path, method: .PATCH, middleware: middleware)
    }
    
    func patch<Input>(_ path: Path, middleware: @escaping DecodableInput<Input>) where Input: Decodable {
        use(path, method: .PATCH, middleware: middleware)
    }
    
    func patch<Input>(_ path: Path, middleware: @escaping SynchDecodableInput<Input>) where Input: Decodable {
        use(path, method: .PATCH, middleware: middleware)
    }
    
    func patch<Input>(_ path: Path, middleware: @escaping NextDecodableInput<Input>) where Input: Decodable {
        use(path, method: .PATCH, middleware: middleware)
    }
}

public extension Router {
    
    /// Register a middleware which triggers on a `PATCH`
    /// with a specific path prefix.
    
    func delete(_ path: Path, middleware: @escaping Middleware) {
        use(path, method: .DELETE, middleware: middleware)
    }
    
    func delete(_ path: Path, middleware: @escaping NextMiddleware) {
        use(path, method: .DELETE, middleware: middleware)
    }
    
    func delete(_ path: Path, middleware: @escaping SynchMiddleware) {
        use(path, method: .DELETE, middleware: middleware)
    }
}
