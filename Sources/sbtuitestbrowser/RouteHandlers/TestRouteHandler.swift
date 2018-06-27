//
// TestRouteHandler.swift
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
    
    public func testHandler(request: HTTPRequest, _ response: HTTPResponse) {
        let runPlist = request.urlVariables["runplist"] ?? ""
        let suiteName = request.urlVariables["suitename"] ?? ""
        let testName = request.urlVariables["testname"] ?? ""

        guard let run = self.runs.first(where: { $0.id == runPlist }),
            let suite = run.suites.first(where: { $0.name == suiteName }),
            let test = suite.test(named: testName) else {
                response.appendBody(string: h3("Error! TestRoute #1"))
                response.completed()
                return
        }
        
        response.wrapDefaultFont() {
            let showErrorsOnly = request.paramBoolValue(name: "errors_only")
            let showScreenshots = request.paramBoolValue(name: "screenshots")
            
            let paramDict = request.queryParamsDict
            let queryParametersWithToggledScreenshots = paramDict.toggle(key: "screenshots").queryString()
            
            let screenshotLink = test.hasScreenshots() ? "<a href='/details/\(run.id)/\(suite.name)/\(test.name)\(queryParametersWithToggledScreenshots)'>\(showScreenshots ? "Hide screenshots" : "Show screenshots")</a>" : "&nbsp;"
            
            let queryParameters = paramDict.queryString()
            response.threeColumnsBody(leftColumn: "<a href='/\(queryParameters)'>Home</a><br /><a style='padding-left: 20px;' href='/details/\(run.id)\(queryParameters)'>\(run.displayName())</a><br /><a style='padding-left: 40px;' href='/details/\(run.id)/\(suite.name)\(queryParameters)'>\(suite.name)</a>",
                centerColumn: "&nbsp;",
                rightColumn: screenshotLink)
            
            response.appendBody(string: "<hr />")
            
            var diagnosticReportLink = ""
            if test.hasCrashed() {
                diagnosticReportLink = "<br /><a href='/diagnostic_report/\(run.id)/\(suite.name)/\(test.name)\(queryParameters)'>diagnostic report</a><br /><br />"
            }
            
            response.appendBody(string: "<h3>")
            if showErrorsOnly {
                response.threeColumnsBody(leftColumnLink: (test.previousFailed as? Test)?.name.appending(queryParameters),
                                          centerColumn: test.name + diagnosticReportLink,
                                          rightColumnLink: (test.nextFailed as? Test)?.name.appending(queryParameters))
            } else {
                response.threeColumnsBody(leftColumnLink: (test.previous as? Test)?.name.appending(queryParameters),
                                          centerColumn: test.name + diagnosticReportLink,
                                          rightColumnLink: (test.next as? Test)?.name.appending(queryParameters))
            }
            response.appendBody(string: "</h3>")
            
            var lastParentAction: TestAction? = nil
            var paddingLeft = 0
            
            let testActions = test.actions()

            let hasActions = testActions.count > 0
            if hasActions {
                for action in testActions {
                    let color = action.failed ? "red" : "green"
                    
                    if action.parentAction == nil {
                        lastParentAction = nil
                        paddingLeft = 0
                    } else if action.parentAction != lastParentAction {
                        lastParentAction = action.parentAction
                        paddingLeft += 20
                    }

                    let durationString = action.duration >= 0.01 ? "\(String(format: " %.2f", action.duration))s" : ""
                    
                    let attachmentPrefix = action.hasAttachment() ? (action.hasScreenshot() ?  "<b>🖼 " : "<b>🗃 ") : ""
                    let attachmentSuffix = action.hasAttachment() ? "</b>" : ""

                    response.appendBody(string: "<a href='/details/\(run.id)/\(suiteName)/\(test.name)/\(action.uuid)' style='color:\(color); padding-left: \(paddingLeft)px'>\(attachmentPrefix)\(action.name)\(attachmentSuffix)</a><font color=\"#ff9900\">\(durationString)</font><br>")

                    for attachment in action.attachments ?? [] {
                        switch attachment.type {
                        case .image:
                            if showScreenshots {
                                if !attachment.isAutomaticScreenshot {
                                    response.appendBody(string: "<br /><b>\(attachment.title)</b></br>")
                                }
                                response.appendBody(string: "<br /><a href='/static64/\(attachment.base64())'><img style='margin-top:-10px; padding-bottom:20px; padding-left: \(paddingLeft)px; width: 100px' src='/static64/\(attachment.base64())' /></a><br /><br />")
                            }
                        case .plist, .other:
                            response.appendBody(string: "<br /><a href='/static64/\(attachment.base64())'>\(attachmentPrefix)\(attachment.title)\(attachmentSuffix)</a><br /><br />")
                        case .crashlog, .text:
                            response.appendBody(string: "<br /><a href='/attachment/\(run.id)/\(suiteName)/\(test.name)/\(attachment.base64())'><b><font color=red>\(attachmentPrefix)\(attachment.title)\(attachmentSuffix)</font></b></a><br /><br />")
                        }
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
