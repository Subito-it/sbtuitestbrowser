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
        
        let totalCoverage = run.coverage?.totalCoverage() ?? 0
        let coverageFiles = run.coverage?.fileList() ?? []
        
        htmlPage.append(body: """
            <div class='separator'>
            <b>\(run.displayName())</b><br/>Total coverage: \(totalCoverage)%
            </div>
            """)

        for coverageFile in coverageFiles {
            guard let coverageFileB64 = coverageFile.filePath.data(using: .utf8)?.base64EncodedString() else {
                continue
            }
            
            htmlPage.div(id: "", class: "item step") {
                htmlPage.inlineBlock("\(coverageFile.coveragePercentage)%", width: 35)
                htmlPage.button(coverageFile.shortFilePath, link: "/coverage/\(run.id)/\(coverageFileB64)")
            }
        }

        response.appendBody(string: htmlPage.html())
        
        response.completed()
    }
}
