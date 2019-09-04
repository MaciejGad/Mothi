# Mothi
🕸️🔨 Micro web server written in Swift using Swift-NIO 

##Usage

```swift 
import Mothi

let app = Server()

app.get("/") { (req) in
    return """
Móði ok Magni
skulu Mjöllni hafa
Vingnis at vígþroti.
"""
}

app.listen(port: 1337)
```