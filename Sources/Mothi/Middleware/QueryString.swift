import Foundation

fileprivate let key = "codes.gad.Querystring.param"

/**
A middleware which parses the URL query
parameters.
 
- Parameters:
    - req: Request
    - res: Response

You can then access them using:
 
    req.param("id")

 To register call:
 
     app.use(Querystring)
 
*/

public func Querystring(req: Request, res: Response) {
    // use Foundation to parse the `?a=x`
    // parameters
    guard let queryItems = URLComponents(string: req.header.uri)?.queryItems else {
        return
    }
    req.userInfo[key] = Dictionary(grouping: queryItems, by: { $0.name })
        .mapValues { $0.compactMap({ $0.value })
        .joined(separator: ",") }
}

public extension Request {
/**
Returns value of URL query parameter
     
- Parameters:
     - id: `String`, parameter id

- Returns: value for URL query parameter `(Optional<String>)`
     
Access query parameters, like:

     let userId = req.param("id")
     let token  = req.param("token")
*/
    
    func param(_ id: String) -> String? {
        let params = userInfo[key] as? [String: String]
        return params?[id]
    }
}
