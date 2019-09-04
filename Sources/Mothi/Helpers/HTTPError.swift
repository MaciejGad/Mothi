import Foundation
import NIO
import NIOHTTP1

public struct HTTPError: Error, Encodable, CustomStringConvertible {
    public let code: Int
    public let message: String
    
    public static let badRequest = HTTPError(code: 400, message: "Bad Request")
    public static let unauthorized = HTTPError(code: 401, message: "Unauthorized")
    public static let notFound = HTTPError(code: 404, message: "Not Found")
    public static let internalServerError = HTTPError(code: 500, message: "Internal Server Error")
    
    public static func `internal`(message: String) -> HTTPError {
        return HTTPError(code: 500, message: message)
    }
    
    public static func wrapp(_ error: Error) -> HTTPError {
        if let httpError = error as? HTTPError {
            return httpError
        }
        return HTTPError(code: 500, message: "\(error)")
    }
    
    public func httpStatus() -> HTTPResponseStatus {
        return HTTPResponseStatus(statusCode: code)
    }
    
    public var description: String {
        return "\(code) \(message)"
    }
}
