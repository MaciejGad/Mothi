import Foundation
import Mothi

let app = Server()

//smaple route that returs
//array of strings

app.get("/") { (req) in
    return """
Móði ok Magni
skulu Mjöllni hafa
Vingnis at vígþroti.
""".components(separatedBy: "\n")
}

//register JSON handling middlewares
app.use(JSONOutput)
app.use(JSONInput)

//you can register
//`Querystring` middleware
app.use(Querystring)

//and then use it:
app.get("/param") { (req) -> [String : String] in
    if let test = req.param("test") {
        return ["param": test]
    }
    return ["param": "No test param"]
}

//you can also use path paramters
app.get("/id/:id") { (req, res) in
    res.send(["id": req.pathParams["id"]])
}

//and wildcards
app.get("/any/*") { (req, res) in
    res.send(["path": req.path])
}


//you can use middleware to log requests
app.use { (req, res) in
    print("\(req.method):", req.header.uri)
}

//or display request body
app.use { (req, res) -> Void in
    guard let body = req.body else {
        return
    }
    let text = String(bytes: body, encoding: .utf8) ?? "Encoding problem"
    print("Body: \(text)")
}

//normally output from
//two routes will merge
app.get("/merge") {
    return "First line"
}
app.get("/merge") {
    return "Second line"
}

//but you can stop by
//returning `.end` from route
app.get("/end") { (_, res) -> MiddlewareNext in
    res.send("Test")
    return .end
}

app.get("/end") {
    return "Another"
}

//if you throw
app.get("/throw") { (_, res) in
    res.send("Test 1")
}
//only error will appear in respone
app.get("/throw") { (_, res) -> Void in
    throw HTTPError.internal(message: "Just testing")
}

//without rest of response
app.get("/throw") { (_, res) in
    res.send("Test 2")
}

//you can return any object
//that supports `Encodable`
struct Out: Encodable {
    let anotherOut: String
}
app.get("/out") {
    return Out(anotherOut: "Test")
}

//or you can use any `Decodable`
//as input to methods that
//require request body (post, put, patch)
struct PostInput: Decodable {
    let value: String
}
app.post("/post") { (input: PostInput) in
    return ["out": input.value]
}


//you can add middleware to all calls (like `Querystring`)
//or only to some PATH and/or METHOD
app.use("/post", method: .POST, middleware: basicAuth(username: "user", password: "test"))

//you can get currently logged
//user name in `req.username`
app.post("/post") { (req, res) in
    res.send(["loggedAs": req.username])
}

//if your task in long runnig and async
//you can return `EventLoopFuture<MiddlewareNext>` aka `MiddlewareOutput`
//from your route

app.get("/promise") { (req, res, loop) -> MiddlewareOutput in
    res.send("Start: \(Date())")
    let promise = loop.makeMiddlewarePromise()
    DispatchQueue.global(qos: .default).asyncAfter(deadline: .now()+1, execute: {
        loop.execute {
            res.send("End: \(Date())")
            promise.succeed(.next)
        }
    })
    return promise.futureResult
}

//and the next route will be called when previous
//EventLoopFuture will success
app.get("/promise") { _ in
    return "Next: \(Date())"
}

//this approch you can use to any method
app.post("/promise") { (input: PostInput, res , loop) in
    res.send(["Start": "\(Date())"])
    let promise = loop.makeMiddlewarePromise()
    DispatchQueue.global(qos: .default).asyncAfter(deadline: .now()+1, execute: {
        loop.execute {
            res.send(["End": "\(Date())"])
            promise.succeed(.next)
        }
    })
    return promise.futureResult
}

app.post("/promise") { (input: PostInput) in
    return ["out" :input.value]
}

//you can also use put
app.put("/put") { (input: PostInput, res) in
    res.send(input.value)
}

//patch
app.patch("/patch") { (input: PostInput, res) -> MiddlewareNext in
    res.send(input.value)
    return .end
}

app.patch("/patch") { (input: PostInput, res) in
    res.send(input.value)
}

//or delete
app.delete("/delete") { (req, res: Response) in
    res.status = .noContent
}

//but if you need some other HTTP method
//you can use
app.use("/", method: .SEARCH) { (req, res) -> Void in
    res.status = .found
    res.send(["searching": req.param("q")])
}

//read the command line, set host & port
//or you can just use:

//app.listen(port: 1337)

let host: String
if CommandLine.arguments.count > 1 {
    host = CommandLine.arguments[1]
} else {
    host = "localhost"
}

let port: Int
if CommandLine.arguments.count > 2 {
    port = Int(CommandLine.arguments[2]) ?? 1337
} else {
    port = 1337
}

app.listen(host: host, port: port)
