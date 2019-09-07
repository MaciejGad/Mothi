import Foundation
import NIO
import Yggdrasil
import NIOHTTP1

public typealias Path = String

open class Router {
    
    public init() {}
    
    let loopGroup =
        MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    
    defer {
        do {
            try loopGroup.syncShutdownGracefully()
        } catch {
            print("\(error)")
        }
    }
    
    private let tree = Tree<Middleware, HTTPMethod>()
    
    func use(_ path: Path = "/*", method: HTTPMethod? = nil, middleware: @escaping Middleware) {
        tree.store(path: path, key: method, value: middleware)
    }
 
    func middlewares(for path: Path, method: HTTPMethod) -> [Box<Middleware>] {
        return tree.withdraw(path: path, key: method)
    }
}

extension HTTPMethod: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value())
    }
    
    func value() -> String {
        return "\(self)"
    }
}

