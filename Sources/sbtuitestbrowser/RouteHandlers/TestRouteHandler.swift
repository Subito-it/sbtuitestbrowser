//
// TestRoute.swift
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
    
    private static let screencastDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        df.timeZone = TimeZone.current
        
        return df
    }()
    
    public func testHandler(request: HTTPRequest, _ response: HTTPResponse) {
        let runPlist = request.urlVariables["runplist"] ?? ""
        let suiteName = request.urlVariables["suitename"] ?? ""
        let testName = request.urlVariables["testname"] ?? ""

        guard let run = self.runs.first(where: { $0.id == runPlist }),
            let baseFolderPath = self.baseFolderURL?.path,
            let suite = run.suites.first(where: { $0.name == suiteName }),
            let test = suite.test(named: testName) else {
                response.appendBody(string: h3("Error! TestRoute #1"))
                response.completed()
                return
        }
        
        let basePath = run.plistURL.deletingLastPathComponent().path.replacingOccurrences(of: baseFolderPath, with: "")
        
        response.wrapDefaultFont() {
            let showErrorsOnly = request.paramBoolValue(name: "errors_only")
            let showScreeshots = request.paramBoolValue(name: "screenshots")
            
            let paramDict = request.queryParamsDict
            let queryParametersWithToggledScreenshots = paramDict.toggle(key: "screenshots").queryString()
            let screenshotLink = "<a href='/details/\(run.id)/\(suite.name)/\(test.name)\(queryParametersWithToggledScreenshots)'>\(showScreeshots ? "Hide screenshots" : "Show screenshots")</a>"
            
            let queryParameters = paramDict.queryString()
            response.threeColumnsBody(leftColumn: "<a href='/\(queryParameters)'>Home</a><br /><a style='padding-left: 20px;' href='/details/\(run.id)\(queryParameters)'>\(run.id)</a><br /><a style='padding-left: 40px;' href='/details/\(run.id)/\(suite.name)\(queryParameters)'>\(suite.name)</a>",
                centerColumn: "&nbsp;",
                rightColumn: screenshotLink)
            
            response.appendBody(string: "<hr />")
            
            response.appendBody(string: "<h3>")
            if showErrorsOnly {
                response.threeColumnsBody(leftColumnLink: (test.previousFailed as? Test)?.name.appending(queryParameters),
                                          centerColumn: test.name,
                                          rightColumnLink: (test.nextFailed as? Test)?.name.appending(queryParameters))
            } else {
                response.threeColumnsBody(leftColumnLink: (test.previous as? Test)?.name.appending(queryParameters),
                                          centerColumn: test.name,
                                          rightColumnLink: (test.next as? Test)?.name.appending(queryParameters))
            }
            response.appendBody(string: "</h3>")
            
            let hasActions = test.actions.count > 0
            
            // Screencast
            if let screencastURL = run.screencastURL, FileManager.default.fileExists(atPath: screencastURL.path), hasActions {
                guard let testStartDateString = test.actions.first?.name.replacingOccurrences(of: "Start Test at ", with: "") else { // lame
                    return
                }
                
                guard let testStartTimestamp = RouteHandler.screencastDateFormatter.date(from: testStartDateString)?.timeIntervalSince1970,
                    let attr = try? FileManager.default.attributesOfItem(atPath: screencastURL.path),
                    let screenCastStartDate = attr[FileAttributeKey.creationDate] as? Date else {
                        return
                }
                
                let deltaEnd = screenCastStartDate.timeIntervalSince1970 - testStartTimestamp
                
                // Screencast link
                response.appendBody(string: "<video id='screencast' width='100%' height='360' controls='true' type='video/mp4'>")
                response.appendBody(string: "<source src='/static\(basePath)/\(screencastURL.lastPathComponent)' type='video/mp4'><!-- Safari / iPhone video    --></source>")
                response.appendBody(string: "</video><br /><br />")
                response.appendBody(string: "<script type='text/javascript'>")
                response.appendBody(string: "function moveVideoCursor(pos) { var video = document.getElementById('screencast'); video.currentTime = video.duration - \(deltaEnd) + pos; }")
                response.appendBody(string: "document.getElementById('screencast').addEventListener('loadedmetadata', function() { moveVideoCursor(0); }, false);")
                response.appendBody(string: "</script>")
            }
            
            let startInterval = test.actions.first?.startTimeinterval ?? 0.0
            var lastParentAction: TestAction? = nil
            var paddingLeft = 0
            
            if hasActions {
                for action in test.actions {
                    let color = action.failed ? "red" : "green"
                    
                    if action.parentAction == nil {
                        lastParentAction = nil
                        paddingLeft = 0
                    } else if action.parentAction != lastParentAction {
                        lastParentAction = action.parentAction
                        paddingLeft += 20
                    }
                    
                    let durationString = action.duration >= 0.01 ? "\(String(format: " %.2f", action.duration))s" : ""
                    
                    let actionTimeDelta = action.startTimeinterval - startInterval
                    
                    response.appendBody(string: "<a href='#' onclick='moveVideoCursor(\(actionTimeDelta));return false;' style='color:\(color); padding-left: \(paddingLeft)px'>\(action.name)</a><font color=\"#ff9900\">\(durationString)</font><br>")
                    if let screenshotPath = action.screenshotPath, showScreeshots == true {
                        response.appendBody(string: "<br /><a href='/static\(screenshotPath)'><img style='margin-top:-10px; padding-bottom:20px; padding-left: \(paddingLeft)px; width: 100px' src='/static\(screenshotPath)' /></a><br />")
                    }
                }
            } else {
                for failure in test.failures {
                    response.appendBody(string: "<br /><font color=red>Failure in file \(failure.filePath):\(failure.lineNumber), \(failure.message)</font>")
                }
            }
        }
        
        response.completed()
    }
}
