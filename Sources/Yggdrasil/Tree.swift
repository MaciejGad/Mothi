import Foundation

public final class Tree<Value, Key:Hashable> {
    let root = Node<Value, Key>.root
    let wildcard = Node<Value, Key>(value: "*")
    
    public private(set) var count = 0
    
    public init() {}
    
    public func store(path: String, key: Key? = nil, value: Value) {
        let box = Box(order: count, value: value)
        count += 1
        
        var path: String = path
        var node:Node<Value, Key>
        if path == "*" || path == "" {
            node = wildcard
        } else {
            var index = path.startIndex
            if path.hasPrefix("/") {
                index = path.index(after: index)
            }
            node = root
            while index != path.endIndex {
                node = node.createChild(path: &path, index: &index)
            }
        }
        
        if let key = key {
            node.store(box: box, key: key)
        } else {
            node.store(box: box)
        }
    }
    
    public func withdraw(path: String, key: Key) -> [Box<Value>] {
        guard path.count > 0 else {
            return []
        }
        let startIndex = path.index(after: path.startIndex)
        var output:[Box<Value>] = []
        output.append(contentsOf: wildcard.boxes(key: key))
        
        withdraw(path: path, index: startIndex, for: root, key: key, output: &output)
        
        output.sort { (lhs, rhs) -> Bool in
            lhs.order < rhs.order
        }
        return output
    }
    
    func withdraw(path: String, index: String.Index, for node: Node<Value, Key>, key: Key, output: inout [Box<Value>]) {
        guard index < path.endIndex else {
            output.append(contentsOf: node.boxes(key: key))
            return
        }
        guard !node.leaf else {
            return
        }
        
        let slashRange = path.range(of: "/", range: index..<path.endIndex)
        let valueEndIndex = slashRange?.lowerBound ?? path.endIndex
        let value = String(path[index..<valueEndIndex])
        let nextIndex = slashRange?.upperBound ?? path.endIndex
        

        
        if let wildcard = node.wildcard {
            if wildcard.leaf {
                output.append(contentsOf: wildcard.boxes(key: key))
            } else {
                withdraw(path: path, index: nextIndex, for: wildcard, key: key, output: &output)
            }
        }
        if let staticNode = node.statics?[value] {
            withdraw(path: path, index: nextIndex, for: staticNode, key: key, output: &output)
        }
        if let dynamics = node.dynamics?.values {
            for dynamicNode in dynamics {
                var out:[Box<Value>] = []
                withdraw(path: path, index: nextIndex,for: dynamicNode, key: key, output: &out)
                let key = String(dynamicNode.value.dropFirst())
                out.forEach {
                    $0.params[key] = value
                }
                output.append(contentsOf: out)
            }
        }
        return
    }
    
    
}

#if Encodable
extension Tree: Encodable {}
#endif
