//
//  Created by Alaneuler Erving on 2022/10/19.
//

import Foundation

/// Class implementing the HelperTool protocol, it's a long running daemon.
class PrivilegeHelper: NSObject, NSXPCListenerDelegate, HelperProtocol {
    static let CHARGING_KEY_STR: String = "CH0B"
    
    // TODO: Update functionality
    static let VERSION = "0.0.1"
    
    let listener: NSXPCListener
    
    /// Under SMC key CH0B, 00 means charging and 02 meaning not
    func chargingStat(then completion: @escaping (Bool, Bool) -> Void) {
        let smcKey = SMCKit.getKey(PrivilegeHelper.CHARGING_KEY_STR, type: DataTypes.UInt8)
        let stat = readSMCBytes(key: smcKey)
        if stat == nil {
            NSLog("Reading value from SMC failed!")
            completion(false, false)
        } else {
            let val = stat!.0
            let stat = val == 0
            if stat {
                NSLog("Current is charging")
            } else {
                NSLog("Current is not charging")
            }
            completion(true, stat)
        }
    }
    
    func disableCharging(then completion: @escaping (Bool) -> Void) {
        NSLog("Disabling charging...")
        
        let smcKey = SMCKit.getKey(PrivilegeHelper.CHARGING_KEY_STR, type: DataTypes.UInt8)
        let oldChargingStat = readSMCBytes(key: smcKey)
        if oldChargingStat != nil {
            let val = oldChargingStat!.0
            NSLog(String(format: "Old charging stat: %d", val))
            if val == 02 {
                NSLog("Already in non-charging stat! Skipped.")
                completion(true)
            } else {
                completion(writeSMCBytes(key: smcKey, bytes: smcBytes(value: 02)))
            }
        } else {
            NSLog(String(format: "Unable to find SMC key: %s", PrivilegeHelper.CHARGING_KEY_STR))
            completion(false)
        }
        
        NSLog("Disable charging done.")
    }
    
    func enableCharging(then completion: @escaping (Bool) -> Void) {
        NSLog("Enabling charging...")
        
        let smcKey = SMCKit.getKey(PrivilegeHelper.CHARGING_KEY_STR, type: DataTypes.UInt8)
        let oldChargingStat = readSMCBytes(key: smcKey)
        if oldChargingStat != nil {
            let val = oldChargingStat!.0
            NSLog(String(format: "Old charging stat: %d", val))
            if val == 0 {
                NSLog("Already in charging stat! Skipped.")
                completion(true)
            } else {
                completion(writeSMCBytes(key: smcKey, bytes: smcBytes(value: 00)))
            }
        } else {
            NSLog(String(format: "Unable to find SMC key: %s", PrivilegeHelper.CHARGING_KEY_STR))
            completion(false)
        }
        
        NSLog("Enable charging done.")
    }
    
    func getVersion(then completion: @escaping (String) -> Void) {
        completion(PrivilegeHelper.VERSION)
    }
    
    private func readSMCBytes(key: SMCKey) -> SMCBytes? {
        do {
            return try SMCKit.readData(key)
        } catch {
            NSLog(error.localizedDescription)
            return nil
        }
    }
    
    private func writeSMCBytes(key: SMCKey, bytes: SMCBytes) -> Bool {
        do {
            try SMCKit.writeData(key, data: bytes)
            return true
        } catch {
            NSLog(error.localizedDescription)
            return false
        }
    }
    
    private func smcBytes(value: UInt8) -> SMCBytes {
        return (value, UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
               UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
               UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
               UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
               UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
               UInt8(0), UInt8(0))
    }
    
    private func closeSMC() {
        NSLog("Closing connection to SMC...")
        SMCKit.close()
    }
    
    private func openSMC() {
        NSLog("Opening connection to SMC...")
        do {
            try SMCKit.open()
        } catch {
            NSLog(error.localizedDescription)
            exit(-1)
        }
    }
    
    override init() {
        self.listener = NSXPCListener(machServiceName: Constants.domain)
        super.init()
        self.listener.delegate = self
        
        openSMC()
        // TODO: close the connection to SMC when process is killed
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
}
