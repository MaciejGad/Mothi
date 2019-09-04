import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat

open class Server: Router {

    open func listen(host:String = "localhost", port: Int) {
        let reuseAddrOpt = ChannelOptions.socket(
            SocketOptionLevel(SOL_SOCKET),
            SO_REUSEADDR)
        let bootstrap = ServerBootstrap(group: loopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler(router: self))
                }
            }
            
            .childChannelOption(ChannelOptions.socket(
                IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(reuseAddrOpt, value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead,
                                value: 1)
        
        do {
            let serverChannel =
                try bootstrap.bind(host: host, port: port)
                    .wait()
            print("Server running on:", serverChannel.localAddress!)
            
            try serverChannel.closeFuture.wait() // runs forever
        }
        catch {
            fatalError("failed to start server: \(error)")
        }
    }
    
    final class HTTPHandler: ChannelInboundHandler {
        typealias InboundIn = HTTPServerRequestPart
        
        let router: Router
        var buffer = ByteBufferAllocator().buffer(capacity: 4096)
        var requestHead: HTTPRequestHead? = nil
        
        init(router: Router) {
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
                        return (request, response)
                    }.flatMap { (request, response) in
                        self.router.handle(request: request, response: response, loop: loop)
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
        }
    }

}
