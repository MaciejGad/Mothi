import Foundation
import NIO

open class Router {
    
    public init() {}
    
    let loopGroup =
        MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    /// The sequence of Middleware functions.
    private var middlewares: [Middleware] = []
    
    /// Add another middleware (or many) to the list
    open func use(_ middleware: Middleware...) {
        self.middlewares.append(contentsOf: middleware)
    }
    
    open func use(_ middleware: @escaping NextMiddleware) {
        use(wrapp(middleware))
    }
    
    open func use(_ middleware: @escaping SynchMiddleware) {
        use(wrapp(middleware))
    }
    
    open func use<Output>(_ middleware: @escaping EncodableOutput<Output>) where Output: Encodable {
        use(wrapp(middleware))
    }
    
    func handle(request: Request, response: Response, loop: EventLoop) -> EventLoopFuture<Response> {
        
        
        var future: MiddlewareOutput = loop.makeSucceededFuture(.next)
        
        for middleware in middlewares {
            future = future.flatMap { next in
                guard next != .end else {
                    return loop.makeSucceededFuture(.end)
                }
                do {
                    return try middleware(request, response, loop)
                } catch {
                    return loop.makeFailedFuture(error)
                }
                
            }
            
        }
        return future.map { _ in
            
            if response.handled == false {
                response.send(HTTPError.notFound)
            }
            return response
        }
    }
}

