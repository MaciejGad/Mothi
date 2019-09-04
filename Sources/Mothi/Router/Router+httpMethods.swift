import Foundation
import NIOHTTP1

public extension Router {
    func use(_ path: Path, method: NIOHTTP1.HTTPMethod? = nil, requireBody: Bool = false, middleware: @escaping Middleware) {
        use { (req, res, loop) -> MiddlewareOutput in
            if let method = method {
                guard req.method == method else {
                    return loop.makeSucceededFuture(.next)
                }
            }
            guard path.matching(path: req.path) else {
                return loop.makeSucceededFuture(.next)
            }
            req.pathParams = path.params
            if requireBody {
                guard req.body != nil else {
                    throw HTTPError.badRequest
                }
            }
            return try middleware(req, res, loop)
        }
    }
    
    func use(_ path: Path, method: NIOHTTP1.HTTPMethod? = nil, requireBody: Bool = false, middleware: @escaping SynchMiddleware) {
        use(path, method: method, middleware: wrapp(middleware))
    }
    
    func use(_ path: Path, method: NIOHTTP1.HTTPMethod? = nil, requireBody: Bool = false, middleware: @escaping NextMiddleware) {
        use(path, method: method, middleware: wrapp(middleware))
    }
    
    func use<Output>(_ path: Path, method: NIOHTTP1.HTTPMethod, middleware: @escaping EncodableOutput<Output>) where Output: Encodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let output: Output = try middleware(req)
            res.send(output)
            return loop.makeSucceededFuture(.next)
        }
    }
    
    func use<Input, Output>(_ path: Path, method: NIOHTTP1.HTTPMethod, middleware: @escaping DecodableInputEncodableOutput<Input, Output>) where Input: Decodable, Output: Encodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let input: Input = try req.object()
            let output: Output = try middleware(input)
            res.send(output)
            return loop.makeSucceededFuture(.next)
        }
    }
    
    func use<Input>(_ path: Path, method: NIOHTTP1.HTTPMethod, middleware: @escaping DecodableInput<Input>) where Input: Decodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let input: Input = try req.object()
            return try middleware(input, res, loop)
        }
    }
    
    func use<Input>(_ path: Path, method: NIOHTTP1.HTTPMethod, middleware: @escaping SynchDecodableInput<Input>) where Input: Decodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let input: Input = try req.object()
            let next = try middleware(input, res)
            return loop.makeSucceededFuture(next)
        }
    }
    
    func use<Input>(_ path: Path, method: NIOHTTP1.HTTPMethod, middleware: @escaping NextDecodableInput<Input>) where Input: Decodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let input: Input = try req.object()
            try middleware(input, res)
            return loop.makeSucceededFuture(.next)
        }
    }
}

public extension Router {
    
    /// Register a middleware which triggers on a `GET`
    /// with a specific path prefix.
    
    func get(_ path: Path, middleware: @escaping Middleware) {
        use(path, method: .GET, middleware: middleware)
    }
    
    func get(_ path: Path, middleware: @escaping NextMiddleware) {
        get(path, middleware: wrapp(middleware))
    }
    
    func get(_ path: Path, middleware: @escaping SynchMiddleware) {
        get(path, middleware: wrapp(middleware))
    }
    
    func get<Output>(_ path: Path, middleware: @escaping EncodableOutput<Output>) where Output: Encodable {
        get(path, middleware: wrapp(middleware))
    }
    func get<Output>(_ path: Path, middleware: @escaping EncodableSimpleOutput<Output>) where Output: Encodable {
        get(path, middleware: wrapp(middleware))
    }
}

public extension Router {
    
    /// Register a middleware which triggers on a `POST`
    /// with a specific path prefix.
    
    func post(_ path: Path, middleware: @escaping Middleware) {
        use(path, method: .POST, requireBody: true, middleware: middleware)
    }
    
    func post(_ path: Path, middleware: @escaping SynchMiddleware) {
        post(path, middleware: wrapp(middleware))
    }
    
    func post(_ path: Path, middleware: @escaping NextMiddleware) {
        post(path, middleware: wrapp(middleware))
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
        use(path, method: .DELETE, middleware: wrapp(middleware))
    }
    
    func delete(_ path: Path, middleware: @escaping SynchMiddleware) {
        use(path, method: .DELETE, middleware: wrapp(middleware))
    }
}
