//
//  FileLineReader.swift
//  sbtuitestbrowser
//
//  Created by tomas on 05/04/2019.
//

import Foundation

class FileReader {
    var size: Int
    
    private let handle: UnsafeMutablePointer<FILE>?
    
    typealias Line = (text: String?, startOffset: Int, endOffset: Int)
    
    init(path: String?, initialOffset: Int = 0) throws {
        guard let path = path
            , let handle = fopen(path, "r") else {
            throw NSError(domain: "FilePathNotFound", code: 404, userInfo: nil)
        }
        
        self.handle = handle
        fseek(handle, 0, SEEK_END)
        self.size = ftell(handle)
        
        fseek(handle, initialOffset, 0)
    }
        
    func nextLine() -> Line? {
        var line: UnsafeMutablePointer<CChar>? = nil
        defer { free(line) }

        let startOffset = ftell(handle)
        var bufferSize: Int = 0
        let lineSize = getline(&line, &bufferSize, handle)
        let endOffset = ftell(handle)

        guard lineSize > 0 else { return nil }

        return (text: String(cString: line!), startOffset: startOffset, endOffset: endOffset)
    }
    
    func string(starting sOffset: Int, ending eOffset: Int) -> String {
        guard eOffset > sOffset else { return ""}
        
        fseek(handle, sOffset, 0)
        
        let size = eOffset - sOffset
        
        let buffer: UnsafeMutablePointer<UInt8> = UnsafeMutablePointer.allocate(capacity: size)
        defer { buffer.deallocate() }

        let count: Int = fread(buffer, 1, size, handle)
        if ferror(handle) == 0, count > 0 {
            let data = Data(bytes: buffer, count: size)
            return String(data: data, encoding: String.Encoding.utf8) ?? ""
        }
        
        return ""
    }
    
    deinit {
        fclose(handle)
    }
}
