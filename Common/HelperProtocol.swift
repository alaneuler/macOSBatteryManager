//
//  Created by Alaneuler Erving on 2022/10/19.
//

import Foundation

/// Interface for interacting with the PrivilegeHelper.
@objc(HelperProtocol)
public protocol HelperProtocol {
    @objc func getVersion(then completion: @escaping (String) -> Void)
}
