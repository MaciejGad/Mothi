import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat
import Yggdrasil

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    weak var router: Router?
    var buffer = ByteBufferAllocator().buffer(capacity: 4096)
    var requestHead: HTTPRequestHead? = nil
    
    var middlewares: [Box<Middleware>]? = nil
    
    init(router: Router?) {
        self.router = router
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = unwrapInboundIn(data)
        switch reqPart {
        case .head(let head):
            requestHead = head
        case .body(var buffer):
            self.buffer.writeBuffer(&buffer)
        case .end:
            end(context: context)
        }
    }
    
    func end(context: ChannelHandlerContext) {
        
        let response = Response()
        let loop = context.eventLoop
        
        loop
            .makeSucceededFuture(response)
            .flatMapThrowing { response -> (Request, Response) in
                guard let header = self.requestHead else {
                    throw HTTPError.badRequest
                }
                let request  = Request(header: header)
                if self.buffer.readableBytes > 0 {
                    request.body = self.buffer.getData(at: 0, length: self.buffer.readableBytes)
                }
                self.setupMiddlewares(request: request)
                
                return (request, response)
            }.flatMap { (request, response) -> EventLoopFuture<Response> in
                
                
                guard self.middlewares?.count ?? 0 > 0 else {
                    response.send(HTTPError.notFound)
                    return loop.makeSucceededFuture(response)
                }
                
                let promise = loop.makePromise(of: Response.self)
                
                self.callMiddleware(request: request, response: response, loop: loop, endingPromise: promise)
                
                return promise.futureResult
            }.map { response -> Response in
                if !response.handled {
                    response.send(HTTPError.notFound)
                }
                return response
            }.whenComplete { result in
                switch result {
                case .success(let response):
                    response.save(channel: context.channel)
                case .failure(let error):
                    print("Error: \(error)")
                    response.send(HTTPError.wrapp(error))
                    response.save(channel: context.channel)
                }
        }
    }
    
    func callMiddleware(request: Request, response: Response, loop: EventLoop, endingPromise: EventLoopPromise<Response>) {
        guard let middleware = self.middlewares?.popLast() else {
            endingPromise.succeed(response)
            return
        }
        do {
            request.pathParams = middleware.params
            try middleware.value(request, response, loop).whenComplete { result in
                switch result {
                case .success(let next) where next == .next:
                    self.callMiddleware(request: request, response: response, loop: loop, endingPromise: endingPromise)
                case .success:
                    endingPromise.succeed(response)
                case .failure(let error):
                    endingPromise.fail(error)
                }
            }
        } catch {
            endingPromise.fail(error)
        }
    }
    
    func setupMiddlewares(request: Request) {
        middlewares = router?.middlewares(for: request.path, method: request.method).reversed()
    }
    
}
