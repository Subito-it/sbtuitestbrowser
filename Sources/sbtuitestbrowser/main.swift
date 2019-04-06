//
//  main.swift
//  PerfectTemplate
//
//  Created by Kyle Jessup on 2015-11-05.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import Foundation

let version = "1.0.5"

var baseFolderURL: URL?

for argument in CommandLine.arguments.dropFirst() {
    let path = NSString(string: argument).expandingTildeInPath
    baseFolderURL = URL(fileURLWithPath: path)
}
guard let baseFolderURL = baseFolderURL else {
    print("sbtuitestbrowser \(version)\n\nMissing basefolder!")
    exit(-1)
}

Test.resetActionCache()

// Create server object.
let server = HTTPServer()

server.serverPort = 8090

var routes = Routes()
var routeHandler = RouteHandler(baseFolderURL: baseFolderURL)
routeHandler.parseAll()

routes.add(method: .get, uri: "/", handler: routeHandler.homeHandler)
routes.add(method: .get, uri: "/reset", handler: routeHandler.resetHandler)
routes.add(method: .get, uri: "/version", handler: routeHandler.versionHandler)
routes.add(method: .get, uri: "/teststats", handler: routeHandler.testStatsHandler)
routes.add(method: .get, uri: "/status", handler: routeHandler.statusHandler)
routes.add(method: .get, uri: "/results", handler: routeHandler.resultsHandler)
routes.add(method: .get, uri: "/parse", handler: routeHandler.parseHandler) 
routes.add(method: .get, uri: "/details/{runplist}", handler: routeHandler.runHandler)
routes.add(method: .get, uri: "/details/{runplist}/{suitename}", handler: routeHandler.suiteHandler)
routes.add(method: .get, uri: "/details/{runplist}/{suitename}/{testname}", handler: routeHandler.testHandler)
routes.add(method: .get, uri: "/coverage/{runplist}", handler: routeHandler.coverageHomeHandler)
routes.add(method: .get, uri: "/coverage/{runplist}/{filepath}", handler: routeHandler.coverageFileHandler)
routes.add(method: .get, uri: "/diagnostic_report/{runplist}/{suitename}/{testname}", handler: routeHandler.diagnosticReportHandler)
routes.add(method: .get, uri: "/attachment/{runplist}/{suitename}/{testname}/{attachmentpath}", handler: routeHandler.attachmentHandler)
routes.add(method: .get, uri: "/attachment/{runplist}/{suitename}/{testname}/{actionuuid}/{attachmentpath}", handler: routeHandler.attachmentHandler)

routes.add(method: .get, uri: "/static/**", handler: { request, response in
    request.path = request.urlVariables[routeTrailingWildcardKey] ?? ""
    StaticFileHandler(documentRoot: baseFolderURL.path).handleRequest(request: request, response: response)
})

routes.add(method: .get, uri: "/static64/**", handler: { request, response in
    if let path64 = request.urlVariables[routeTrailingWildcardKey]?.replacingOccurrences(of: " ", with: "+").replacingOccurrences(of: "/", with: ""),
       let pathData = Data(base64Encoded: path64),
       let path = String(data: pathData, encoding: .utf8) {
        // Since Xcode10 folder containing attachments might contain '+'. This causes problems since the plus sign gets translated to " " by PerfectLib
        // We move the part containing to the documentRoot to workaround the issue
        let filename = path.lastFilePathComponent
        let prePath = path.deletingLastFilePathComponent
        request.path = filename
        response.addHeader(.contentDisposition, value: "attachment; filename=\"\(filename)\"")
        
        StaticFileHandler(documentRoot: baseFolderURL.appendingPathComponent(prePath).path).handleRequest(request: request, response: response)
    }
})

// Add our routes.
server.addRoutes(routes)

do {
    // Launch the HTTP server
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}
