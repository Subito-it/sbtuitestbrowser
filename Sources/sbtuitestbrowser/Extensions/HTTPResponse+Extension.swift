//
// HTTPResponse+Extension.swift
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

extension HTTPResponse {
    
    func wrapDefaultFont(block: () -> Void) {
        appendBody(string: "<html><meta charset='utf-8' /><body>")
        appendBody(string: "<div style='font-family: Menlo; font-size: 12px;'>")
        block()
        appendBody(string: "</div>")
        appendBody(string: "<br /><br />")
        appendBody(string: "</body></html>")
    }

    func threeColumnsBody(leftColumnLink: String?, centerColumn: String, rightColumnLink: String?) {
        threeColumnsBody(leftColumn: leftColumnLink != nil ? "<a style='color: inherit;' href='\(leftColumnLink!)'><</a>" : nil,
                         centerColumn: centerColumn,
                         rightColumn: rightColumnLink != nil ? "<a style='color: inherit;' href='\(rightColumnLink!)'>></a>" : nil)
    }
    
    func threeColumnsBody(leftColumn: String?, centerColumn: String, rightColumn: String?) {
        // left col
        appendBody(string: "<div style='float: left; width: 30%'>&nbsp;")
        if let leftColumn = leftColumn {
            appendBody(string: leftColumn)
        }
        appendBody(string: "</div>")
        
        // center col
        appendBody(string: "<div style='display: inline-block; width: 40%; text-align: center'>\(centerColumn)</div>")
        
        // left col
        appendBody(string: "<div style='float: right; width: 30%; text-align:right'>")
        if let rightColumn = rightColumn {
            appendBody(string: rightColumn)
        }
        appendBody(string: "&nbsp;</div>")
        appendBody(string: "<div style='clear:both;'></div>")
    }
}
