//
// TestAction.swift
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


import Foundation

class TestAction: Hashable, Equatable {
    let name: String
    let uuid: String
    let failed: Bool
    let attachments: [TestAttachment]?
    let startTimeinterval: TimeInterval
    let stopTimeinterval: TimeInterval
    let duration: TimeInterval
    unowned let parentTest: Test
    weak var parentAction: TestAction?
    
    private(set) var subActions = [TestAction]()
    
    init(dict: [String : Any], parentAction: TestAction?, parentTest: Test, attachmentBasePath: String) {
        let actionName = dict["Title"] as! String
        self.name = actionName
        self.uuid = dict["UUID"] as! String
        
        let startTime = dict["StartTimeInterval"] as? TimeInterval ?? 0.0
        let stopTime = dict["FinishTimeInterval"] as? TimeInterval ?? 0.0
        
        self.startTimeinterval = startTime
        self.stopTimeinterval = stopTime
        
        self.duration = max(stopTime - startTime, 0.0)
        
        self.parentAction = parentAction
        self.parentTest = parentTest
        
        if let attachments = dict["Attachments"] as? [[String: Any]] {
            self.attachments = attachments.compactMap {
                guard let filename = $0["Filename"] as? String else { return nil }
                return TestAttachment(title: $0["Name"] as? String, path: "\(attachmentBasePath)/Attachments/\(filename)")
            }
        } else if (dict["HasScreenshotData"] as? Bool) == true {
            self.attachments = [TestAttachment(title: "Screenshot", path: "\(attachmentBasePath)/Attachments/Screenshot_\(self.uuid).jpg")]
        } else {
            self.attachments = nil
        }
        
        self.failed = self.parentTest.failures.filter({ actionName.contains($0.message) && actionName.contains(":\($0.lineNumber)") && actionName.contains($0.fileName.count > 0 ? $0.fileName : " ") }).count > 0
        
        self.parentAction?.add(self)
    }
    
    public func add(_ subAction: TestAction) {
        subActions.append(subAction)
    }
    
    public func hasAttachment() -> Bool {
        guard let attachments = attachments else { return false }
        return attachments.count > 0
    }
    
    public func hasScreenshot() -> Bool {
        guard let attachments = attachments, attachments.count == 1 else { return false }
        guard let attachment = attachments.first else { return false }
        
        return attachment.isAutomaticScreenshot
    }
    
    // MARK: - Protocols
    
    var hashValue: Int { return uuid.hashValue }
    
    static func ==(lhs: TestAction, rhs: TestAction) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
