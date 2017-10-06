//
// ParseRoute.swift
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
    
    public func parseHandler(request: HTTPRequest, _ response: HTTPResponse) {
        response.wrapDefaultFont() { [unowned self] in
            response.appendBody(string: "<a href='/'>Home</a>")
            response.appendBody(string: "<hr />")
            
            if self.parsingProgress < 1.0 {
                response.appendBody(string: "Parsing is already in progress")
            } else {
                response.appendBody(string: "Started parsing")
            }
        }
        
        response.completed()
        
        parseAll()
    }
    
    // MARK: - Private
    
    public func parseAll() {
        guard let baseFolderURL = baseFolderURL else {
            return
        }
        guard parsingProgress == 1.0 else {
            return
        }
        
        parsingProgress = 0.0
        
        var plists = plistFiles(baseFolderURL, matchSuffix: "_TestSummaries.plist")
        
        plists = plists.filter({ plist in
            if self.groupedPlists.contains(plist) {
                return false
            }

            for run in runs {
                if run.plistURL == plist {
                    return false
                }
            }
            return true
        })
        
        var lastRuns = runs
        
        DispatchQueue.global().async {
            // check if previous runs still exists
            let fileManager = FileManager.default
            
            lastRuns = lastRuns.filter {
                fileManager.fileExists(atPath: $0.plistURL.path)
            }
            
            let r = TestRun.parse(plists: plists, screenshotBaseURL: baseFolderURL) {
                partialResult, progress in
                
                self.runSyncQueue.async { [unowned self] in
                    self.runs.append(partialResult)
                    self.parsingProgress = progress
                }
            }
            
            self.runSyncQueue.async { [unowned self] in
                self.runs = lastRuns + r
                
                let groupRuns = true
                
                if groupRuns {
                    var runsToDelete = [TestRun]()
                    
                    for run in self.runs {
                        if runsToDelete.map({ $0.plistURL }).contains(run.plistURL) {
                            continue
                        }
                        
                        let groupableRuns = self.runs.filter { run.canBeGrouped(with: $0) }
                        if groupableRuns.count > 1 {
                            let runsDroppingFirst = groupableRuns.dropFirst()
                            for runInTheSameFolder in runsDroppingFirst {
                                runInTheSameFolder.suites.forEach { $0.parentRun = groupableRuns.first! }
                                
                                groupableRuns.first!.add(runInTheSameFolder.suites)
                            }
                            
                            runsToDelete += runsDroppingFirst
                            runsToDelete.forEach { self.groupedPlists.insert($0.plistURL) }
                        }
                    }
                    
                    self.runs = self.runs.filter { !runsToDelete.map({ $0.plistURL }).contains($0.plistURL) }
                }
                
                self.runs.sort(by: { lhs, rhs in
                    let lhsStartTime = lhs.suites.reduce(Double.greatestFiniteMagnitude, { min($0, $1.startTimeInterval()) })
                    let rhsStartTime = rhs.suites.reduce(Double.greatestFiniteMagnitude, { min($0, $1.startTimeInterval()) })
                    
                    return lhsStartTime > rhsStartTime
                })
                if groupRuns {
                    self.runs.forEach { $0.sortSuites() }
                }
                
                self.runs.listify()
                
                self.parsingProgress = 1.0
            }
        }
    }
    
    private func plistFiles(_ baseURL: URL?, matchSuffix: String) -> [URL] {
        guard let baseURL = baseURL else {
            return []
        }
        
        let fileManager = FileManager.default
        let keys = [URLResourceKey.isDirectoryKey, URLResourceKey.localizedNameKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsPackageDescendants, .skipsHiddenFiles]
        
        let enumerator = fileManager.enumerator(
            at: baseURL,
            includingPropertiesForKeys: keys,
            options: options,
            errorHandler: {(url, error) -> Bool in
                return true
        })
        
        var plistToProcess = [URL]()
        let foldersToSkip = ["ModuleCache", "Build", "Attachments"]
        while let file = enumerator?.nextObject() as? URL {
            if #available(OSX 10.11, *) {
                if file.hasDirectoryPath && foldersToSkip.contains(file.lastPathComponent) {
                    enumerator?.skipDescendants()
                }
            }
            
            if file.absoluteString.hasSuffix(matchSuffix) == true {
                plistToProcess.append(file)
            }
        }
        
        plistToProcess.sort { ( u1: URL, u2: URL) -> Bool in
            do {
                let values1 = try u1.resourceValues(forKeys: [.creationDateKey])
                let values2 = try u2.resourceValues(forKeys: [.creationDateKey])
                
                if let date1 = values1.creationDate, let date2 = values2.creationDate {
                    return date1.compare(date2) == ComparisonResult.orderedDescending
                }
            } catch {}
            
            return true
        }
        
        return plistToProcess
    }
}
