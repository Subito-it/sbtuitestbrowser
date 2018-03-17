//
// RunRouteHandler.swift
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
    
    public func runHandler(request: HTTPRequest, _ response: HTTPResponse) {
        let runPlist = request.urlVariables["runplist"] ?? ""
        guard let run = self.runs.first(where: { $0.id == runPlist }) else {
            response.completed()
            return
        }
        
        response.wrapDefaultFont() {
            let showErrorsOnly = request.paramBoolValue(name: "errors_only")
            let showErrorsDetails = request.paramBoolValue(name: "errors_details")

            let paramDict = request.queryParamsDict
            let queryParametersWithToggledErrors = paramDict.toggle(key: "errors_only").queryString()
            var errorLink = "<a href='/details/\(run.id)\(queryParametersWithToggledErrors)'>\(showErrorsOnly ? "Show All" : "Show Errors Only")</a>"
            
            let queryParametersWithToggledErrorsDetails = paramDict.toggle(key: "errors_details").queryString()
            let errorDetailLink = "<a href='/details/\(run.id)\(queryParametersWithToggledErrorsDetails)'>\(showErrorsDetails ? "Hide Errors Details" : "Show Errors Details")</a>"
            
            errorLink = "\(errorDetailLink)&nbsp;&nbsp;\(errorLink)"
            
            let queryParameters = paramDict.queryString()
            response.threeColumnsBody(leftColumn: "<a href='/\(queryParameters)'>Home</a>",
                centerColumn: "&nbsp;",
                rightColumn: errorLink)
            
            response.appendBody(string: "<hr />")
            
            response.appendBody(string: "<h3>")
            let coverageColor = "blue"
            let codeCoverageLink = (run.codeCoveragePath != nil) ? "<br><br><a href='/coverage/\(run.id)' style='color:\(coverageColor)'>code coverage</a>&nbsp;" : ""
            
            if showErrorsOnly {
                response.threeColumnsBody(leftColumnLink: (run.previousFailed as? TestRun)?.id.appending(queryParameters),
                                          centerColumn: "\(run.displayName())<br /><small>\(run.failingSuites().count) of \(run.suites.count) failed</small>\(codeCoverageLink)",
                    rightColumnLink: (run.nextFailed as? TestRun)?.id.appending(queryParameters))
            } else {
                response.threeColumnsBody(leftColumnLink: (run.previous as? TestRun)?.id.appending(queryParameters),
                                          centerColumn: "\(run.displayName())<br /><small>\(run.failingSuites().count) of \(run.suites.count) failed</small>\(codeCoverageLink)",
                    rightColumnLink: (run.next as? TestRun)?.id.appending(queryParameters))
            }
            
            response.appendBody(string: "</h3>")
            for suite in run.suites {
                let color = suite.hasFailure() ? "red" : "green"
                let crash = suite.hasCrashed() ? "🚨 " : ""
                let suiteHasFailure = suite.hasFailure()
                if !showErrorsOnly || suiteHasFailure {
                    response.appendBody(string: "\(crash)<a href='/details/\(run.id)/\(suite.name)\(queryParameters)' style='color:\(color)'>\(suite.name)</a>")
                    response.appendBody(string: "&nbsp;\(suite.totalDuration().durationString())<br>")
                    
                    if showErrorsDetails && suiteHasFailure {
                        for failingTest in suite.failingTests() {
                            guard let failedAction = failingTest.firstFailingAction()?.name else {
                                continue
                            }
                            response.appendBody(string: "<a style='padding-left: 20px; color:red' href='/details/\(failingTest.parentSuite.parentRun.id)/\(failingTest.parentSuite.name)/\(failingTest.name)\(queryParameters)'>\(failingTest.name)</a><br />")
                            response.appendBody(string: "<div style='padding-left: 40px; color:SlateGrey'><small>\(failedAction)</small></div><br />")
                        }
                    }
                }
            }
        }
        
        response.completed()
    }
}
