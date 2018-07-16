//
// DiagnosticReportRouteHandler.swift
//
// Copyright (C) 2018 Subito.it S.r.l (www.subito.it)
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
    
    public func diagnosticReportHandler(request: HTTPRequest, _ response: HTTPResponse) {
        defer {
            response.completed()
        }
        
        let runPlist = request.urlVariables["runplist"] ?? ""
        let suiteName = request.urlVariables["suitename"] ?? ""
        let testName = request.urlVariables["testname"] ?? ""
        
        guard let run = self.runs.first(where: { $0.id == runPlist }),
              let suite = run.suites.first(where: { $0.name == suiteName }),
              let test = suite.test(named: testName) else {
            response.appendBody(string: h3("Error! DiagnosticRoute #1"))
            response.completed()
            return
        }
        
        guard let diagnosticReportUrl = test.diagnosticReportUrl,
              let diagnosticReportContent = try? String(contentsOf: diagnosticReportUrl) else {
            response.appendBody(string: h3("Error! DiagnosticRoute #2"))
            response.completed()
            return
        }
        
        let paramDict = request.queryParamsDict
        let queryParameters = paramDict.queryString()
        
        let htmlPage = HTMLPage(title: "UI Test Browser - Diagnostic report")
        
        htmlPage.div(id: "header") {
            htmlPage.div(class: "centered") {
                htmlPage.button("Home", link: "/\(queryParameters)")
                htmlPage.append(body: "・&nbsp;")
                htmlPage.button("Run summary", link: "/details/\(run.id)\(queryParameters)")
                htmlPage.append(body: "・&nbsp;")
                htmlPage.button("Suite summary", link: "/details/\(run.id)/\(suite.name)\(queryParameters)")
                htmlPage.append(body: "・&nbsp;")
                htmlPage.button("Test summary", link: "/details/\(run.id)/\(suite.name)/\(test.name)\(queryParameters)")

            }
        }
        htmlPage.div(id: "header-padding")
        htmlPage.append(body: """
                    <script>
                        $('#header-padding').css('height', $('#header').outerHeight());
                    </script>
                """)
        
        let testDescription = test.name.dropLast(2)
        
        htmlPage.append(body: """
            <div class='separator'>
            <b>\(testDescription)</b>
            </div>
            """)
        
        let formattedContent = diagnosticReportContent
            .replacingOccurrences(of: "\n", with: "<br />")
            .replacingOccurrences(of: "\t", with: "&#09;")

        htmlPage.inlineBlock(formattedContent, class: "code")
        
        response.appendBody(string: htmlPage.html())
        
        response.completed()
    }
}
