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
        case plist
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
        case "plist":
            self.type = .plist
        default:
            self.type = .other
        }
        
        switch self.type {
        case .image:
            self.title = title ?? "Screenshot"
        case .crashlog:
            self.title = title ?? "Diagnostic report"
        case .text:
            self.title = title ?? "String attachment"
        case .plist:
            self.title = title ?? "Plist attachment"
        default:
            self.title = title ?? "Attachment"
        }
        
        self.isAutomaticScreenshot = title?.hasPrefix("kXCTAttachment") == true && title?.hasSuffix("ScreenImageData") == true
    }
    
    func base64() -> String {
        return self.path.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}
