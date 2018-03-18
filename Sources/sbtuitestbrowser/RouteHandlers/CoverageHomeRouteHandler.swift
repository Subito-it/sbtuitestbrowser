//
// CoverageHomeRouteHandler.swift
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
    
    public func coverageHomeHandler(request: HTTPRequest, _ response: HTTPResponse) {
        defer {
            response.completed()
        }
        
        let runPlist = request.urlVariables["runplist"] ?? ""
        
        guard let run = self.runs.first(where: { $0.id == runPlist }) else {
            response.appendBody(string: h3("Error! Coverage #1"))
            response.completed()
            return
        }
        
        let totalCoverage = run.coverage?.totalCoverage() ?? 0
        let coverageFiles = run.coverage?.fileList() ?? []
        
        response.wrapDefaultFont() {
            response.threeColumnsBody(leftColumn: "<a href='/'>Home</a><br /><a style='padding-left: 20px;' href='/details/\(run.id)'>\(run.displayName())</a>",
                                      centerColumn: "&nbsp;",
                                      rightColumn: "&nbsp;")
            response.appendBody(string: "<hr /><br />")

            response.appendBody(string: h3("Total coverage: \(totalCoverage)%"))
            
            response.appendBody(string: "<table>")
            for coverageFile in coverageFiles {
                guard let coverageFileB64 = coverageFile.filePath.data(using: .utf8)?.base64EncodedString() else {
                    continue
                }
                let coverageBar = "&nbsp;<div style='float: right; width: \(String(describing: Int(Double(coverageFile.coveragePercentage) / 100.0 * 50.0)))px; background-color:PaleGreen'>&nbsp;</div>"
                response.appendBody(string: "<tr><td>\(coverageFile.coveragePercentage)%\(coverageBar)</td><td><a href='/coverage/\(run.id)/\(coverageFileB64)'>\(coverageFile.shortFilePath)</a></td></tr>")
            }
            response.appendBody(string: "</table>")
        }
        
        response.completed()
    }
}
