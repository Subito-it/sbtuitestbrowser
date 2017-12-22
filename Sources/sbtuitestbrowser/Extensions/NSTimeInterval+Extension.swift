//
//  NSTimeInterval+Extension.swift
//  sbtuitestbrowser
//
//  Created by Tomas Camin on 23/03/2017.
//
//

import Foundation

extension TimeInterval {
    
    private func hoursMinutesSeconds() -> (Int, Int, Int) {
        let seconds = Int(self)
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func durationString() -> String {        
        let (h, m, s) = hoursMinutesSeconds()
        
        var ret = ""
        
        if h > 0 {
            ret += "<font color=\"#f02e0f\">\(h)h</font> "
        }
        if m > 0 || ret.count > 0 {
            ret += "<font color=\"#ff772c\">\(m)m</font> "
        }
        ret += "<font color=\"#ffbb44\">\(s)s</font>"

        return ret
    }
}
