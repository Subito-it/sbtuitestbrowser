//
// ResultsRouteHandler.swift
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
    
    public func resultsHandler(request: HTTPRequest, _ response: HTTPResponse) {
        defer {
            response.completed()
        }
        
        var results = [[String: Any]]()
        
        for result in runs {
            let totalTests = result.totalTests(errorsOnly: false)
            let totalErrors = result.totalTests(errorsOnly: true)
            let successfulTests = totalTests - totalErrors
            
            results.append(["total_success": successfulTests,
                            "total_errors": totalErrors,
                            "total_tests": totalTests,
                            "branch": result.branchName ?? "",
                            "device": result.deviceName,
                            "is_crashed": result.hasCrashed(),
                            "has_failure": result.hasFailure(),
                            "commit_hash": result.commitHash ?? "",
                            "commit_message": result.commitMessage ?? "",
                            "url": "/details/\(result.id)"])
        }
        
        _ = try? response.setBody(json: results)
    }
}
