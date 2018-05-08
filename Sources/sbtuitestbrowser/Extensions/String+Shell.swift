//
//  String+Shell.swift
//  TestListExtractor
//
//  Created by Tomas Camin on 12/12/2017.
//  Copyright © 2017 Tomas Camin. All rights reserved.
//

import Foundation

extension String {
    
    func shellExecute() -> String {
        let task = Process()
        
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", self]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
}
