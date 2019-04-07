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
        
        let showErrorsOnly = request.paramBoolValue(name: "errors_only")
        let showErrorsDetails = request.paramBoolValue(name: "errors_details")

        let paramDict = request.queryParamsDict
        let queryParameters = paramDict.queryString()
        
        let queryParametersWithToggledErrors = paramDict.toggle(key: "errors_only").queryString()
        let queryParametersWithToggledErrorsDetails = paramDict.toggle(key: "errors_details").queryString()

        let htmlPage = HTMLPage(title: "UI Test Browser - \(run.displayName())")
        
        htmlPage.div(id: "header") {
            htmlPage.div(class: "centered") {
                htmlPage.button("Home", link: "/\(queryParameters)")
            }
            
            htmlPage.div(class: "centered") {
                if run.hasFailure() {
                    let errorButtonClass = showErrorsOnly ? "button_selected" : "button_deselected"
                    htmlPage.button("Only failing", link: "/details/\(run.id)\(queryParametersWithToggledErrors)", class: errorButtonClass)
                    
                    let errorDetailsButtonClass = showErrorsDetails ? "button_selected" : "button_deselected"
                    htmlPage.button("Fail details", link: "/details/\(run.id)\(queryParametersWithToggledErrorsDetails)", class: errorDetailsButtonClass)
                }
                
                if let coverageInfoPath = run.codeCoveragePath,
                   let coverageInfoData = try? Data(contentsOf: URL(fileURLWithPath: coverageInfoPath)),
                   let coverageInfo = (try? JSONSerialization.jsonObject(with: coverageInfoData, options: [])) as? [String: Any],
                   let datas = coverageInfo["data"] as? [[String: Any]],
                   let totalCoverageInfo = datas.first?["totals"] as? [String: Any],
                   let totalCoverageLines = totalCoverageInfo["lines"] as? [String: Any],
                   let totalCoverage = totalCoverageLines["percent"] as? Int {
                    htmlPage.button("Coverage (\(totalCoverage)%)", link: "/coverage/\(run.id)\(queryParameters)")
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
            <b>\(run.displayName())</b> (\(Int(run.totalDuration()))s)
            </div>
            """)
        
        for suite in run.suites {
            let suiteHasFailure = suite.hasFailure()
            let crashIcon = (suiteHasFailure && suite.hasCrashed()) ? HTMLPage.Icons.crash : ""
            let divIcon = suiteHasFailure ? HTMLPage.Icons.failure : HTMLPage.Icons.success
            
            if !showErrorsOnly || suiteHasFailure {
                let divClass = suiteHasFailure ? "failure" : ""
                
                htmlPage.div(class: "item \(divClass)") {
                    htmlPage.append(body: crashIcon)
                    
                    htmlPage.button("\(divIcon) \(suite.name) (\(Int(suite.totalDuration()))s)", link: "/details/\(run.id)/\(suite.name)\(queryParameters)")
                    
                    if showErrorsDetails && suiteHasFailure {
                        for failingTest in suite.failingTests() {
                            guard let failedAction = failingTest.firstFailingAction()?.name else {
                                continue
                            }
                            
                            let failureDescription = failedAction.unescaped()
                            
                            htmlPage.newline()
                            htmlPage.append(body: "<a style='padding-left: 20px; color:red' href='/details/\(failingTest.parentSuite.parentRun.id)/\(failingTest.parentSuite.name)/\(failingTest.name)\(queryParameters)'><small>\(failingTest.name)</small></a>")
                            htmlPage.newline()
                            htmlPage.append(body: "<div style='padding-left: 40px; color:SlateGrey'><small>\(failureDescription)</small></div>")
                            htmlPage.newline()
                        }
                    }
                }
            }
        }
        
        response.appendBody(string: htmlPage.html())
        
        response.completed()
    }
}
