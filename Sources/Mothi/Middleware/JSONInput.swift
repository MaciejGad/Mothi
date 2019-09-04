import Foundation

/**
 A middleware which decode request body
 from `JSON` to type that supports `Decodable`
 
 - Parameters:
     - req: Request
     - res: Response

To register call:
 
     app.use(JSONInput)
 
*/

public func JSONInput(req: Request, res: Response) {
    req.bodyDecoder = JSONBodyDecoder()
}

fileprivate let key = "codes.gad.JSONInput.object"

class JSONBodyDecoder: BodyDecoder {
    let jsonDecoder = JSONDecoder()
    func decode<T:Decodable>(data: Data) throws -> T {
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch DecodingError.dataCorrupted(let context) {
            throw HTTPError(code: 400, message: context.debugDescription)
        } catch DecodingError.keyNotFound(_, let context) {
            throw HTTPError(code: 400, message: "\(context.debugDescription)" )
        } catch DecodingError.typeMismatch(_, let context) {
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ",")
            throw HTTPError(code: 400, message: "\(context.debugDescription) Path: \(path)" )
        } catch DecodingError.valueNotFound(_, let context) {
            let path = context.codingPath.map { $0.stringValue }.joined(separator: ",")
            throw HTTPError(code: 400, message: "\(context.debugDescription) Path: \(path)" )
        } catch {
            throw HTTPError(code: 400, message: "\(error)" )
        }
    }
}



extension Request {
    public func object<T:Decodable> () throws -> T {
        guard let body = self.body else {
            throw HTTPError.badRequest
        }
        guard let bodyDecoder = bodyDecoder else {
            throw HTTPError.internal(message: "Request body decoder not set")
        }
        if let obj: T = userInfo[key] as? T {
            return obj
        }
        let obj: T = try bodyDecoder.decode(data: body)
        userInfo[key] = obj
        return obj
    }
}
