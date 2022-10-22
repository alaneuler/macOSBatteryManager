//
//  Created by Alaneuler Erving on 2022/10/19.
//

import Foundation
import ServiceManagement

class PrivilegeHelper {
    
    static let INSTANCE = PrivilegeHelper()
    
    var privilegeHelperInstalled: Bool { FileManager.default.fileExists(atPath: Constants.privilegeHelperPath) }
    
    func getRemote() -> HelperProtocol? {
        var proxyError: Error?
        
        let connection = getConnection()
        if connection == nil {
            NSLog("Unable to get a valid connection to privilegeHelper daemon! Please check.")
            return nil
        }
        
        let helper = getConnection()!.remoteObjectProxyWithErrorHandler({error in
            proxyError = error
        }) as? HelperProtocol
        
        if let unwrappedHelper = helper {
            return unwrappedHelper
        } else {
            NSLog("Unwrap PrivilegeHelper errror: " + (proxyError?.localizedDescription ?? ""))
            return nil
        }
    }
    
    private func getConnection() -> NSXPCConnection? {
        if !privilegeHelperInstalled {
            if !installHelper() {
                NSLog("Install PrivilegeHelper failed! Please check.")
                return nil
            }
        }
        
        return createConnection()
    }
    
    private func createConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(machServiceName: Constants.domain, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: RemoteApplicationProtocol.self)
        connection.exportedObject = self
        
        connection.invalidationHandler = { [privilegeHelperInstalled] in
            if privilegeHelperInstalled {
                NSLog("Unable to connect to PrivilegeHelper although it is installed")
            } else {
                NSLog("PrivilegeHelper is not installed")
            }
        }
        connection.resume()
        return connection
    }
    
    /// Install the Helper in the privileged helper tools folder and load the daemon.
    private func installHelper() -> Bool {
        NSLog("Start to install PrivilegeHelper...")
        
        // Create an AuthorizationItem to specify we want to bless a privileged Helper
        let authItem = kSMRightBlessPrivilegedHelper.withCString { authorizationString in
            AuthorizationItem(name: authorizationString, valueLength: 0, value: nil, flags: 0)
        }
        
        // It's required to pass a pointer to the call of the AuthorizationRights.init function
        let pointer = UnsafeMutablePointer<AuthorizationItem>.allocate(capacity: 1)
        pointer.initialize(to: authItem)
        defer {
            pointer.deinitialize(count: 1)
            pointer.deallocate()
        }
        
        var authRef: AuthorizationRef?
        var authRights = AuthorizationRights(count: 1, items: pointer)
        let flags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
        let authStatus = AuthorizationCreate(&authRights, nil, flags, &authRef)
        if authStatus != errAuthorizationSuccess {
            let errorMsg = SecCopyErrorMessageString(authStatus, nil) ?? "" as CFString
            NSLog(errorMsg as String)
            return false
        }
        
        // Try to install the helper and to load the daemon with authorization
        var error: Unmanaged<CFError>?
        if SMJobBless(kSMDomainSystemLaunchd, Constants.domain as CFString, authRef, &error) == false {
            print(error!.takeRetainedValue())
            return false
        }
        
        // Helper successfully installed
        // Release the authorization
        AuthorizationFree(authRef!, [])
        return true
    }
}
