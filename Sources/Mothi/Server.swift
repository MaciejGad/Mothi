import Foundation
import NIO
import NIOHTTP1
import NIOFoundationCompat

open class Server: Router {

    var serverChannel: Channel? = nil

    open func listen(host:String = "localhost", port: Int, asynch: Bool = false) {
        let reuseAddrOpt = ChannelOptions.socket(
            SocketOptionLevel(SOL_SOCKET),
            SO_REUSEADDR)
        let bootstrap = ServerBootstrap(group: loopGroup)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(reuseAddrOpt, value: 1)
            
            .childChannelInitializer {[weak self] channel in
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
            self.serverChannel = serverChannel
            if asynch {
                 serverChannel.closeFuture.whenFailure({ error in
                    print("error: \(error)")
                })
            } else {
                try serverChannel.closeFuture.wait() // runs forever
            }
        }
        catch {
            fatalError("failed to start server: \(error)")
        }
    }
    
    deinit {
        do {
            try serverChannel?.close(mode: .all).wait()
        } catch {
            print("\(error)")
        }
    }

}
