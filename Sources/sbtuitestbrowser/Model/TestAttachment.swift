//
//  TestAttachment.swift
//  sbtuitestbrowser
//
//  Created by Tomas Camin on 26/06/2018.
//

import Foundation

class TestAttachment {
    enum `Type` {
        case image
        case crashlog
        case text
        case other
    }
    
    let title: String
    let path: String
    let isAutomaticScreenshot: Bool
    let type: Type
    
    init(title: String?, path: String) {
        self.path = path
        
        switch path.filePathExtension {
        case "png", "jpg":
            self.type = .image
        case "crash":
            self.type = .crashlog
        case "txt":
            self.type = .text
        default:
            self.type = .other
        }
        
        switch self.type {
        case .image:
            self.title = title ?? "Screenshot"
        case .crashlog:
            self.title = title ?? "Diagnostic report"
        case .text:
            self.title = title ?? "Text attachment"
        default:
            self.title = title ?? "Attachment"
        }
        
        self.isAutomaticScreenshot = path.hasPrefix("Screenshot_") && path.filePathExtension == "jpg"
    }
    
    func encodedPath() -> String {
        return self.path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? self.path
    }
}
