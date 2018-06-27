//
// TestActionRouteHandler.swift
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
    
    public func testActionHandler(request: HTTPRequest, _ response: HTTPResponse) {
        let runPlist = request.urlVariables["runplist"] ?? ""
        let suiteName = request.urlVariables["suitename"] ?? ""
        let testName = request.urlVariables["testname"] ?? ""
        let targetActionUuid = request.urlVariables["actionuuid"] ?? ""

        guard let run = self.runs.first(where: { $0.id == runPlist }),
              let suite = run.suites.first(where: { $0.name == suiteName }),
              let test = suite.test(named: testName) else {
            response.appendBody(string: h3("Error! TestRoute #1"))
            response.completed()
            return
        }
        
        let testActions = test.actions()
    
        guard let targetAction = testActions.first(where: { $0.uuid == targetActionUuid }) else {
            response.appendBody(string: h3("Error! TestRoute #2"))
            response.completed()
            return
        }
        
        var previousAction: TestAction?
        var nextAction: TestAction?
        var lastParentAction: TestAction?
        var paddingLeft = 0
        var actionFound = false
        var selectedSubactions = [(TestAction, Int)]() // (action, padding)
        
        for action in testActions {
            if actionFound {
                if targetAction.attachments?.count != 0 || nextAction?.attachments?.count != 0 {
                    nextAction = action
                    break
                }
                nextAction = action
            }
            
            if action.parentAction == nil {
                lastParentAction = nil
                paddingLeft = 0
            } else if action.parentAction != lastParentAction {
                lastParentAction = action.parentAction
                paddingLeft += 20
            }
            selectedSubactions.append((action, paddingLeft))
            
            if action == targetAction {
                actionFound = true
            }
            
            if action.attachments?.count != 0 {
                if !actionFound {
                    previousAction = action
                    selectedSubactions.removeAll()
                }
            }
        }
        
        let minPadding = selectedSubactions.reduce(Int.max) { min($0, $1.1) }
        selectedSubactions = selectedSubactions.map { ($0.0, $0.1 - minPadding) }
        
        response.wrapDefaultFont() {
            let paramDict = request.queryParamsDict
            
            let queryParameters = paramDict.queryString()
            response.threeColumnsBody(leftColumn: "<a href='/\(queryParameters)'>Home</a><br /><a style='padding-left: 20px;' href='/details/\(run.id)\(queryParameters)'>\(run.displayName())</a><br /><a style='padding-left: 40px;' href='/details/\(run.id)/\(suite.name)\(queryParameters)'>\(suite.name)</a><br /><a style='padding-left: 60px;' href='/details/\(run.id)/\(suite.name)/\(test.name)\(queryParameters)'>\(test.name)</a>",
                centerColumn: "&nbsp;",
                rightColumn: "&nbsp;")
            
            response.appendBody(string: "<hr />")
            
            response.appendBody(string: "<h3>")

            let targetActionStart = targetAction.startTimeinterval - test.startTimeinterval
            let progess = "\(targetActionStart.formattedString()) - \(test.duration.formattedString())"
            response.threeColumnsBody(leftColumnLink: previousAction?.uuid.appending(queryParameters),
                                      centerColumn: progess,
                                      rightColumnLink: nextAction?.uuid.appending(queryParameters))
            response.appendBody(string: "</h3>")
            
            for (action, paddingLeft) in selectedSubactions {
                let color = action.failed ? "red" : "green"
                
                let durationString = action.duration >= 0.01 ? "\(String(format: " %.2f", action.duration))s" : ""
                
                response.appendBody(string: "<a href='#' style='color:\(color); padding-left: \(paddingLeft)px'>\(action.name)</a><font color=\"#ff9900\">\(durationString)</font><br>")
            }
            
            let attachmentPrefix = "<b>🗃 "
            let attachmentSuffix = "</b>"
            
            for attachment in selectedSubactions.last?.0.attachments ?? [] {
                switch attachment.type {
                case .image:
                    if !attachment.isAutomaticScreenshot {
                        response.appendBody(string: "<br /><b>\(attachment.title)</b></br>")
                    }
                    response.appendBody(string: "<br /><br /><a href='/static64/\(attachment.base64())'><img style='margin-top:-10px; padding-bottom:20px; width: 25%' src='/static64/\(attachment.base64())' /></a><br /><br />")
                case .plist, .other:
                    response.appendBody(string: "<br /><br /><a href='/static64/\(attachment.base64())'><b>\(attachmentPrefix)\(attachment.title)\(attachmentSuffix)</b></a><br /><br />")
                case .crashlog, .text:
                    response.appendBody(string: "<br /><br /><a href='/attachment/\(run.id)/\(suiteName)/\(test.name)/\(targetActionUuid)/\(attachment.base64())'><b><font color=red>\(attachmentPrefix)\(attachment.title)\(attachmentSuffix)</font></b></a><br /><br />")
                }
            }
        }
        
        response.completed()
    }
}
