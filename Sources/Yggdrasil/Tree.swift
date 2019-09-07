import Foundation

public final class Tree<Value, Key:Hashable> {
    let root = Node<Value, Key>.root
    public private(set) var count = 0
    
    public init() {}
    
    public func store(path: String, key: Key? = nil, value: Value) {
        let box = Box(order: count, value: value)
        count += 1
        let pathComponents = path.components(separatedBy: "/").dropFirst()
        var node: Node = root
        for component in pathComponents {
            node = node.createChild(for: component)
        }
        if let key = key {
            node.store(box: box, key: key)
        } else {
            node.store(box: box)
        }
    }
    
    public func withdraw(path: String, key: Key) -> [Box<Value>] {
        let pathComponenets = path.components(separatedBy: "/").dropFirst()
        return withdraw(pathComponents: pathComponenets, for: root, key: key).sorted(by: { (lhs, rhs) -> Bool in
            lhs.order < rhs.order
        })
    }
    
    func withdraw(pathComponents: ArraySlice<String>, for node: Node<Value, Key>, key: Key) -> [Box<Value>] {
        guard pathComponents.count > 0 else {
            return node.boxes(key: key)
        }
        guard !node.leaf else {
            if node.type == .wildcard {
                return node.boxes(key: key)
            }
            return []
        }
        var pathComponents = pathComponents
        let value = pathComponents.removeFirst()
        var out:[Box<Value>] = []
        if let wildcard = node.wildcard {
            out.append(contentsOf: withdraw(pathComponents: pathComponents, for: wildcard, key: key))
        }
        if let staticNode = node.statics?[value] {
            out.append(contentsOf: withdraw(pathComponents: pathComponents, for: staticNode, key: key))
        }
        if let dynamics = node.dynamics?.values {
            for dynamicNode in dynamics {
                let dyniamicMiddlewares = withdraw(pathComponents: pathComponents, for: dynamicNode, key: key)
                let key = String(dynamicNode.value.dropFirst())
                dyniamicMiddlewares.forEach {
                    $0.params[key] = value
                }
                out.append(contentsOf: dyniamicMiddlewares)
            }
        }
        return out
    }
    
    
}

#if Encodable
extension Tree: Encodable {}
#endif
