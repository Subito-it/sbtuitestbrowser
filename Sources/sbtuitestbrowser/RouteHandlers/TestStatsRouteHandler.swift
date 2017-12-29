//
// TestStatsRouteHandler.swift
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
import PerfectHTTP

extension RouteHandler {
    
    public func testStatsHandler(request: HTTPRequest, _ response: HTTPResponse) {
        var stats = ["last_duration_secs": 0.0, "avg_duration_sec": 0.0]

        if let testIdComponents = request.param(name: "id")?.components(separatedBy: "/"),
           testIdComponents.count == 2 {
            let suiteName = testIdComponents[0]
            let testName = testIdComponents[1].replacingOccurrences(of: "()", with: "") + "()"
            
            var matchingTests = [Test]()
            for run in self.runs {
                guard let test = run.suite(named: suiteName)?.test(named: testName) else {
                    continue
                }
                
                matchingTests.append(test)
            }
            
            if let lastDuration = matchingTests.first?.duration {
                stats["last_duration_secs"] = lastDuration
                stats["avg_duration_sec"] = matchingTests.reduce(lastDuration, { ($0 + $1.duration) / 2.0 })
            }
        }
        
        _ = try? response.setBody(json: stats)
        
        response.completed()
    }
}
