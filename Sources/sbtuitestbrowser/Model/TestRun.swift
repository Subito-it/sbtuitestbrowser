//
// TestRun.swift
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

class TestRun: ListItem, FailableItem, Equatable {
    let plistURL: URL
    let screenshotBasePath: String
    var id: String { return plistURL.lastPathComponent }
    var groupIdentifier: String?
    var branchName: String?
    var commitHash: String?
    var commitMessage: String?
    var codeCoveragePath: String?
    var repoBasePath: String?
    
    static var diagnosticReportDateFormatter: DateFormatter {
        let d = DateFormatter()
        d.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        return d
    }
    
    private(set) var deviceName: String = ""
    private(set) var suites = [TestSuite]()
    private(set) var coverage: TestCoverage?
    
    init(plistURL: URL, screenshotBaseURL: URL) {
        self.plistURL = plistURL
        
        let basePath = plistURL.deletingLastPathComponent().path
       
        self.screenshotBasePath = basePath.replacingOccurrences(of: screenshotBaseURL.path, with: "")
        super.init()
        self.parse()
    }
    
    static func parse(plists: [URL], screenshotBaseURL: URL, partialRun: @escaping (TestRun, Double) -> Void ) -> [TestRun] {
        var runs = [TestRun]()
        
        let synchQueue = DispatchQueue(label: "com.synch.parse")
        // parallel enumeration
        (plists as NSArray).enumerateObjects(options: .concurrent, using: { (obj, idx, stop) -> Void in
            autoreleasepool {
                let run = TestRun(plistURL: obj as! URL, screenshotBaseURL: screenshotBaseURL)
                
                synchQueue.async {
                    runs.append(run)
                    partialRun(run, Double(runs.count) / Double(plists.count))
                }
            }
        })
        
        return runs
    }
    
    public func displayName() -> String {
        switch (branchName, commitHash) {
        case (let branchName?, let commitHash?):
            return "[\(branchName)] \(commitHash) - \(deviceName)"
        case (let branchName?, _):
            return "[\(branchName)] - \(deviceName)"
        default:
            return "\(createdString()) - \(deviceName)"
        }
    }
    
    public func createdDate() -> Date? {
        let attr = try? FileManager.default.attributesOfItem(atPath: plistURL.path)
        
        return attr?[FileAttributeKey.modificationDate] as? Date
    }
    
    public func createdString() -> String {
        if let date = createdDate() {
            return DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
        }
        
        return ""
    }
    
    public func sortSuites() {
        self.suites.sort(by: { $0.name < $1.name })
    }
    
    public func groupSuites() {
        sortSuites()
        
        // Update parentRun
        for suite in self.suites {
            suite.parentRun = self
        }
        
        guard var lastSuite = self.suites.last else {
            return
        }
        for (indx, suite) in self.suites.dropLast().enumerated().reversed() {
            if suite.name == lastSuite.name {
                for test in suite.tests {
                    test.parentSuite = lastSuite
                }
                lastSuite.add(suite.tests)
                
                self.suites.remove(at: indx)
            } else {
                lastSuite = suite
            }
        }
        
        self.suites.listify()
    }
    
    public func canBeGrouped(with testRun: TestRun) -> Bool {
        guard let groupIdentifier = groupIdentifier else {
            return false
        }
        return deviceName == testRun.deviceName && groupIdentifier == testRun.groupIdentifier
    }
    
    public func add(_ suites: [TestSuite]) {
        var mSuites = self.suites + suites
        
        mSuites.sort(by: { $0.name < $1.name })
        mSuites.listify()
        
        self.suites = mSuites
    }
    
    public func totalTests(errorsOnly: Bool) -> Int {
        return suites.reduce(0) { $0 + $1.totalTests(errorsOnly: errorsOnly) }
    }
    
    public func totalSuites(errorsOnly: Bool) -> Int {
        if errorsOnly {
            return suites.filter({ $0.hasFailure() }).count
        } else {
            return suites.count
        }
    }
    
    public func totalDuration() -> TimeInterval {
        return suites.reduce(0) { $0 + $1.totalDuration() }
    }
    
    public func totalElapsedDuration() -> TimeInterval {
        return stopTimeInterval() - startTimeInterval()
    }
    
    public func startTimeInterval() -> TimeInterval {
        if totalTests(errorsOnly: false) == 0 {
            return createdDate()?.timeIntervalSinceReferenceDate ?? Date().timeIntervalSinceReferenceDate
        }

        return suites.reduce(Double.greatestFiniteMagnitude, { min($0, $1.startTimeInterval()) })
    }

    public func stopTimeInterval() -> TimeInterval {
        if totalTests(errorsOnly: false) == 0 {
            return createdDate()?.timeIntervalSinceReferenceDate ?? Date().timeIntervalSinceReferenceDate
        }
        
        return suites.reduce(0.0, { max($0, $1.stopTimeInterval()) })
    }
    
    public func suite(named: String) -> TestSuite? {
        return suites.first(where: { $0.name == named})
    }
    
    public func allTests() -> [Test] {
        var ret = [Test]()
        for suite in suites {
            ret += suite.tests
        }
        return ret
    }
    
    public func failingSuites() -> [TestSuite] {
        return suites.filter { $0.hasFailure() }
    }
    
    public func failingTests() -> [Test] {
        return suites.reduce([Test]()) { $0 + $1.failingTests() }
    }
    
    // MARK: - Private
    
    private func read(plist url: URL) -> [String : Any]? {
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml
        var plistData: [String: Any] = [:]
        guard let plistXML = try? Data(contentsOf: self.plistURL) else {
            return nil
        }
        
        do {
            plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListFormat) as! [String: Any]
        } catch {
            print("Error reading plist: \(error)")
            return nil
        }
        
        return plistData
    }
    
    private func parse() {
        guard let dict = read(plist: self.plistURL) else {
            fatalError("Failed to load dictionary")
        }

        guard extract(formatVersion: dict) == "1.2" else {
            fatalError("Unsupported format version, expected 1.2")
        }
        
        self.branchName = dict["BranchName"] as? String
        self.commitHash = dict["CommitHash"] as? String
        self.commitMessage = dict["CommitMessage"] as? String
        self.codeCoveragePath = dict["CodeCoverageFile"] as? String
        self.groupIdentifier = dict["GroupingIdentifier"] as? String
        self.repoBasePath = dict["RepoPath"] as? String
        
        let deviceName = extractSimulatorName(from: dict)
        let testsDict = extractTestableSummaries(from: dict)
        
        let runSuites = suites(from: testsDict).map {
            suite in
                autoreleasepool {
                    let suiteTests = tests(from: testsDict, suite: suite)
  
                    suite.add(suiteTests)
                    return suite
                }
            } as [TestSuite]
        
        self.add(runSuites)
        
        self.deviceName = deviceName
  
        self.coverage = TestCoverage(coveragePath: self.codeCoveragePath, parentRun: self)
        
        if let diagnosticReportPaths = dict["DiagnosticReports"] as? String {
            let url = self.plistURL.deletingLastPathComponent().appendingPathComponent(diagnosticReportPaths).standardized
            
            let findCmd = "find \(url.path) -name *.crash"
            let diagnosticReportUrls = findCmd.shellExecute().components(separatedBy: "\n").filter({ !$0.isEmpty }).flatMap { URL(fileURLWithPath: $0) }
            
            let diagnosticReportTimeIntervals = zip(diagnosticReportUrls, diagnosticReportUrls.map { self.diagnosticReportTimeInterval(at: $0)} )
            
            // Try to match diagnostic reports
            for test in self.allTests() {
                let start = test.startTimeinterval
                let stop = test.stopTimeinterval
                
                for diagnosticReportTimeInterval in diagnosticReportTimeIntervals {
                    if (diagnosticReportTimeInterval.1 > start) && (diagnosticReportTimeInterval.1 < stop + 1.0) {
                        test.diagnosticReportUrl = diagnosticReportTimeInterval.0
                    }
                }
            }
        }
    }
    
    private func diagnosticReportTimeInterval(at url: URL) -> TimeInterval {
        guard let report = try? String(contentsOf: url, encoding: .utf8) else {
            return 0
        }
        
        let dateMarker = "Date/Time:"
        let lines = report.split(separator: "\n")
        let dateLine = lines.first(where: { $0.contains(dateMarker) })
        if let dateString = dateLine?.replacingOccurrences(of: dateMarker, with: "").trimmingCharacters(in: .whitespacesAndNewlines),
            let date = TestRun.diagnosticReportDateFormatter.date(from: dateString) {
            let diagnosticReportTimeInterval = date.timeIntervalSinceReferenceDate
            
            return diagnosticReportTimeInterval
        }
        
        return 0
    }
    
    private func suites(from dicts: [[String : Any]]) -> [TestSuite] {
        var ret = Set<TestSuite>()
        dicts.forEach { ret.insert(TestSuite(dict: $0, parentRun: self)) }
        
        return Array(ret)
    }
    
    private func tests(from dicts: [[String : Any]], suite: TestSuite) -> [Test] {
        var ret = [Test]()
        
        dicts.filter({ $0["ParentTestName"] as! String == suite.name }).forEach {
            testDict in
            
            let test = Test(dict: testDict, parentSuite: suite)
            
            ret.append(test)
        }
        
        return ret
    }
    
    private func extract(formatVersion dict: [String : Any]?) -> String {
        guard let formatVersion = dict?["FormatVersion"] as? String else {
            fatalError("No FormatVersion?")
        }
        
        return formatVersion
    }
    
    private func extractSimulatorName(from dict: [String : Any]?) -> String {
        guard let dict = dict?["RunDestination"] as? [String : Any] else {
            fatalError("No RunDestination?")
        }
        guard let targetDevice = dict["TargetDevice"] as? [String : Any] else {
            fatalError("Unsupported RunDestination format, TargetDevice")
        }
        guard let localComputer = dict["LocalComputer"] as? [String : Any] else {
            fatalError("Unsupported RunDestination format, LocalComputer")
        }
        guard let targetSDK = dict["TargetSDK"] as? [String : Any] else {
            fatalError("Unsupported RunDestination format, TargetSDK")
        }
        guard let modelName = targetDevice["ModelName"] as? String else {
            fatalError("Unsupported RunDestination format, TargetSDK")
        }
        guard let modelVersion = targetDevice["OperatingSystemVersion"] as? String else {
            fatalError("Unsupported RunDestination format, TargetSDK")
        }

        _ = localComputer["suppresswarning"]
        _ = targetSDK["suppresswarning"]
        
        // for the time being we just extract the device name
        return "\(modelName) (\(modelVersion))"
    }
    
    private func extractTestableSummaries(from dict: [String : Any]?) -> [[String : Any]] {
        func extract(subTestLeafes dict: [String : Any]?, parent: [String : Any]?) -> [[String : Any]] {
            guard var dict = dict else {
                return []
            }
            var ret = [[String : Any]]()
            if let subtests = dict["Subtests"] as? [[String : Any]] {
                subtests.forEach { ret += extract(subTestLeafes: $0, parent: dict) }
            } else {
                dict["ParentTestName"] = parent?["TestName"]
                return [dict]
            }
            
            return ret
        }
        
        guard let summaries = dict?["TestableSummaries"] as? [[String : Any]] else {
            fatalError("No TestableSummaries?")
        }
        
        assert(summaries.count == 1) // we support just one here
        
        guard let tests = summaries.first?["Tests"] as? [[String : Any]]  else {
            fatalError("No Tests in TestableSummaries?")
        }
        
        assert(tests.count < 2) // we support just one here
        
        if tests.count == 0 {
            return []
        }
        
        return extract(subTestLeafes: tests.first!, parent: nil)
    }
    
    // MARK: - Protocols
    
    func hasFailure() -> Bool {
        return suites.reduce(false) { $0 || $1.hasFailure() }
    }
    
    func hasCrashed() -> Bool {
        return suites.reduce(false) { $0 || $1.hasCrashed() }
    }

    var hashValue: Int { return plistURL.hashValue }
    
    static func ==(lhs: TestRun, rhs: TestRun) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Array where Element: TestRun {
    func frequentlyFailingTests(minRunsForFrequentFail: Int) -> [Test] {
        func cleanupName(action: TestAction?) -> String? {
            guard let action = action else {
                return nil
            }
            let actionName = action.name
            let regex = try? NSRegularExpression(pattern: "<XC.*>", options: .caseInsensitive)
            let range = NSMakeRange(0, actionName.count)
            
            return regex?.stringByReplacingMatches(in: actionName, options: [], range: range, withTemplate: "")
        }
        
        var frequentFailingTests = [Test]()
        
        outer: for failingTest0 in self[0].failingTests() {
            guard let failingTestAction0 = cleanupName(action: failingTest0.firstFailingAction()) else {
                continue
            }
            
            for i in 1..<minRunsForFrequentFail {
                if let failingTestI = self[i].failingTests().first(where: { $0 == failingTest0 }) {
                    guard let failingTestActionI = cleanupName(action: failingTestI.firstFailingAction()) else {
                        continue
                    }
                    
                    if failingTestAction0 == failingTestActionI {
                        continue
                    }
                }
                continue outer
            }
            frequentFailingTests.append(failingTest0)
        }
        
        return frequentFailingTests
    }
}
