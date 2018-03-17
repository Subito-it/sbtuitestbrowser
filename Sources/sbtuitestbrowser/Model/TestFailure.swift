//
//  TestFailure.swift
//  sbtuitestbrowser
//
//  Created by Tomas on 18/01/2017.
//
//

import Foundation

class TestFailure {
    
    let filePath: String
    let fileName: String
    let lineNumber: Int
    let message: String
    let performanceFailure: Bool
    let crash: Bool
    
    init(dict: [String : Any]) {
        filePath = dict["FileName"] as? String ?? ""
        let u = URL(string: filePath)
        fileName = u?.lastPathComponent ?? ""
        lineNumber = dict["LineNumber"] as? Int ?? 0
        message = dict["Message"] as? String ?? ""
        performanceFailure = dict["PerformanceFailure"] as? Bool ?? false
        crash = message.contains(string: " crashed in ")
    }
}
