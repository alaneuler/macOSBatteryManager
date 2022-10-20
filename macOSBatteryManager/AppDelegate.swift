//
//  AppDelegate.swift
//  macOSBatteryManager
//
//  Created by Alaneuler Erving on 2022/10/19.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let helperProtocolWrapper = PrivilegeHelper.INSTANCE.getRemote()
        if let helperProtocol = helperProtocolWrapper {
            helperProtocol.getVersion { version in
                NSLog(version)
            }
        }
        
        
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
