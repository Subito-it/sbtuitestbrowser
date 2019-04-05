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
        let inlineScreenshots = request.paramBoolValue(name: "screenshots")
        let targetActionUuid = request.urlVariables["actionuuid"] ?? ""
        
        let paramDict = request.queryParamsDict
        let queryParameters = paramDict.queryString()
        
        let queryParametersWithToggledScreenshots = paramDict.toggle(key: "screenshots").queryString()

        guard let run = self.runs.first(where: { $0.id == runPlist }),
            let suite = run.suites.first(where: { $0.name == suiteName }),
            let test = suite.test(named: testName) else {
                response.appendBody(string: h3("Error! TestRoute #1"))
                response.completed()
                return
        }
        
        let testDescription = test.name.dropLast(2)
        
        let htmlPage = HTMLPage(title: "UI Test Browser - \(testDescription)")
        
        htmlPage.div(id: "header") {
            htmlPage.div(class: "centered") {
                htmlPage.button("Home", link: "/\(queryParameters)")
                htmlPage.append(body: "・&nbsp;")
                htmlPage.button("Run summary", link: "/details/\(run.id)\(queryParameters)")
                htmlPage.append(body: "・&nbsp;")
                htmlPage.button("Suite summary", link: "/details/\(run.id)/\(suite.name)\(queryParameters)")
            }
            
            htmlPage.div(class: "centered") {
                if test.hasScreenshots() {
                    let screenshotButtonClass = inlineScreenshots ? "button_selected" : "button_deselected"
                    htmlPage.button("Inline screenshots", link: "/details/\(run.id)/\(suite.name)/\(test.name)\(queryParametersWithToggledScreenshots)", class: screenshotButtonClass)
                }
                if test.diagnosticReportUrl != nil {
                    htmlPage.button("Diagnostic report", link: "/diagnostic_report/\(run.id)/\(suite.name)/\(test.name)\(queryParameters)")
                }
            }
        }
        
        htmlPage.div(id: "header-padding")
        htmlPage.append(body: """
                    <script>
                        $('#header-padding').css('height', $('#header').outerHeight());
                        $('#fixed_screenshot').css('top', $('#header').outerHeight());
                    </script>
                """)
        
        if inlineScreenshots == false && test.hasScreenshots() {
            htmlPage.append(body: """
                        <script>
                            $(window).on('resize', function() {
                                const minActionWidth = 600;
                                const minScreenshotWidth = 150;
                                const maxScreenshotWidth = 400;
                                
                                if ($(window).width() > minActionWidth + minScreenshotWidth) {
                                    var screenshotWidth = Math.min(maxScreenshotWidth, $(window).width() - minActionWidth);
                                    
                                    $('#actions').css('width', $(window).width() - screenshotWidth);
                                    $('#fixed_screenshot').css('width', screenshotWidth);
                                } else {
                                    $('#actions').css('width', $(window).width());
                                    $('#fixed_screenshot').css('width', '0px');
                                }
                            } );

                            $(document).ready(function() {
                                $(window).resize();

                                const steps = $("div.step");
                                const stepLefts = steps.map(function() { return $(this).offset().left; });
                                const stepTops = steps.map(function() { return $(this).offset().top; });
                                const stepHeights = steps.map(function() { return $(this).height(); });
                                const stepWidths = steps.map(function() { return $(this).width(); });
                                const stepRights = stepLefts.map(function (idx, num) {
                                    return num + stepWidths[idx];
                                });
                                const stepBottoms = stepTops.map(function (idx, num) {
                                    return num + stepHeights[idx];
                                });

                                var xMousePos = 0;
                                var yMousePos = 0;
                                var lastScrolledLeft = 0;
                                var lastScrolledTop = 0;
                                var lastStepIndx = 0;

                                $(document).mousemove(function(event) {
                                    captureMousePosition(event);
                                    
                                    updateScreenshotAtIndex(stepIndexAtMousePosition(xMousePos, yMousePos));
                                })

                                $(window).scroll(function(event) {
                                    if (lastScrolledLeft != $(document).scrollLeft()) {
                                        xMousePos -= lastScrolledLeft;
                                        lastScrolledLeft = $(document).scrollLeft();
                                        xMousePos += lastScrolledLeft;
                                    }
                                    if (lastScrolledTop != $(document).scrollTop()) {
                                        yMousePos -= lastScrolledTop;
                                        lastScrolledTop = $(document).scrollTop();
                                        yMousePos += lastScrolledTop;
                                    }

                                    updateScreenshotAtIndex(stepIndexAtMousePosition(xMousePos, yMousePos));
                                });

                                function stepIndexAtMousePosition(x, y) {
                                    // could be improved by using a binary search
                                    for (var i = 0, len = steps.length; i < len; i++) {
                                        if (x > stepLefts[i] && x < stepRights[i] && y > stepTops[i] && y < stepBottoms[i]) {
                                            if (lastStepIndx != i) {
                                                lastStepIndx = i;
                                                return i;
                                            }
                                            return -1;
                                        }
                                    }

                                    return -1;
                                }

                                function captureMousePosition(event) {
                                    xMousePos = event.pageX;
                                    yMousePos = event.pageY;
                                }

                                function updateScreenshotAtIndex(i) {
                                    if (i < 0) {
                                        return;
                                    }

                                    steps.each(function(indx) {
                                        if (indx == i) {
                                            $(this).addClass("bold");
                                            
                                            var href = $(this).find('a').slice(0,1).attr('href');

                                            var screenshotBody = `<a href="${href}"><img style="width: 100%" src="${href}"></a>`
                                            if ($("#fixed_screenshot").html() != screenshotBody) {
                                                $("#fixed_screenshot").html(screenshotBody);
                                            }
                                        } else {
                                            $(this).removeClass("bold");
                                        }
                                    });
                                }
                            });
                        </script>
                    """)
        }
        
        htmlPage.append(body: """
            <div class='separator'>
            <b>\(testDescription)</b> (\(Int(test.duration))s)
            </div>
            """)
        
        htmlPage.append(body: "<div id='fixed_screenshot'></div>")
        htmlPage.append(body: "<div id='actions'>")
        
        let testActions = test.actions()
        
        var lastParentAction: TestAction? = nil
        var paddingLeft = 0
        var currentTime: TimeInterval = 0.0
        
        let firstAttachment = testActions.lazy.compactMap { self.automaticScreenshot(for: $0, in: testActions) }.first
        
        let hasActions = testActions.count > 0
        if hasActions {
            for action in testActions {
                if action.parentAction == nil {
                    lastParentAction = nil
                    paddingLeft = 0
                } else if action.parentAction != lastParentAction {
                    lastParentAction = action.parentAction
                    paddingLeft += 20
                }

                let currentTimeString = String(format: "%.2f", currentTime) + "s&nbsp;"
                currentTime += action.duration
                
                let durationString = action.duration >= 0.01 ? "(\(String(format: "%.2f", action.duration))s)" : ""
                
                htmlPage.div(id: "", class: "item step") {
                    if let attachment = self.automaticScreenshot(for: action, in: testActions), firstAttachment != nil {
                        htmlPage.inlineBlock("<a href='/static64/\(attachment.base64())'></a>", class: "hidden screenshot")
                    }
                    
                    htmlPage.inlineBlock(currentTimeString, class: "green")
                    htmlPage.inlineBlock("", width: paddingLeft)
                    
                    if (action.subActions.count > 0) {
                        htmlPage.inlineBlock(HTMLPage.Icons.triangleDown)
                    }
                    
                    htmlPage.inlineBlock("\(action.name) \(durationString)", class: action.failed ? "red bold" : "")
                    
                    if let attachments = action.attachments, attachments.count > 0 {
                        for attachment in attachments {
                            switch attachment.type {
                            case .image:
                                htmlPage.inlineBlock(HTMLPage.Icons.eye)
                            case .crashlog:
                                htmlPage.inlineBlock(HTMLPage.Icons.crash)
                            case .text:
                                htmlPage.inlineBlock(HTMLPage.Icons.text)
                            case .plist, .other:
                                htmlPage.inlineBlock(HTMLPage.Icons.attachment)
                            }
                            
                            switch attachment.type {
                            case .image:
                                if inlineScreenshots {
                                    htmlPage.newline()
                                    if !attachment.isAutomaticScreenshot {
                                        htmlPage.inlineBlock(attachment.title, class: "bold")
                                        htmlPage.newline()
                                    }
                                                                        
                                    htmlPage.inlineBlock("<a href='/static64/\(attachment.base64())'><img style='padding-top: 10px; width: 25%' src='/static64/\(attachment.base64())' /></a>")
                                    
                                    htmlPage.newline()
                                    htmlPage.newline()
                                }
                            case .crashlog, .text:
                                htmlPage.inlineBlock("<a href='/attachment/\(run.id)/\(suiteName)/\(test.name)/\(targetActionUuid)/\(attachment.base64())'>\(attachment.title)</b></a>", class: "red bold")
                            case .plist, .other:
                                htmlPage.inlineBlock("<a href='/attachment/\(run.id)/\(suiteName)/\(test.name)/\(targetActionUuid)/\(attachment.base64())'>\(attachment.title)</a>", class: "red bold")
                            }
                        }
                    }
                }
            }
        } else {
            for failure in test.failures {
                htmlPage.newline()
                htmlPage.div(id: "", class: "item step") {
                    htmlPage.inlineBlock("Failure in file \(failure.filePath):\(failure.lineNumber), \(failure.message)", class: "red")
                }
            }
        }
        
        htmlPage.append(body: "</div>")

        response.appendBody(string: htmlPage.html())
        
        response.completed()
    }
    
    private func automaticScreenshot(for selectedAction: TestAction, in testActions: [TestAction]) -> TestAttachment? {
        var screenshot: TestAttachment? = nil
        
        for action in testActions {
            if let actionScreenshot = action.attachments?.compactMap({ $0 }).first(where: { $0.type == .image && $0.isAutomaticScreenshot }) {
               screenshot = actionScreenshot
            }
            
            if action == selectedAction {
                return screenshot
            }
        }
        
        return nil
    }
}
