//
// HomeRoute.swift
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
    
    public func homeHandler(request: HTTPRequest, _ response: HTTPResponse) {
        let minRunsForFrequentFail = 3
        
        response.wrapDefaultFont { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let showErrorsOnly = request.paramBoolValue(name: "errors_only")
            let showErrorsDetails = request.paramBoolValue(name: "errors_details")
            
            let paramDict = request.queryParamsDict
            let queryParametersWithToggledErrors = paramDict.toggle(key: "errors_only").queryString()
            let errorLink = "<a href='/\(queryParametersWithToggledErrors)'>\(showErrorsOnly ? "Show All" : "Show Errors Only")</a>"
            
            response.threeColumnsBody(leftColumn: "<a href='/parse'>parse ui tests results</a>",
                                      centerColumn: "&nbsp;",
                                      rightColumn: errorLink)
            
            response.appendBody(string: "<hr />")
            
            response.threeColumnsBody(leftColumn: h3("Last sessions"),
                                      centerColumn: "&nbsp;",
                                      rightColumn: self.parsingProgress < 1.0 ? "<br/><small style='color: red'>parsing in progess (\(Int(self.parsingProgress * 100))%)</small><script>setTimeout(function(){ window.location.reload(1); }, 2000);</script>" : "")
            
            let queryParameters = paramDict.queryString()
            for run in self.runs {
                let hasFailedTest = (run.suites.reduce(false) { $0 || $1.hasFailure() }) || (run.totalTests(errorsOnly: false) == 0)
                let hasCrashedTest = (run.suites.reduce(false) { $0 || $1.hasCrashed() })
                let color = hasFailedTest ? "red" : "green"
                let crash = (hasFailedTest && hasCrashedTest) ? "🚨 " : ""
                
                let totalTests = run.totalTests(errorsOnly: showErrorsOnly)
                let totalSuites = run.totalSuites(errorsOnly: showErrorsOnly)
                if (!showErrorsOnly || run.totalTests(errorsOnly: true) > 0) {
                    response.appendBody(string: "<a href='/details/\(run.id)\(queryParameters)' style='color:\(color)'>\(run.createdString()) - \(run.deviceName)</a>&nbsp;")
                    response.appendBody(string: "<font color=\"\(color)\">(\(totalSuites) test suites, \(totalTests) tests)</font>&nbsp;")
                    response.appendBody(string: "\(run.totalDuration().durationString())&nbsp;")
                    response.appendBody(string: "<br />")
                }
            }
            
            // disable frequently failing which are crashing
            if self.parsingProgress == 1.0 {
                response.appendBody(string: "<br /><br />")
                response.appendBody(string: "<hr />")
                
                var errorDetailLink = ""
                if self.runs.count >= minRunsForFrequentFail {
                    let queryParametersWithToggledErrorsDetails = paramDict.toggle(key: "errors_details").queryString()
                    errorDetailLink = "<a href='/\(queryParametersWithToggledErrorsDetails)'>\(showErrorsDetails ? "Hide Errors Details" : "Show Errors Details")</a>"
                }
                
                response.threeColumnsBody(leftColumn: "<div style='float: left'>\(h3("Frequently failing", bottomMargin: false))<small>Tests that failed consistently in the last \(minRunsForFrequentFail) runs</small></div><br /><br />",
                    centerColumn: "&nbsp;",
                    rightColumn: errorDetailLink)
                
                response.appendBody(string: "<br /><br />")
                
                if self.runs.count < minRunsForFrequentFail {
                    response.appendBody(string: "Not enough data")
                } else {
                    let fFailingTests = self.runs.frequentlyFailingTests(minRunsForFrequentFail: minRunsForFrequentFail)
                    
                    var lastSuite = ""
                    var failingParameters = paramDict
                    failingParameters["errors_only"] = "1"
                    let queryParameters = failingParameters.queryString()
                    for failingTest in fFailingTests {
                        if failingTest.parentSuite.name != lastSuite {
                            response.appendBody(string: "<a style='color:red' href='/details/\(failingTest.parentSuite.parentRun.id)/\(failingTest.parentSuite.name)\(queryParameters)'>\(failingTest.parentSuite.name)</a><br />")
                        }
                        response.appendBody(string: "<a style='padding-left: 20px; color:red' href='/details/\(failingTest.parentSuite.parentRun.id)/\(failingTest.parentSuite.name)/\(failingTest.name)\(queryParameters)'>\(failingTest.name)</a>")
                        if showErrorsDetails,
                            let failedAction = failingTest.firstFailingAction()?.name {
                            response.appendBody(string: "<div style='padding-left: 40px;color:SlateGrey'><small>\(failedAction)</small></div>")
                        }
                        
                        response.appendBody(string: "<br />")
                        
                        lastSuite = failingTest.parentSuite.name
                    }
                }
            }
        }
        
        response.completed()
    }
}
