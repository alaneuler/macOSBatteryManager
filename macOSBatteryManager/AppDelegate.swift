//
//  Created by Alaneuler Erving on 2022/10/19.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: NSStatusItem!
    
    private var helperProtocol: HelperProtocol!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        obtainHelper()
        addMenu()
    }
    
    private func obtainHelper() {
        let helperProtocolWrapper = PrivilegeHelper.INSTANCE.getRemote()
        if let helperProtocolTmp = helperProtocolWrapper {
            self.helperProtocol = helperProtocolTmp
            self.helperProtocol.getVersion { version in
                NSLog("PrivilegeHelper version: " + version)
            }
        } else {
            NSLog("Unable to get connection to PrivilegeHelper!")
            exit(-2)
        }
    }
    
    private func addMenu() {
        menuBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = menuBar.button {
            let image = NSImage(named: "menu_bar")
            image?.size = NSMakeSize(18.0, 18.0)
            button.image = image
        }
        
        let menu = NSMenu()
        
        let switchMenuItem = NSMenuItem()
        updateSwitchMenuItem(menuItem: switchMenuItem)
        menu.addItem(switchMenuItem)
        
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(terminate(_:)), keyEquivalent: "q")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(quitMenuItem)
        menuBar.menu = menu
    }
    
    private func updateSwitchMenuItem(menuItem: NSMenuItem) {
        getSwitchText { title, enabled in
            menuItem.title = title
            if enabled {
                menuItem.action = #selector(self.toggleSwith(_:))
            } else {
                menuItem.action = nil
            }
        }
    }
    
    private func getSwitchText(withReply completion: @escaping (String, Bool) -> Void) {
        self.helperProtocol.chargingStat { success, stat in
            if !success {
                completion("Unknown charging stat", false)
                return
            }
            
            if stat {
                NSLog("Current stat is charging.")
                completion("Disable Charging", true)
            } else {
                NSLog("Current stat is non-charging.")
                completion("Enable Charging", true)
            }
        }
    }
    
    @objc
    private func toggleSwith(_ sender: NSMenuItem) {
        self.helperProtocol.chargingStat { success, stat in
            if !success {
                NSLog("Get charging stat failed!")
                return
            }
            
            if stat {
                self.helperProtocol.disableCharging { result in
                    if result {
                        self.updateSwitchMenuItem(menuItem: sender)
                    } else {
                        NSLog("Disable charging failed!")
                    }
                }
            } else {
                self.helperProtocol.enableCharging { result in
                    if result {
                        self.updateSwitchMenuItem(menuItem: sender)
                    } else {
                        NSLog("Enable charging failed!")
                    }
                }
            }
        }
    }
    
    @objc
    func terminate(_ sender: NSMenuItem) {
        NSApp.terminate(sender)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }
}
