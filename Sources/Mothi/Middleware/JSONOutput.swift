import Foundation
/**
 A middleware which encode response body
 from type that supports `Encodable` to `JSON`
 
 - Parameters:
    - req: Request
    - res: Response
 
 To register call:
 
      app.use(JSONOutput)
 
 */
public func JSONOutput(req: Request, res: Response) {
    res.headers.add(name: "Content-Type", value: "application/json")
    res.responseSerializer = { bodyParts in

        if bodyParts.count == 1 {
            switch bodyParts[0] {
            case let text as String:
                return try [text].encode()
            case let encodable as Encodable:
                return try encodable.encode()
            case let error as Error:
                return try HTTPError.wrapp(error).encode()
            default:
                throw HTTPError.internal(message:  "Can't encode object: \(bodyParts[0])")
            }
        }
        
        var output:[AnyEncodable] = []
        
        for part in bodyParts {
            switch part {
                case let text as String:
                    output.append(AnyEncodable(text))
                case let error as Encodable & Error:
                    return try error.encode()
                case let error as Error:
                    return try HTTPError.wrapp(error).encode() 
                case let anyEncodable as AnyEncodable:
                    output.append(anyEncodable)
                case let encodable as Encodable:
                    output.append(AnyEncodable(encodable))

                default:
                    throw HTTPError.internal(message:  "Can't encode object: \(bodyParts[0])")
            }
        }
        return try output.encode()
    }
}

extension Encodable {
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
}

public struct AnyEncodable: Encodable {
    var _encodeFunc: (Encoder) throws -> Void
    
    public init(_ encodable: Encodable) {
        func _encode(to encoder: Encoder) throws {
            try encodable.encode(to: encoder)
        }
        self._encodeFunc = _encode
    }
    public func encode(to encoder: Encoder) throws {
        try _encodeFunc(encoder)
    }
}
