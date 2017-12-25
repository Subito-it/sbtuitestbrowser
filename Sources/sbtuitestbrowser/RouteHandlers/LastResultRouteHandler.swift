//
// LastResultRouteHandler.swift
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
    
    public func lastResultHandler(request: HTTPRequest, _ response: HTTPResponse) {
        defer {
            response.completed()
        }
        
        guard let lastRun = runs.first else {
            _ = try? response.setBody(json: [:])
            return
        }
        
        let totalTests = lastRun.totalTests(errorsOnly: false)
        let totalErrors = lastRun.totalTests(errorsOnly: true)
        let successfulTests = totalTests - totalErrors
        
        _ = try? response.setBody(json: ["total_success": successfulTests, "total_errors": totalErrors, "total_tests": totalTests, "url": "/details/\(lastRun.id)"])
    }
}
