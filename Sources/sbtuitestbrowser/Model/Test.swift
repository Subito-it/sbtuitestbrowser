//
// Test.swift
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

class Test: ListItem, FailableItem, Hashable, Equatable {
    let name: String
    let startTimeinterval: TimeInterval
    let stopTimeinterval: TimeInterval
    let duration: TimeInterval
    unowned var parentSuite: TestSuite
    let failures: [TestFailure]
    var diagnosticReportUrl: URL?
    
    private let actionsDataUrl: URL?
    
    init(dict: [String : Any], parentSuite: TestSuite) {
        self.name = dict["TestName"] as! String
        self.duration = dict["Duration"] as! TimeInterval
        self.parentSuite = parentSuite
        
        guard let activitySummaries = dict["ActivitySummaries"] as? [[String : Any]] else {
            self.startTimeinterval = 0.0
            self.stopTimeinterval = 0.0
            self.failures = []
            self.actionsDataUrl = nil

            return
        }
        
        var startTimeinterval = TimeInterval(Float.greatestFiniteMagnitude)
        var stopTimeinterval = 0.0
        
        for activitySummary in activitySummaries {
            startTimeinterval = min(startTimeinterval, activitySummary["StartTimeInterval"] as? TimeInterval ?? TimeInterval(Float.greatestFiniteMagnitude))
            stopTimeinterval = max(stopTimeinterval, activitySummary["FinishTimeInterval"] as? TimeInterval ?? 0.0)
        }
        
        self.startTimeinterval = startTimeinterval
        self.stopTimeinterval = stopTimeinterval
        
        let failureSummaries = dict["FailureSummaries"] as? [[String : Any]]
        failures = failureSummaries?.map { TestFailure(dict: $0) } ?? []
        
        let temporaryUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sbtuitesttunnel")
        
        try? FileManager.default.createDirectory(at: temporaryUrl, withIntermediateDirectories: true, attributes: nil)
        let actionsDataUrl = temporaryUrl.appendingPathComponent(ProcessInfo().globallyUniqueString)
        
        let d = try? JSONSerialization.data(withJSONObject: activitySummaries, options: [])
        try? d?.write(to: actionsDataUrl)
        self.actionsDataUrl = actionsDataUrl
    }
    
    public func firstFailingAction() -> TestAction? {
        return actions().first(where: { $0.failed })
    }
    
    public func hasScreenshots() -> Bool {
        return actions().first(where: { $0.screenshotPath != nil }) != nil
    }
    
    public func actions() -> [TestAction] {
        let start = CFAbsoluteTimeGetCurrent()
        defer { print("Action processing took \(CFAbsoluteTimeGetCurrent() - start)s") }

        guard let actionsDataUrl = self.actionsDataUrl,
              let actionData = try? Data(contentsOf: actionsDataUrl),
              let rawActions = (try? JSONSerialization.jsonObject(with: actionData, options: [])) as? [[String : Any]] else {
            return []
        }
        
        return actions(from: rawActions, parentAction: nil, parentTest: self)
    }
    
    // MARK: - Private
    
    private func actions(from dicts: [[String : Any]], parentAction: TestAction?, parentTest: Test) -> [TestAction] {
        var ret = [TestAction]()
        
        for dict in dicts {
            let action = TestAction(dict: dict, parentAction: parentAction, parentTest: parentTest)
            
            ret.append(action)
            
            if let subActivities = dict["SubActivities"] as? [[String : Any]] {
                ret += actions(from: subActivities, parentAction: action, parentTest: parentTest)
            }
        }
        
        return ret
    }
    
    // MARK: - Protocols
    
    var hashValue: Int { return "\(parentSuite.name)-\(name)".hashValue }
    
    static func ==(lhs: Test, rhs: Test) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hasFailure() -> Bool {
        return failures.count > 0
    }
    
    func hasCrashed() -> Bool {
        return diagnosticReportUrl != nil || failures.contains(where: { $0.crash })
    }
}
