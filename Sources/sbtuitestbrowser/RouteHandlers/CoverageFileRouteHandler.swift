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
        
        let coverageFile = "cd \(repoBasePath); git --no-pager show \(commitHash):\(coverageFilePath)"
        let coverageFileContent = coverageFile.shellExecute()
        let fileContentLines = coverageFileContent.components(separatedBy: "\n")

        response.wrapDefaultFont() {
            response.threeColumnsBody(leftColumn: "<a href='/'>Home</a><br /><a style='padding-left: 20px;' href='/details/\(run.id)'>\(run.displayName())</a><br /><a style='padding-left: 40px;' href='/coverage/\(run.id)'>coverage</a>",
                centerColumn: "&nbsp;",
                rightColumn: "&nbsp;")
            response.appendBody(string: "<hr />")
            
            response.appendBody(string: "<h3>")
            response.threeColumnsBody(leftColumnLink: nil,
                                      centerColumn: "\(coverageFilePath)<br/><br/><small>Coverage: \(totalCoverage)%</small>",
                                      rightColumnLink: nil)
            response.appendBody(string: "</h3>")

            response.appendBody(string: "<br />")
            
            response.appendBody(string: "<div style='font-family: Menlo, Courier;'")
            for (indx, fileContentLine) in fileContentLines.enumerated() {
                let color = coveredLines.contains(indx) ? "background-color:PaleGreen;" : ""
                var line = fileContentLine.replacingOccurrences(of: " ", with: "&nbsp;")
                if line.isEmpty {
                    line = "&nbsp;"
                }

                response.appendBody(string: "<div style='\(color)'>\(line)</div>")
            }
            response.appendBody(string: "</div>")
        }

        response.completed()
    }
}
