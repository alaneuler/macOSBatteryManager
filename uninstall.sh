#!/bin/sh

#  Created by Alaneuler Erving on 2022/10/22.
#

sudo launchctl unload /Library/LaunchDaemons/me.alaneuler.mbm.PrivilegeHelper.plist
sudo rm -rf /Library/LaunchDaemons/me.alaneuler.mbm.PrivilegeHelper.plist
sudo rm -rf /Library/PrivilegedHelperTools/me.alaneuler.mbm.PrivilegeHelper
