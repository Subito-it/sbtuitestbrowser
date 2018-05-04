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

    private(set) var actions = [TestAction]()
    
    init(dict: [String : Any], parentSuite: TestSuite) {
        self.name = dict["TestName"] as! String
        self.duration = dict["Duration"] as! TimeInterval
        
        let failureSummaries = dict["FailureSummaries"] as? [[String : Any]]
        failures = failureSummaries?.map { TestFailure(dict: $0) } ?? []

        if let activitySummaries = dict["ActivitySummaries"] as? [[String : Any]] {
            var startTimeinterval = TimeInterval(Float.greatestFiniteMagnitude)
            var stopTimeinterval = 0.0
            
            for activitySummary in activitySummaries {
                startTimeinterval = min(startTimeinterval, activitySummary["StartTimeInterval"] as? TimeInterval ?? TimeInterval(Float.greatestFiniteMagnitude))
                stopTimeinterval = max(stopTimeinterval, activitySummary["FinishTimeInterval"] as? TimeInterval ?? 0.0)
            }
            
            self.startTimeinterval = startTimeinterval
            self.stopTimeinterval = stopTimeinterval
        } else {
            self.startTimeinterval = 0.0
            self.stopTimeinterval = 0.0
        }
        
        self.parentSuite = parentSuite
    }
    
    public func add(_ actions: [TestAction]) {
        self.actions += actions
    }
    
    public func firstFailingAction() -> TestAction? {
        return actions.first(where: { $0.failed })
    }
    
    public func hasScreenshots() -> Bool {
        return (actions.first(where: { $0.screenshotPath != nil }) != nil)
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
