//
// CoverageFileRouteHandler.swift
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
    
    public func coverageFileHandler(request: HTTPRequest, _ response: HTTPResponse) {
        defer {
            response.completed()
        }
        
        let runPlist = request.urlVariables["runplist"] ?? ""
        let coverageFilePathB64 = request.urlVariables["filepath"] ?? ""

        guard let run = self.runs.first(where: { $0.id == runPlist }),
              let repoBasePath = run.repoBasePath,
              let commitHash = run.commitHash,
              let coverageFilePathB64Data = Data(base64Encoded: coverageFilePathB64),
              let coverageFilePath = String(data: coverageFilePathB64Data, encoding: .utf8) else {
            response.appendBody(string: h3("Error! Coverage #1"))
            response.completed()
            return
        }
        
        guard let coveredLines = run.coverage?.coveredLines(filename: coverageFilePath),
              let totalCoverage = run.coverage?.totalCoverage(filename: coverageFilePath) else {
            response.appendBody(string: h3("Error! Coverage #2"))
            response.completed()
            return
        }
        
        let paramDict = request.queryParamsDict
        let queryParameters = paramDict.queryString()
        
        let htmlPage = HTMLPage(title: "UI Test Browser - Coverage report")
        
        htmlPage.div(id: "header") {
            htmlPage.div(class: "centered") {
                htmlPage.button("Home", link: "/\(queryParameters)")
                htmlPage.append(body: "・&nbsp;")
                htmlPage.button("Run summary", link: "/details/\(run.id)\(queryParameters)")
            }
        }
        htmlPage.div(id: "header-padding")
        htmlPage.append(body: """
                    <script>
                        $('#header-padding').css('height', $('#header').outerHeight());
                    </script>
                """)
        
        let coverageFile = "cd \(repoBasePath); git --no-pager show \(commitHash):\(coverageFilePath)"
        let coverageFileContent = coverageFile.shellExecute()
        let fileContentLines = coverageFileContent.components(separatedBy: "\n")
        
        htmlPage.append(body: """
            <div class='separator'>
            <b>\(run.displayName())</b><br/>Coverage: \(totalCoverage)%
            </div>
            """)
        
        htmlPage.div(id: "", class: "item code") {
        
            for (indx, fileContentLine) in fileContentLines.enumerated() {
                let markerClass = coveredLines.contains(indx) ? "" : "red_fill"
                let lineClass = coveredLines.contains(indx) ? "gray" : "uncovered_line"
                var line = fileContentLine.replacingOccurrences(of: " ", with: "&nbsp;")
                if line.isEmpty {
                    line = "&nbsp;"
                }
                
                htmlPage.inlineBlock("", class: markerClass, width: 5)
                htmlPage.inlineBlock(line, class: lineClass)
                htmlPage.newline()
            }
        }

        response.appendBody(string: htmlPage.html())
        
        response.completed()
    }
}
