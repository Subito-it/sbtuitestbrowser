//
//  TimeInterval+String.swift
//  sbtuitestbrowser
//
//  Created by Tomas Camin on 29/12/2017.
//

import Foundation

extension TimeInterval {
    func formattedString() -> String {
        let ms = Int(truncatingRemainder(dividingBy: 1) * 1000)
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.hour, .minute, .second]
        
        let formattedString = formatter.string(from: self)! + ".\(ms)"
        
        return String(formattedString.dropFirst(2))
    }
}
