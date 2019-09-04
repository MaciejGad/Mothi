import Foundation
import NIO


public enum MiddlewareNext {
    case next
    case end
    
}

public typealias MiddlewareOutput = EventLoopFuture<MiddlewareNext>


public typealias Middleware = (Request, Response, EventLoop) throws -> MiddlewareOutput
public typealias SynchMiddleware = (Request, Response) throws -> MiddlewareNext
public typealias NextMiddleware = (Request, Response) throws -> Void

public typealias EncodableOutput<Output> = (Request) throws -> Output where Output: Encodable
public typealias EncodableSimpleOutput<Output> = () throws ->  Output where Output: Encodable

public typealias DecodableInputEncodableOutput<Input, Output> = (Input) throws -> Output where Input: Decodable, Output: Encodable
public typealias DecodableInput<Input> = (Input, Response, EventLoop) throws -> MiddlewareOutput where Input: Decodable

public typealias SynchDecodableInput<Input> = (Input, Response) throws -> MiddlewareNext where Input: Decodable
public typealias NextDecodableInput<Input> = (Input, Response) throws -> Void where Input: Decodable

func wrapp(_ middleware: @escaping Middleware) -> Middleware {
    return middleware
}

func wrapp(_ middleware: @escaping SynchMiddleware) -> Middleware {
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

func wrapp(_ middleware: @escaping NextMiddleware) -> Middleware {
    return wrapp { (req, res) throws ->  MiddlewareNext in
        try middleware(req, res)
        return .next
    }
}

func wrapp<Output>(_ middleware: @escaping EncodableOutput<Output>) -> Middleware where Output: Encodable {
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


extension EventLoop {
    public func makeMiddlewarePromise(file: StaticString = #file, line: UInt = #line) -> EventLoopPromise<MiddlewareNext> {
        return makePromise(of: MiddlewareNext.self, file: file, line: line)
    }
}
