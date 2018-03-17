//
// SuiteRouteHandler.swift
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

    public func suiteHandler(request: HTTPRequest, _ response: HTTPResponse) {
        let runPlist = request.urlVariables["runplist"] ?? ""
        let suiteName = request.urlVariables["suitename"] ?? ""
        
        guard let run = self.runs.first(where: { $0.id == runPlist }),
            let suite = run.suite(named: suiteName) else {
                response.appendBody(string: h3("Error! SuiteRoute #1"))
                response.completed()
                return
        }
        
        response.wrapDefaultFont() {
            let showErrorsOnly = request.paramBoolValue(name: "errors_only")
            let showErrorsDetails = request.paramBoolValue(name: "errors_details")
            
            let paramDict = request.queryParamsDict
            let queryParametersWithToggledErrors = paramDict.toggle(key: "errors_only").queryString()
            var errorLink = "<a href='/details/\(run.id)/\(suiteName)\(queryParametersWithToggledErrors)'>\(showErrorsOnly ? "Show All" : "Show Errors Only")</a>"
            
            let queryParametersWithToggledErrorsDetails = paramDict.toggle(key: "errors_details").queryString()
            let errorDetailLink = "<a href='/details/\(run.id)/\(suiteName)\(queryParametersWithToggledErrorsDetails)'>\(showErrorsDetails ? "Hide Errors Details" : "Show Errors Details")</a>"
            
            errorLink = "\(errorDetailLink)&nbsp;&nbsp;\(errorLink)"
            
            let queryParameters = paramDict.queryString()
            response.threeColumnsBody(leftColumn: "<a href='/\(queryParameters)'>Home</a><br /><a style='padding-left: 20px;' href='/details/\(run.id)\(queryParameters)'>\(run.displayName())</a>",
                centerColumn: "&nbsp;",
                rightColumn: errorLink)
            response.appendBody(string: "<hr />")
            
            response.appendBody(string: "<h3>")
            if showErrorsOnly {
                response.threeColumnsBody(leftColumnLink: (suite.previousFailed as? TestSuite)?.name.appending(queryParameters),
                                          centerColumn: "\(suiteName)<br /><small>\(suite.failingTests().count) of \(suite.tests.count) failed</small>",
                    rightColumnLink: (suite.nextFailed as? TestSuite)?.name.appending(queryParameters))
            } else {
                response.threeColumnsBody(leftColumnLink: (suite.previous as? TestSuite)?.name.appending(queryParameters),
                                          centerColumn: "\(suiteName)<br /><small>\(suite.failingTests().count) of \(suite.tests.count) failed</small>",
                    rightColumnLink: (suite.next as? TestSuite)?.name.appending(queryParameters))
            }
            response.appendBody(string: "</h3>")
            
            for test in suite.tests {
                let color = test.hasFailure() ? "red" : "green"
                let crash = test.hasCrashed() ? "🚨 " : ""
                let testHasFailure = test.hasFailure()
                if !showErrorsOnly || testHasFailure {
                    response.appendBody(string: "\(crash)<a href='/details/\(run.id)/\(suiteName)/\(test.name)' style='color:\(color)'>\(test.name)</a>")
                    response.appendBody(string: "&nbsp;\(test.duration.durationString())<br>")
                    
                    if showErrorsDetails && testHasFailure,
                        let failedAction = test.firstFailingAction()?.name {
                        response.appendBody(string: "<div style='padding-left: 20px; color:SlateGrey'><small>\(failedAction)</small></div><br />")
                    }
                }
            }
        }
        
        response.completed()
    }
}
