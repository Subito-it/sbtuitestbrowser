//
//  TestCoverage.swift
//  sbtuitestbrowser
//
//  Created by Tomas Camin on 18/03/2018.
//

import Foundation

class TestCoverage {
    public typealias CoverageItem = (coveragePercentage: Int, filePath: String, shortFilePath: String)
    
    unowned var parentRun: TestRun
    
    private(set) var coveragePath: String
    private(set) var json: [String: Any]
    
    init?(coveragePath: String?, parentRun: TestRun) {
        guard let coveragePath = coveragePath else {
            return nil
        }
        self.coveragePath = coveragePath
        self.parentRun = parentRun
        
        let coverageUrl = URL(fileURLWithPath: self.coveragePath)
        guard let json = (try? JSONSerialization.jsonObject(with: Data(contentsOf: coverageUrl))) as? [String: Any] else {
            return nil
        }
        self.json = json
    }
    
    private func fileListFindCommonPathComponent(coverageFiles: [CoverageItem]) -> String {
        let filePathComponents = coverageFiles.map { $0.shortFilePath.filePathComponents }
        
        for filePathComponent in filePathComponents {
            for (indx, _) in filePathComponents.enumerated() {
                for filePathComponent2 in filePathComponents {
                    
                    if indx > filePathComponent2.count || filePathComponent2[indx] != filePathComponent[indx] {
                        let separator = filePathComponents.first?.first ?? "/"
                        return filePathComponents.first?
                            .prefix(upTo: indx)
                            .joined(separator: separator)
                            .replacingOccurrences(of: separator + separator, with: separator) ?? ""
                    }
                }
            }
        }
        
        return ""
    }
    
    public func fileList() -> [CoverageItem] {
        guard let datas = self.json["data"] as? [Any],
              let data = datas.first as? [String: Any],
              let files = data["files"] as? [[String: Any]] else {
            return []
        }
        
        var coverageFiles = [CoverageItem]()
        for file in files {
            guard let filePath = file["filename"] as? String,
                  let summary = file["summary"] as? [String: Any],
                  let lines = summary["lines"] as? [String: Any],
                  let coveragePercentage = lines["percent"] as? Int else {
                continue
            }
            
            let item = CoverageItem(coveragePercentage: coveragePercentage, filePath: filePath, shortFilePath: filePath)
            coverageFiles.append(item)
        }

        // Remove common part from path
        let pathToRemove = fileListFindCommonPathComponent(coverageFiles: coverageFiles)
        
        return coverageFiles.map { item in
            return CoverageItem(coveragePercentage: item.coveragePercentage, filePath: item.filePath, shortFilePath: item.filePath.replacingOccurrences(of: pathToRemove, with: ""))
        }
    }
    
    public func totalCoverage() -> Int {
        guard let datas = self.json["data"] as? [Any],
              let data = datas.first as? [String: Any],
              let totals = data["totals"] as? [String: Any],
              let totalLines = totals["lines"] as? [String: Any],
              let totalCoverage = totalLines["percent"] as? Int else {
            return 0
        }

        return totalCoverage
    }
    
    public func totalCoverage(filename: String) -> Int {
        guard let datas = self.json["data"] as? [Any],
            let data = datas.first as? [String: Any],
            let files = data["files"] as? [[String: Any]] else {
                return 0
        }
        
        for file in files {
            guard let fn = file["filename"] as? String, fn == filename,
                  let summary = file["summary"] as? [String: Any],
                  let lines = summary["lines"] as? [String: Any],
                  let covered = lines["percent"] as? Int else {
                continue
            }
            
            return covered
        }
        
        return 0
    }
    
    public func coveredLines(filename: String) -> Set<Int> {
        guard let datas = self.json["data"] as? [Any],
              let data = datas.first as? [String: Any],
              let files = data["files"] as? [[String: Any]] else {
            return []
        }
        
        for file in files {
            guard let fn = file["filename"] as? String, fn == filename,
                  let segments = file["segments"] as? [[Int]] else {
                continue
            }
            
            var coveredLines = [Int]()
            var previousRegion = -1
            for segment in segments {
                guard segment.count == 5 else {
                    assert(false, "Unexpected segment counts")
                    return []
                }
                let line = segment[0] - 1
                let isCovered = (segment[2] > 0)
                let isRegionEntry = (segment[4] == 1)
                if isRegionEntry {
                    if previousRegion == -1 && isCovered {
                        previousRegion = line
                    }
                    continue
                }
                
                if previousRegion > -1 {
                    coveredLines += Array(previousRegion...line)
                    previousRegion = -1
                } else if isCovered {
                    coveredLines.append(line)
                }
            }

            return Set(coveredLines)
        }
        
        return Set()
    }
}
