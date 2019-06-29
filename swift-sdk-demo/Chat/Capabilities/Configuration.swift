//
//  Configuration.swift
//  Chat
//
//  Created by zapcannon87 on 2019/6/17.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation

class Configuration {
    
    static let `default` = Configuration()
    
    private init() {}
    
    static let userDefaultsNameSpace: String = "com.leancloud.swift.demo.chat"
    
    enum UserOption {
        case isTagEnabled
        case isLocalStorageEnabled
        case isAutoOpenEnabled
        case clientID
        
        var key: String {
            return "\(Configuration.userDefaultsNameSpace).\(self)"
        }
        
        var boolValue: Bool {
            return UserDefaults.standard.bool(forKey: self.key)
        }
        
        var stringValue: String? {
            return UserDefaults.standard.string(forKey: self.key)
        }
        
        func set(value: Any) {
            UserDefaults.standard.set(value, forKey: self.key)
            UserDefaults.standard.synchronize()
        }
    }
    
}
