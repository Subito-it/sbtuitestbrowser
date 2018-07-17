//
//  TemplateTestCase.swift
//  sbtuitestbrowser
//
//  Created by Tomas Camin on 05/07/2018.
//

import Foundation

class HTMLPage {
    private let title: String
    private var body = ""
    
    init(title: String) {
        self.title = title
    }
    
    func append(body: String) {
        self.body += body
    }
    
    func button(_ button: String, link: String, id: String? = nil, `class`: String = "button_deselected") {
        var idTag = ""
        if let id = id {
            idTag = "id='\(id)'"
        }
        body += "<a href='\(link)' \(idTag) class='\(`class`)'>\(button)</a>"
    }
    
    func div(id: String = "", `class`: String = "", content: (() -> Void)? = nil) {
        body += "<div class='\(`class`)'"
        if id.count > 0 {
            body += " id='\(id)'"
        }
        body += ">"
        content?()
        body += "</div>"
    }
    
    func inlineBlock(_ inlineBlock: String, `class`: String? = nil, width: Int? = nil) {
        var style = "display:inline-block;"
        if let width = width {
            style += "width:\(width)px;"
        }

        body += "<div class='\(`class` ?? "")' style='\(style)'>\(inlineBlock)&nbsp;</div>\n"
    }
    
    func newline() {
        body += "<br/>\n"
    }
    
    func html() -> String {
        return "<html>\(HTMLPage.head(title: title))<body>\(body)</body></html>"
    }
}
