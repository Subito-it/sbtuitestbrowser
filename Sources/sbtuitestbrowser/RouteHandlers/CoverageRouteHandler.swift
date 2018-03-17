//
// CoverageRouteHandler.swift
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
    
    public func coverageHandler(request: HTTPRequest, _ response: HTTPResponse) {
        defer {
            response.completed()
        }
        
        let runPlist = request.urlVariables["runplist"] ?? ""
        
        guard let run = self.runs.first(where: { $0.id == runPlist }),
              let coveragePath = run.codeCoveragePath else {
                response.appendBody(string: h3("Error! Coverage #1"))
                response.completed()
                return
        }
        
        let coverageUrl = URL(fileURLWithPath: coveragePath)
        guard let json = (try? JSONSerialization.jsonObject(with: Data(contentsOf: coverageUrl))) as? [String: Any] else {
            response.appendBody(string: h3("Error! Coverage #2"))
            response.completed()
            return
        }
        
        guard let datas = json["data"] as? [Any],
              let data = datas.first as? [String: Any],
              let files = data["files"] as? [[String: Any]],
              let totals = data["totals"] as? [String: Any],
              let totalLines = totals["lines"] as? [String: Any],
              let totalCoverage = totalLines["percent"] as? Int else {
            response.appendBody(string: h3("Error! Coverage #3"))
            response.completed()
            return
        }
        
        var coverageFiles = [(Int, String)]()
        for file in files {
            guard let filename = file["filename"] as? String,
                let summary = file["summary"] as? [String: Any],
                let lines = summary["lines"] as? [String: Any],
                let coveragePercentage = lines["percent"] as? Int else {
                    continue
            }
            coverageFiles.append((coveragePercentage, filename))
        }
        
        coverageFiles.sort(by: { $0.0 < $0.1 })
        
        response.wrapDefaultFont() {
            response.threeColumnsBody(leftColumn: "<a href='/'>Home</a><br /><a style='padding-left: 20px;' href='/details/\(run.id)'>\(run.displayName())</a>",
                                      centerColumn: "&nbsp;",
                                      rightColumn: "&nbsp;")
            response.appendBody(string: "<hr />")

            response.appendBody(string: h3("Total coverage: \(totalCoverage)%"))
            
            for coverageFile in coverageFiles {
                response.appendBody(string: "(\(coverageFile.0)%) \(coverageFile.1)<br />")
            }
        }
        
        response.completed()
    }
}
