//
//  Created by Alaneuler Erving on 2022/10/19.
//

import Foundation
import ServiceManagement

class PrivilegeHelper {
    
    static let INSTANCE = PrivilegeHelper()
    
    var privilegeHelperInstalled: Bool { FileManager.default.fileExists(atPath: Constants.PRIVILEGE_HELPER_PATH) }
    
    func getRemote() -> HelperProtocol? {
        var proxyError: Error?
        
        let connection = getConnection()
        if connection == nil {
            Logger.error("Unable to get a valid connection to privilegeHelper daemon! Please check.")
            return nil
        }
        
        let helper = getConnection()!.remoteObjectProxyWithErrorHandler({error in
            proxyError = error
        }) as? HelperProtocol
        
        if let helper {
            return helper
        } else {
            Logger.error("Unwrap PrivilegeHelper errror: \(proxyError?.localizedDescription ?? "Unknown error")")
            return nil
        }
    }
    
    private func getConnection() -> NSXPCConnection? {
        if !privilegeHelperInstalled {
            if !installHelper() {
                Logger.error("Install PrivilegeHelper failed! Please check.")
                return nil
            }
        }
        
        return createConnection()
    }
    
    private func createConnection() -> NSXPCConnection {
        let connection = NSXPCConnection(machServiceName: Constants.DOMAIN, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: RemoteApplicationProtocol.self)
        connection.exportedObject = self
        
        connection.invalidationHandler = { [privilegeHelperInstalled] in
            if privilegeHelperInstalled {
                Logger.error("Unable to connect to PrivilegeHelper although it is installed")
            } else {
                Logger.error("PrivilegeHelper is not installed")
            }
        }
        connection.resume()
        return connection
    }
    
    /// Install the Helper in the privileged helper tools folder and load the daemon.
    private func installHelper() -> Bool {
        Logger.info("Start to install PrivilegeHelper...")
        
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
            Logger.error("Auth for installing helper failed: \(SecCopyErrorMessageString(authStatus, nil) ?? "Unknown error" as CFString)")
            return false
        }
        
        // Try to install the helper and to load the daemon with authorization
        var error: Unmanaged<CFError>?
        if SMJobBless(kSMDomainSystemLaunchd, Constants.DOMAIN as CFString, authRef, &error) == false {
            Logger.error("Install helper failed: \(error!.takeRetainedValue().localizedDescription)")
            return false
        }
        
        // Helper successfully installed
        // Release the authorization
        AuthorizationFree(authRef!, [])
        return true
    }
}
