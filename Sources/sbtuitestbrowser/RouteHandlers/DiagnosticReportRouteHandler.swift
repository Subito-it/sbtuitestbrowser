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
        
        response.wrapDefaultFont() {
            let paramDict = request.queryParamsDict
            
            let queryParameters = paramDict.queryString()

            response.threeColumnsBody(leftColumn: "<a href='/\(queryParameters)'>Home</a><br /><a style='padding-left: 20px;' href='/details/\(run.id)\(queryParameters)'>\(run.displayName())</a><br /><a style='padding-left: 40px;' href='/details/\(run.id)/\(suite.name)\(queryParameters)'>\(suite.name)</a><br /><a style='padding-left: 60px;' href='/details/\(run.id)/\(suite.name)/\(test.name)\(queryParameters)'>\(test.name)</a>",
                centerColumn: "&nbsp;",
                rightColumn: "&nbsp;")
            
            response.appendBody(string: "<hr />")
            
            response.appendBody(string: "<h3>")
            
            response.threeColumnsBody(leftColumnLink: nil, centerColumn: "<b>diagnostic report</b>", rightColumnLink: nil)
            
            response.appendBody(string: "</h3>")
            
            let formattedContent = diagnosticReportContent
                .replacingOccurrences(of: "\n", with: "<br />")
                .replacingOccurrences(of: "\t", with: "&#09;")
            
            response.appendBody(string: formattedContent)
        }
        
        response.completed()
    }
}
