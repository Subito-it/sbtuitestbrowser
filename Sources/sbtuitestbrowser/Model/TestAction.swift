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
    let screenshotPath: String?
    let startTimeinterval: TimeInterval
    let stopTimeinterval: TimeInterval
    let duration: TimeInterval
    unowned let parentTest: Test
    weak var parentAction: TestAction?
    
    private(set) var subActions = [TestAction]()
    
    init(dict: [String : Any], parentAction: TestAction?, parentTest: Test) {
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
        
        let screenshotBasePath = parentTest.parentSuite.parentRun.screenshotBasePath
        
        if (dict["HasScreenshotData"] as? Bool) == true {
            self.screenshotPath = "\(screenshotBasePath)Attachments/Screenshot_\(self.uuid).jpg"
        } else {
            self.screenshotPath = nil
        }
        
        self.failed = self.parentTest.failures.filter({ actionName.contains($0.message) && actionName.contains(":\($0.lineNumber)") && actionName.contains($0.fileName.characters.count > 0 ? $0.fileName : " ") }).count > 0
    }
    
    public func add(_ subAction: TestAction) {
        subActions.append(subAction)
    }
    
    // MARK: - Protocols
    
    var hashValue: Int { return uuid.hashValue }
    
    static func ==(lhs: TestAction, rhs: TestAction) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}
