import Foundation

fileprivate let key = "codes.gad.basicAuth.username"

/**
A middleware which handle basic access authentication.
 
 - Parameters:
    - username: user name
    - password: password
 
To register call:

     app.use(basicAuth(username: "mothi", password: "Mjollnir"))
 
 */

public func basicAuth(username: String, password: String) -> NextMiddleware {
    return { (req: Request, res: Response) in
        guard let authorization = req.authorization else {
            throw HTTPError.unauthorized
        }
        let components = authorization.components(separatedBy: " ")
        guard components.count == 2 else {
            throw HTTPError.unauthorized
        }
        guard components[0] == "Basic" else {
            throw HTTPError.unauthorized
        }
        guard let baseData = Data(base64Encoded: components[1]) else {
            throw HTTPError.unauthorized
        }
        guard let userAndPasword = String(bytes: baseData, encoding: .utf8) else {
            throw HTTPError.unauthorized
        }
        let credentails = userAndPasword.components(separatedBy: ":")
        guard credentails.count == 2 else {
            throw HTTPError.unauthorized
        }
        guard credentails[0] == username && credentails[1] == password else {
            throw HTTPError.unauthorized
        }
        req.userInfo[key] = username
    }
}

extension Request {
    public var username: String? {
        return userInfo[key] as? String
    }
}
