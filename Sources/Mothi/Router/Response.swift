import Foundation

import NIO
import NIOHTTP1

open class Response {
    
    public var status = HTTPResponseStatus.ok {
        didSet {
            handled = true
        }
    }
    public var headers = HTTPHeaders()
    public var handled: Bool = false
    public var body: Data = .init()
    
    public var bodyPart: [Any] = []
    
    public var responseSerializer:([Any]) throws -> Data = { bodyParts in
        let output = bodyParts.reduce("", { (text: String, part: Any) -> String in
            return text + "\(part)" + "\n"
        })
        return Data(output.utf8)
    }
    
    public func send(_ s: String) {
        send(any: s)
    }
    
    public func send<Object: Encodable>(_ obj: Object) {
        send(any: obj)
    }
    
    func send(_ error: Error) {
        if let httpError = error as? HTTPError {
            status = httpError.httpStatus()
        } else {
            status = .internalServerError
        }
        handled = true
        bodyPart = [error]
    }
    
    private func send(any: Any) {
        handled = true
        bodyPart.append(any)
    }
    
    func save(channel: Channel) {
        do {
            body = try responseSerializer(bodyPart)
        } catch {
            status = .internalServerError
            let message = "Can't serialize output: \(error)"
            
            let httpError:HTTPError
            if let hError = error as? HTTPError {
                httpError = hError
            } else {
                httpError = HTTPError(code: 500, message: message)
            }
            if let data = try? responseSerializer([httpError]) {
                body = data
            } else {
                body = Data(message.utf8)
            }
        }

        let head = HTTPResponseHead(version: .init(major:1, minor:1), status: status, headers: headers)
        let headPart = HTTPServerResponsePart.head(head)
        channel.writeAndFlush(headPart).flatMap { _ -> EventLoopFuture<Void> in
            var buffer = channel.allocator.buffer(capacity: self.body.count)
            buffer.writeBytes(self.body)
            let part = HTTPServerResponsePart.body(.byteBuffer(buffer))
            return channel.writeAndFlush(part)
        }.flatMap{
            return channel.writeAndFlush(HTTPServerResponsePart.end(nil))
        }.flatMap {
            return channel.close()
        }.whenFailure { error in
            #if DEBUG
            print("\(error)")
            #endif
            _ = channel.close()
        }
    }
}
