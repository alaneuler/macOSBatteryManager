//
//  Created by Alaneuler Erving on 2022/10/19.
//

import Foundation

/// Class implementing the HelperTool protocol, it's a long running daemon.
class PrivilegeHelper: NSObject, NSXPCListenerDelegate, HelperProtocol {
    
    let listener: NSXPCListener
    
    override init() {
        self.listener = NSXPCListener(machServiceName: Constants.domain)
        super.init()
        self.listener.delegate = self
    }
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.remoteObjectInterface = NSXPCInterface(with: RemoteApplicationProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.resume()
        return true
    }
    
    func run() {
        self.listener.resume()
        RunLoop.current.run()
    }
    
    func getVersion(then completion: @escaping (String) -> Void) {
        completion("1")
    }
}
