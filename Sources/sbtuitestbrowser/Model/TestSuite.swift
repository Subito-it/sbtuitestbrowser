//
// TestSuite.swift
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

class TestSuite: ListItem, FailableItem, Hashable, Equatable {
    let name: String
    unowned var parentRun: TestRun
    
    private(set) var tests = [Test]()
    
    init(dict: [String : Any], parentRun: TestRun) {
        self.name = dict["ParentTestName"] as! String
        self.parentRun = parentRun
    }
    
    public func add(_ tests: [Test]) {
        var mTests = self.tests + tests
        
        mTests.sort(by: { return ($0.actions.first?.startTimeinterval ?? 0) < ($1.actions.first?.startTimeinterval ?? 0) })
        mTests.listify()
        
        self.tests = mTests
    }
    
    public func test(named: String) -> Test? {
        return tests.first(where: { $0.name == named})
    }

    public func totalTests(errorsOnly: Bool) -> Int {
        if errorsOnly {
            return tests.filter({ $0.hasFailure() }).count
        } else {
            return tests.count
        }
    }
    
    public func failingTests() -> [Test] {
        return tests.filter { $0.hasFailure() }
    }
    
    public func startTimeInterval() -> TimeInterval {
        guard tests.count > 0 else {
            return parentRun.createdDate()?.timeIntervalSinceReferenceDate ?? Date().timeIntervalSinceReferenceDate
        }
        
        var sti = Double.greatestFiniteMagnitude
        for test in tests {
            if test.startTimeinterval > 0 {
                sti = min(sti, test.startTimeinterval)
            }
        }
        
        return sti
    }
    
    public func stopTimeInterval() -> TimeInterval {
        guard tests.count > 0 else {
            return parentRun.createdDate()?.timeIntervalSinceReferenceDate ?? Date().timeIntervalSinceReferenceDate
        }
        
        var sti = 0.0
        for test in tests {
            if test.startTimeinterval > 0 {
                sti = max(sti, test.stopTimeinterval)
            }
        }
        
        return sti
    }
    
    public func totalDuration() -> TimeInterval {
        return tests.reduce(0.0, { $0 + $1.duration })        
    }
    
    // MARK: - Protocols
    
    var hashValue: Int { return name.hashValue }
    
    static func ==(lhs: TestSuite, rhs: TestSuite) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hasFailure() -> Bool {
        return tests.reduce(false) { $0 || $1.hasFailure() }
    }
}
