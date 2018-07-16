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
        
        
        let showErrorsOnly = request.paramBoolValue(name: "errors_only")
        let showErrorsDetails = request.paramBoolValue(name: "errors_details")
        
        let paramDict = request.queryParamsDict
        let queryParameters = paramDict.queryString()
        
        let queryParametersWithToggledErrors = paramDict.toggle(key: "errors_only").queryString()
        var errorLink = "<a href='/details/\(run.id)/\(suiteName)\(queryParametersWithToggledErrors)'>\(showErrorsOnly ? "Show All" : "Show Errors Only")</a>"
        
        let queryParametersWithToggledErrorsDetails = paramDict.toggle(key: "errors_details").queryString()
        let errorDetailLink = "<a href='/details/\(run.id)/\(suiteName)\(queryParametersWithToggledErrorsDetails)'>\(showErrorsDetails ? "Hide Errors Details" : "Show Errors Details")</a>"
        
        errorLink = "\(errorDetailLink)&nbsp;&nbsp;\(errorLink)"
        
        let htmlPage = HTMLPage(title: "UI Test Browser - Home")
        
        htmlPage.div(id: "header") {
            htmlPage.div(class: "centered") {
                htmlPage.button("Home", link: "/\(queryParameters)")
                htmlPage.append(body: "・&nbsp;")
                htmlPage.button("Run summary", link: "/details/\(run.id)\(queryParameters)")
            }
            
            if suite.hasFailure() {
                htmlPage.div(class: "centered") {
                    let queryParametersWithToggledErrorsDetails = paramDict.toggle(key: "errors_details").queryString()
                    
                    let errorButtonClass = showErrorsOnly ? "button_selected" : "button_deselected"
                    htmlPage.button("Only failing", link: "/details/\(run.id)/\(suiteName)\(queryParametersWithToggledErrors)", class: errorButtonClass)
                    
                    let errorDetailButtonClass = showErrorsDetails ? "button_selected" : "button_deselected"
                    htmlPage.button("Fail details", link: "/details/\(run.id)/\(suiteName)\(queryParametersWithToggledErrorsDetails)", class: errorDetailButtonClass)
                }
            }
        }
        htmlPage.div(id: "header-padding")
        htmlPage.append(body: """
                    <script>
                        $('#header-padding').css('height', $('#header').outerHeight());
                    </script>
                """)
        
        htmlPage.append(body: """
                <div class='separator'>
                    <b>\(suite.name)</b> done
                    in \(Int(suite.totalDuration()))s
                </div>
            """)
        
        for test in suite.tests {
            let testHasFailure = test.hasFailure()
            let crashIcon = (testHasFailure && test.hasCrashed()) ? HTMLPage.Icons.crash : ""
            let divIcon = testHasFailure ? HTMLPage.Icons.failure : HTMLPage.Icons.success

            if !showErrorsOnly || testHasFailure {
                let divClass = testHasFailure ? "failure" : ""
                
                htmlPage.div(class: "item \(divClass)") {
                    htmlPage.append(body: crashIcon)
                    
                    let testName = test.name.dropLast(2)
                    htmlPage.button("\(divIcon) \(testName) (\(Int(test.duration))s)", link: "/details/\(run.id)/\(suiteName)/\(test.name)")
                    
                    if showErrorsDetails && testHasFailure,
                        let failedAction = test.firstFailingAction()?.name {
                        let failureDescription = failedAction.unescaped.replacingOccurrences(of: "\n", with: "<br/>")
                        htmlPage.append(body: "<div style='padding-left: 20px; color:SlateGrey'><small>\(failureDescription)</small></div><br />")
                    }
                }
            }
        }
        
        response.appendBody(string: htmlPage.html())
        response.completed()
    }
}
