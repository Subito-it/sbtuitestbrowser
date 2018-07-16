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
        let showErrorsOnly = request.paramBoolValue(name: "errors_only")
        let paramDict = request.queryParamsDict
        let queryParametersWithToggledErrors = paramDict.toggle(key: "errors_only").queryString()
        let queryParameters = paramDict.queryString()
        
        let htmlPage = HTMLPage(title: "UI Test Browser - Home")
        
        htmlPage.div(id: "header", class: "centered") {            
            if self.parsingProgress < 1.0 {
                htmlPage.button("Parsing results (\(Int(self.parsingProgress * 100))%)", link: "#", class: "button_deselected")
                htmlPage.append(body: """
                    <script>
                        setTimeout(function(){ window.location.reload(1); }, 2000);
                    </script>
                """)
            } else {
                htmlPage.button("Parse results", link: "#", id: "executeParseRequest")
                htmlPage.append(body: """
                    <script>
                        $('#executeParseRequest').click(function(event) {
                            event.preventDefault();
                            $.get( "/parse", function( data ) {
                                alert( "Parse requested" );
                                location.reload();
                            });
                        });
                    </script>
                """)
            }
            
            let errorButtonClass = showErrorsOnly ? "button_selected" : "button_deselected"
            htmlPage.button("Only failing", link: "/\(queryParametersWithToggledErrors)", class: errorButtonClass)
        }
        htmlPage.div(id: "header-padding")
        htmlPage.append(body: """
                    <script>
                        $('#header-padding').css('height', $('#header').outerHeight());
                    </script>
                """)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        var lastRunDate: String = ""
        for run in self.runs {
            if let runCreateDate = run.createdDate() {
                let runDate = dateFormatter.string(from: runCreateDate)
                if runDate != lastRunDate {
                    htmlPage.append(body: "<div class='separator'><b>\(runDate)</b></div>")
                }
                lastRunDate = runDate
            }
            
            let hasFailedTest = run.hasFailure() || (run.totalTests(errorsOnly: false) == 0)
            let hasCrashedTest = run.hasCrashed()
            let divClass = hasFailedTest ? "failure" : ""
            let divIcon = hasFailedTest ? HTMLPage.Icons.failure : HTMLPage.Icons.success
            let crashIcon = (hasFailedTest && hasCrashedTest) ? HTMLPage.Icons.crash : ""
            
            let totalTests = run.totalTests(errorsOnly: showErrorsOnly)
            let totalTestsFailures = run.totalTests(errorsOnly: true)
            let failureDescription = totalTestsFailures > 0 ? " | \(totalTestsFailures) failed" : ""
            let testDescription = showErrorsOnly ? "\(totalTestsFailures) failed" : "\(totalTests) tests\(failureDescription)"
            if (!showErrorsOnly || run.totalTests(errorsOnly: true) > 0) {
                htmlPage.div(class: "item \(divClass)") {
                    htmlPage.append(body: crashIcon)

                    let buttonText = "\(run.displayName())<br/><div>\(divIcon) \(testDescription)</div>"
                    htmlPage.button(buttonText, link: "/details/\(run.id)\(queryParameters)")
                }
            }
        }
        
        response.appendBody(string: htmlPage.html())
        
        response.completed()
    }
}
