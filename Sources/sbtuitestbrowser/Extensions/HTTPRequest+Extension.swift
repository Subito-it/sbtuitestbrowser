//
//  HTTPRequest+Extension.swift
//  sbtuitestbrowser
//
//  Created by Tomas Camin on 17/03/2017.
//
//

import Foundation
import PerfectHTTP

extension HTTPRequest {
    
    /// Returns the first GET or POST parameter with the given name.
    /// Returns the supplied default value if the parameter was not found.
    public func paramBoolValue(name: String, defaultValue: Bool = false) -> Bool {
        for p in self.queryParams
            where p.0 == name {
                return p.1 == "1"
        }
        for p in self.postParams
            where p.0 == name {
                return p.1 == "1"
        }
        return defaultValue
    }

    var queryParamsDict: [String : String] {
        var ret = [String : String]()
        let params = queryParams
        
        params.forEach() { ret[$0.0] = $0.1 }
        
        return ret
    }
}
