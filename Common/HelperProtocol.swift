//
//  Created by Alaneuler Erving on 2022/10/19.
//

import Foundation

/// Interface for interacting with the PrivilegeHelper.
@objc(HelperProtocol)
public protocol HelperProtocol {
    @objc func getVersion(then completion: @escaping (String) -> Void)
    
    /// First boolean value indicats whether the request is successful.
    /// Second boolean value indicates whether the system is charging or not.
    @objc func chargingStat(then completion: @escaping (Bool, Bool) -> Void)
    
    @objc func disableCharging(then completion: @escaping (Bool) -> Void)
    
    @objc func enableCharging(then completion: @escaping (Bool) -> Void)
}
