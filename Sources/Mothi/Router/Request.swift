import Foundation
import NIOHTTP1

public protocol BodyDecoder {
    func decode<T:Decodable>(data: Data) throws -> T
}

open class Request {
    
    public let header: HTTPRequestHead
    public var userInfo: [String: Any] = [:]
    public var body: Data?
    
    public var bodyDecoder: BodyDecoder?
    
    public var method: HTTPMethod {
            return header.method
    }
    
    public var url: URL? {
        return URL(string: header.uri)
    }
    
    public let path: String
    public var pathParams: [String: String] = [:]
    
    public var userAgent: String? {
        return header.headers["User-Agent"].first
    }
    public var authorization: String? {
        return header.headers["Authorization"].first
    }
    
    
    init(header: HTTPRequestHead) {
        self.header = header
        self.path = header.uri.components(separatedBy: "?")[0]
    }
}
