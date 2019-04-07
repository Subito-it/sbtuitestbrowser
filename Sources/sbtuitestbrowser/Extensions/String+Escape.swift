//
//  String+Escape.swift
//  COpenSSL
//
//  Created by Tomas Camin on 17/07/2018.
//

import Foundation

extension String {
    func unescaped() -> String {
        let entities = ["\0", "\t", "\n", "\r", "\"", "\'", "\\"]
        guard var current = self.removingPercentEncoding else {
            return self
        }
        
        for entity in entities {
            let description = entity.debugDescription.dropFirst().dropLast()
            current = current.replacingOccurrences(of: description, with: entity)
        }
        
        return current
            .replacingOccurrences(of: "\\/", with: "/")
            .replacingOccurrences(of: "\n", with: "<br/>")
    }
    
    func encodeUsingHtmlEntities() -> String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "'", with: "&apos;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br />")
    }
}
