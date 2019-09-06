import Foundation
import NIOHTTP1

extension Router {

    //simple use
    open func use(_ path: Path = "/*", method: HTTPMethod? = nil, middleware: @escaping NextMiddleware) {
        use(path, method:method, middleware: wrapp(middleware))
    }
    
    open func use(_ path: Path = "/*", method: HTTPMethod? = nil, middleware: @escaping SynchMiddleware) {
        use(path, method:method, middleware: wrapp(middleware))
    }
    
    //require body
    func use(_ path: Path = "/*", method: HTTPMethod? = nil, requireBody: Bool, middleware: @escaping Middleware) {
        use(path, method: method) { (req, res, loop) -> MiddlewareOutput in

            if requireBody {
                guard req.body != nil else {
                    throw HTTPError.badRequest
                }
            }
            return try middleware(req, res, loop)
        }
    }
    
    func use(_ path: Path = "/*", method: HTTPMethod? = nil, requireBody: Bool, middleware: @escaping SynchMiddleware) {
        use(path, method: method, requireBody: requireBody, middleware: wrapp(middleware))
    }
    
    func use(_ path: Path = "/*", method: HTTPMethod? = nil, requireBody: Bool, middleware: @escaping NextMiddleware) {
        use(path, method: method, requireBody: requireBody, middleware: wrapp(middleware))
    }
    
    //encodable output
    func use<Output>(_ path: Path = "/*", method: HTTPMethod? = nil, middleware: @escaping EncodableOutput<Output>) where Output: Encodable {
        use(path, method: method) { (req, res, loop) -> MiddlewareOutput in
            let output: Output = try middleware(req)
            res.send(output)
            return loop.makeSucceededFuture(.next)
        }
    }
    
    //input & output
    func use<Input, Output>(_ path: Path = "/*", method: HTTPMethod? = nil, middleware: @escaping DecodableInputEncodableOutput<Input, Output>) where Input: Decodable, Output: Encodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let input: Input = try req.object()
            let output: Output = try middleware(input)
            res.send(output)
            return loop.makeSucceededFuture(.next)
        }
    }
    
    //input
    func use<Input>(_ path: Path = "/*", method: HTTPMethod? = nil, middleware: @escaping DecodableInput<Input>) where Input: Decodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let input: Input = try req.object()
            return try middleware(input, res, loop)
        }
    }
    
    //sync input
    func use<Input>(_ path: Path = "/*", method: HTTPMethod? = nil, middleware: @escaping SynchDecodableInput<Input>) where Input: Decodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let input: Input = try req.object()
            let next = try middleware(input, res)
            return loop.makeSucceededFuture(next)
        }
    }
    //next input
    func use<Input>(_ path: Path = "/*", method: HTTPMethod? = nil, middleware: @escaping NextDecodableInput<Input>) where Input: Decodable {
        use(path, method: method, requireBody: true) { (req, res, loop) -> MiddlewareOutput in
            let input: Input = try req.object()
            try middleware(input, res)
            return loop.makeSucceededFuture(.next)
        }
    }
}
//
//func wrapp(_ middleware: @escaping Middleware) -> Middleware {
//    return middleware
//}

fileprivate func wrapp(_ middleware: @escaping SynchMiddleware) -> Middleware {
    return { (req, res, loop) throws -> MiddlewareOutput in
        let promise = loop.makePromise(of: MiddlewareNext.self)
        loop.execute {
            do {
                promise.succeed(try middleware(req, res))
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
}

fileprivate func wrapp(_ middleware: @escaping NextMiddleware) -> Middleware {
    return wrapp { (req, res) throws ->  MiddlewareNext in
        try middleware(req, res)
        return .next
    }
}

fileprivate func wrapp<Output>(_ middleware: @escaping EncodableOutput<Output>) -> Middleware where Output: Encodable {
    return wrapp { (req, res) throws ->  MiddlewareNext in
        res.send(try middleware(req))
        return .next
    }
}


func wrapp<Output>(_ middleware: @escaping EncodableSimpleOutput<Output>) -> Middleware where Output: Encodable {
    return wrapp { (_, res) throws -> MiddlewareNext in
        res.send(try middleware())
        return .next
    }
}

